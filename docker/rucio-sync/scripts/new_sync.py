#! /usr/bin/env python3

import argparse
import json
import logging
import random
import string
from multiprocessing import Pool

import yaml
from phedex import PhEDEx
from rucio.api.replica import list_datasets_per_rse, list_dataset_replicas
from rucio.api.rule import list_replication_rules
from rucio.core import monitor
from rucio.db.sqla.constants import DIDType
from syncaccounts import SYNC_ACCOUNT_FMT

from BlockSyncer import BlockSyncer, touch

# import time

DEFAULT_CONFFILE = '/etc/synccmssites.yaml'

# BLOCKS_PER_ACTION = 4
BLOCKS_PER_ACTION = None


def load_config(conffile):
    """
    Gets the conf file and dumps it to the
    working copy
    :conffile:  file to be loaded
    :modif:     dictionnary with modifications

    returns the content dictionnary
    """
    with open(conffile, 'r') as stream:
        config = yaml.load(stream, Loader=yaml.SafeLoader)
    return config


def load_last_synced():
    last_synced = {}
    try:
        with open('last_synced.json', 'r') as ls_file:
            saveable = json.load(ls_file)

        for key, timestamp in saveable.items():
            pair = key.split(':')
            if pair[1] == 'None':
                pair[1] = None
            last_synced[tuple(pair)] = timestamp

        return last_synced
    except IOError:
        return last_synced


def save_last_synced(last_synced):
    saveable = {}
    for pair, timestamp in last_synced.items():
        site, prefix = pair
        key = site + ':' + str(prefix)  # Convert None
        saveable[key] = timestamp
    with open('last_synced.json', 'w') as ls_file:
        json.dump(saveable, ls_file)
    return


def compare_site_blocks(phedex=None, rucio=None, rse='', patterns=None):
    """

    :param phedex: Dictionary with file counts for PhEDEx
    :param rucio: Dictionary with file counts for Rucio
    :return:
    """
    with monitor.record_timer_block('cms_sync.time_node_diff'):
        #        from  pprint import pformat
        phedex_blocks = set(phedex.keys())
        #        logging.info('Blocks in PhEDEx %s', pformat(phedex_blocks))

        rucio_blocks = set(rucio.keys())
        #        logging.info('Blocks in Rucio %s', pformat(rucio_blocks))

        if patterns:
            phedex_match = set()
            rucio_match = set()

            for pattern in patterns:
                phedex_match = phedex_match | {p for p in phedex_blocks if pattern in p}
                rucio_match = rucio_match | {r for r in rucio_blocks if pattern in r}

            logging.info('Pattern matching reduces Rucio %s->%s and PhEDEx %s->%s',
                         len(rucio_blocks), len(rucio_match), len(phedex_blocks), len(phedex_match))
            phedex_blocks = phedex_match
            rucio_blocks = rucio_match

        missing_phedex = rucio_blocks - phedex_blocks
        missing_rucio = phedex_blocks - rucio_blocks
        both = phedex_blocks & rucio_blocks
        incomplete = set()

        for block in both:
            if phedex[block] != rucio[block]:
                print("For %s at %s the files differ: %s vs %s." % (block, rse, phedex[block], rucio[block]))
                incomplete.add(block)
        both = both - incomplete

        return {'not_rucio': missing_rucio, 'not_phedex': missing_phedex, 'complete': both, 'incomplete': incomplete}


class SiteSyncer(object):
    def __init__(self, options):
        self.options = options

        self.config = load_config(options.config)
        self.last_synced = {}  # load_last_synced()
        self.phedex_svc = PhEDEx()
        self.patterns = []

        return

    def sync_site(self, site_pair):
        """
        Sync a site defined by a site_pair of (site, prefix). Prefix can be None to sync all blocks in the site
        :return:
        """
        site, prefix = site_pair

        if site.endswith('_Tape'):
            pnn = site.replace('_Tape', '_MSS')
        else:
            pnn = site

        if site == 'T3_CH_CERN_CTA_CastorTest':
            pnn = 'T0_CH_CERN_MSS'

        # now = int(time.time())

        # Set 1980 as the last sync date if no data exists
        # site_last_synced = self.last_synced.get(site_pair, 10 * 365 * 24 * 3600)
        # last_week = int(site_last_synced - 7 * 24 * 3600)

        if self.config.get('default', None):
            if self.config['default'].get('chunck', 0):
                BLOCKS_PER_ACTION = int(self.config['default']['chunck'])
            if self.config['default'].get('select', None):
                self.patterns = [self.config['default']['select']]

        with monitor.record_timer_block('cms_sync.time_site_sync'):

            r_timer = 'cms_sync.time_rucio_block_list_all'
            p_timer = 'cms_sync.time_phedex_block_list_all'
            if prefix:
                r_timer = 'cms_sync.time_rucio_block_list_partial'
                p_timer = 'cms_sync.time_phedex_block_list_partial'

            # Add touches to keep from getting killed as long as progress is being made
            with monitor.record_timer_block(p_timer):
                touch(text='PQ ' + site)
                phedex_blocks = self.phedex_svc.blocks_at_site(pnn=pnn, prefix=prefix, since=None)
            with monitor.record_timer_block(r_timer):
                touch(text='RQ ' + site)
                rucio_blocks = self.get_datasets_at_rse(rse=site, prefix=prefix)
                touch(text='DQ ' + site)

            n_blocks_in_phedex = len(phedex_blocks)
            n_blocks_in_rucio = len(rucio_blocks)

            # FIXME: This is refusing to delete everything from Rucio. Not clear it's needed
            if not n_blocks_in_phedex and n_blocks_in_rucio:
                logging.warning("At %s found %s blocks in PhEDEx and %s in Rucio with prefix %s",
                                site, n_blocks_in_phedex, n_blocks_in_rucio, prefix)
                return
            if not n_blocks_in_phedex and not n_blocks_in_rucio:
                logging.info("At %s:%s, nothing in PhEDEx or Rucio. Quitting." % (site, prefix))
                return

            block_report = compare_site_blocks(phedex=phedex_blocks, rucio=rucio_blocks, rse=site,
                                               patterns=self.patterns)

            n_blocks_not_in_rucio = len(block_report['not_rucio'])
            n_blocks_not_in_phedex = len(block_report['not_phedex'])
            n_incomplete_blocks = len(block_report['incomplete'])

            logging.info("At %s:%s In both/PhEDEx only/Rucio only: %s/%s/%s" %
                         (site, prefix, len(block_report['complete']),
                          n_blocks_not_in_rucio, n_blocks_not_in_phedex))
            if len(block_report['complete']) or n_blocks_not_in_rucio or n_blocks_not_in_phedex:
                logging.info('At %s:%s %3.0f%% complete',
                             site, prefix, len(block_report['complete']) * 100
                             / (len(block_report['complete']) + n_blocks_not_in_rucio + n_blocks_not_in_phedex))
            if len(block_report['complete']) or n_blocks_not_in_rucio:
                logging.info('At %s:%s %3.0f%% completely added',
                             site, prefix, len(block_report['complete']) * 100
                             / (len(block_report['complete']) + n_blocks_not_in_rucio))
            # Truncate lists if we want to reduce cycle time
            if BLOCKS_PER_ACTION and n_blocks_not_in_rucio > BLOCKS_PER_ACTION:
                block_report['not_rucio'] = set(list(block_report['not_rucio'])[:BLOCKS_PER_ACTION])
                n_blocks_not_in_rucio = len(block_report['not_rucio'])
            if BLOCKS_PER_ACTION and n_blocks_not_in_phedex > BLOCKS_PER_ACTION:
                block_report['not_phedex'] = set(list(block_report['not_phedex'])[:BLOCKS_PER_ACTION])
                n_blocks_not_in_phedex = len(block_report['not_phedex'])

            logging.info('Adding   %6d blocks to   Rucio for %s:%s', n_blocks_not_in_rucio, site, prefix)
            for block in block_report['not_rucio']:
                logging.info('Adding to rucio: %s at %s', block, site)
                bs = BlockSyncer(block_name=block, pnn=pnn, rse=site)
                bs.add_to_rucio()

            logging.info('Removing %6d blocks from Rucio for %s:%s', n_blocks_not_in_phedex, site, prefix)
            for block in block_report['not_phedex']:
                logging.info('Removing from rucio: %s at %s', block, site)
                bs = BlockSyncer(block_name=block, pnn=pnn, rse=site)
                bs.remove_from_rucio()

            for block in block_report['incomplete']:
                logging.warn('Redoing sync for %s at %s', block, site)
                bs = BlockSyncer(block_name=block, pnn=pnn, rse=site)
                bs.add_to_rucio(recover=True)

            logging.info('Finished syncing                      %s:%s' % (site, prefix))

    def chunks_to_sync(self):
        """
        Turn the config into a list of site/prefix pairs which need to be synced
        :return: The site prefix pairs
        """

        to_sync = []

        for site, site_config in self.config.items():
            print('Site %s (%s)is ok %s' % (site, type(site), site not in ['default', 'main']))
            if site not in ['default', 'main']:
                if site_config.get('multi_das_calls', False):
                    for prefix in list(string.ascii_letters + string.digits):
                        if (('CERN' in site) or ('FNAL' in site) or ('_Tape' in site)) and prefix == 'S':
                            for fnal_prefix in ('Sc', 'Se', 'Si', 'Sp', 'St', 'SI', 'SM', 'ST', 'SU', 'SV', 'SS',
                                                'Su', 'SP', 'SL'):
                                to_sync.append((site, fnal_prefix))
                        elif (('T0' in site) or ('FNAL' in site) or ('_Tape' in site)) and prefix == 'M':
                            for fnal_prefix in ('Ma', 'MC', 'ME', 'Mi', 'Mo', 'MS', 'Mu'):
                                to_sync.append((site, fnal_prefix))
                        elif (('T0' in site) or ('FNAL' in site) or ('_Tape' in site)) and prefix == 'D':
                            for fnal_prefix in ('D0', 'Da', 'Di', 'DM', 'Do', 'Dp', 'DP', 'Ds', 'DS', 'DY'):
                                to_sync.append((site, fnal_prefix))
                        elif (('T0' in site) or ('FNAL' in site) or ('_Tape' in site)) and prefix == 'T':
                            for fnal_prefix in ('T1', 'T4', 'T5', 'TH', 'TK', 'TO', 'TA', 'TB', 'TC', 'TG', 'TZ', 'T_',
                                                'TS', 'TT', 'TW', 'Tk', 'To', 'Ta', 'Tb', 'Te', 'Tp', 'Tr', 'Ts',
                                                'Tt', 'Tw', 'Ty'):
                                to_sync.append((site, fnal_prefix))
                        elif (('CERN' in site) or ('FNAL' in site)) and prefix == 'H':
                            for fnal_prefix in ('H0', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'Ha', 'HA', 'Hc', 'He', 'HE',
                                                'HF', 'Hi', 'HI', 'HJ', 'HL', 'Hp', 'HP', 'Hs', 'HS', 'HT', 'HV', 'HW',
                                                'Hy', 'HZ'):
                                to_sync.append((site, fnal_prefix))
                        elif (('T0' in site) or ('FNAL' in site) or ('_Tape' in site) or (
                                '_CTA' in site)) and prefix == 'C':
                            for fnal_prefix in ('Ca', 'CE', 'CG', 'Ch', 'CI', 'CM', 'Co', 'CS'):
                                to_sync.append((site, fnal_prefix))
                        elif (('CERN' in site) or ('FNAL' in site)) and prefix == 'Z':
                            for fnal_prefix in ('Z0', 'Z1', 'Z2', 'Z3', 'Z4', 'Z5', 'ZA', 'Zb', 'ZB', 'Zc', 'ZC', 'Ze',
                                                'ZE', 'ZG', 'ZH', 'ZJ', 'ZL', 'Zm', 'ZM', 'Zn', 'ZN', 'Zp', 'ZP', 'ZR',
                                                'Zt', 'ZT', 'ZU', 'ZV', 'ZZ'):
                                to_sync.append((site, fnal_prefix))
                        elif (('CERN' in site) or ('FNAL' in site)) and prefix == 'G':
                            for fnal_prefix in ('G_', 'G1', 'Ga', 'Ge', 'GF', 'GG', 'Gj', 'GJ', 'Gl', 'GM', 'Gr',
                                                'Gs', 'GV'):
                                to_sync.append((site, fnal_prefix))
                        else:
                            to_sync.append((site, prefix))
                else:
                    to_sync.append((site, None))

        # Cut the list (keep in order but choose a random starting point)
        offset = random.randrange(len(to_sync))
        to_sync = to_sync[offset:] + to_sync[:offset]


        to_sync = [
        #     # ('T1_US_FNAL_Tape', 'ST_s-channel_4f_leptonDecays_TuneCP5_13TeV-amcatnlo-pythia8/RunIISummer19UL18RECO-106X_upgrade2018_realistic_v11_L1v1-v1'),
             ('T0_CH_CERN_Tape', 'DQ'),
            ('T0_CH_CERN_Tape', 'TAC'),
            #     # ('T1_US_FNAL_Tape', 'VBFH_HToSSTo4Tau_MH-125_TuneCUETP8M1_13TeV-powheg-pythia8/RunIISummer16DR80Premix-PUMoriond17_rp_80X_mcRun2_asymptotic_2016_TrancheIV_v6-v2'),
        #     # ('T1_US_FNAL_Tape', 'ZeroBias1/Commissioning2018-26Apr2018-v1'),
        ]

        return to_sync

    @staticmethod
    def get_datasets_at_rse(rse, prefix=None):
        """

        :param rse: The RSE name
        :param prefix: Character(s) to restrict the dataset search
        :return: a dictionary with <dataset name>: <number of files>
        """

        filters = {'scope': 'cms', 'did_type': DIDType.DATASET}
        if prefix:
            filters['name'] = '/' + prefix + '*'

        account = SYNC_ACCOUNT_FMT % rse.lower()
        rule_filters = {'account': account, 'scope': 'cms', 'did_type': DIDType.DATASET}

        with monitor.record_timer_block('cms_sync.time_rse_datasets'):
            synced_ds = {item['name'] for item in list_replication_rules(filters=rule_filters)
                         if item['expires_at'] is None and (prefix is None or item['name'].startswith('/' + prefix))}

            all_datasets = [dataset['name'] for dataset in list_datasets_per_rse(rse=rse, filters=filters)]

            logging.info('Getting all datasets at %s with prefix %s' % (rse, prefix))

            datasets = {}

            for dataset in all_datasets:
                if dataset in synced_ds:
                    for ds in list_dataset_replicas(scope='cms', name=dataset, deep=True):
                        if ds['rse'] == rse:
                            datasets.update({dataset: ds['available_length']})

        return datasets


def sync_a_site(site_option_pair):
    site_pair, options = site_option_pair
    monitor.record_counter('cms_sync.site_started')
    try:
        # Make a new syncer object and sync that one site
        syncer = SiteSyncer(options)
        syncer.sync_site(site_pair)
        monitor.record_counter('cms_sync.site_completed')
    except Exception as e:
        logging.error('Encountered error %s trying to sync %s' % (e, site_pair))
        logging.exception('Exception is: ')
        monitor.record_counter('cms_sync.site_error')

    return


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='''Service for synching rucio and phedex locality data''',
    )
    parser.add_argument('--config', dest='config', default=DEFAULT_CONFFILE,
                        help='Configuration file. Default %s.' % DEFAULT_CONFFILE)

    options = parser.parse_args()
    syncer = SiteSyncer(options)

    site_pairs = syncer.chunks_to_sync()

    # Multi-process version of the syncer
    pool = Pool(processes=1)  # start N worker processes
    sites_and_options = [(site_pair, options) for site_pair in site_pairs]
    pool.map(sync_a_site, sites_and_options, chunksize=1)

    # Single process version of the syncer
    # for site_pair in syncer.chunks_to_sync():
    #     syncer.sync_site(site_pair)
