#! /usr/bin/env python

import argparse
import json
import logging
import random
import string
from multiprocessing import Pool

import yaml
from rucio.api.replica import list_datasets_per_rse
from rucio.core import monitor
from rucio.db.sqla.constants import DIDType

from BlockSyncer import BlockSyncer
from phedex import PhEDEx

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
    with file(conffile, 'r') as stream:
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


def compare_site_blocks(phedex=None, rucio=None):
    """

    :param phedex: Dictionary with file counts for PhEDEx
    :param rucio: Dictionary with file counts for Rucio
    :return:
    """
    with monitor.record_timer_block('cms_sync.time_node_diff'):
        phedex_blocks = set(phedex.keys())
        rucio_blocks = set(rucio.keys())
        missing_phedex = rucio_blocks - phedex_blocks
        missing_rucio = phedex_blocks - rucio_blocks
        both = phedex_blocks & rucio_blocks

        for block in both:
            if phedex[block] != rucio[block]:
                print("For %s the files differ: %s vs %s" % (block, phedex[block], rucio[block]))

        return {'not_rucio': missing_rucio, 'not_phedex': missing_phedex, 'complete': both}


class SiteSyncer(object):
    def __init__(self, options):
        self.options = options

        self.config = load_config(options.config)
        self.last_synced = {}  # load_last_synced()
        self.phedex_svc = PhEDEx()

        pass

    def sync_site(self, site_pair):
        """
        Sync a site defined by a site_pair of (site, prefix). Prefix can be None to sync all blocks in the site
        :return:
        """
        site, prefix = site_pair
        # now = int(time.time())

        # Set 1980 as the last sync date if no data exists
        # site_last_synced = self.last_synced.get(site_pair, 10 * 365 * 24 * 3600)
        # last_week = int(site_last_synced - 7 * 24 * 3600)

        if self.config.get('default', None):
            if self.config['default'].get('chunck', 0):
                BLOCKS_PER_ACTION = int(self.config['default']['chunck'])

        with monitor.record_timer_block('cms_sync.time_site_sync'):

            r_timer = 'cms_sync.time_rucio_block_list_all'
            p_timer = 'cms_sync.time_phedex_block_list_all'
            if prefix:
                r_timer = 'cms_sync.time_rucio_block_list_partial'
                p_timer = 'cms_sync.time_phedex_block_list_partial'

            with monitor.record_timer_block(p_timer):
                phedex_blocks = self.phedex_svc.blocks_at_site(pnn=site, prefix=prefix, since=None)
            with monitor.record_timer_block(r_timer):
                rucio_blocks = self.get_datasets_at_rse(rse=site, prefix=prefix)

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

            block_report = compare_site_blocks(phedex=phedex_blocks, rucio=rucio_blocks)

            n_blocks_not_in_rucio = len(block_report['not_rucio'])
            n_blocks_not_in_phedex = len(block_report['not_phedex'])
            logging.info("At %s: In both/PhEDEx only/Rucio only: %s/%s/%s" %
                         (site, len(block_report['complete']),
                          n_blocks_not_in_rucio, n_blocks_not_in_phedex))

            # Truncate lists if we want to reduce cycle time
            if BLOCKS_PER_ACTION and n_blocks_not_in_rucio > BLOCKS_PER_ACTION:
                block_report['not_rucio'] = set(list(block_report['not_rucio'])[:BLOCKS_PER_ACTION])
                n_blocks_not_in_rucio = len(block_report['not_rucio'])
            if BLOCKS_PER_ACTION and n_blocks_not_in_phedex > BLOCKS_PER_ACTION:
                block_report['not_phedex'] = set(list(block_report['not_phedex'])[:BLOCKS_PER_ACTION])
                n_blocks_not_in_phedex = len(block_report['not_phedex'])

            logging.info('Adding   %6d blocks to   Rucio for %s:%s', n_blocks_not_in_rucio, site, prefix)
            for block in block_report['not_rucio']:
                bs = BlockSyncer(block_name=block, pnn=site, rse=site)
                bs.add_to_rucio()

            logging.info('Removing %6d blocks from Rucio for %s:%s', n_blocks_not_in_phedex, site, prefix)
            for block in block_report['not_phedex']:
                bs = BlockSyncer(block_name=block, pnn=site, rse=site)
                bs.remove_from_rucio()
            logging.info('Finished syncing                      %s:%s' % (site, prefix))
        # FIXME: Resurrect code to check for size differences

        # self.last_synced[site_pair] = now
        # save_last_synced(self.last_synced)

    def chunks_to_sync(self):
        """
        Turn the config into a list of site/prefix pairs which need to be synced
        :return: The site prefix pairs
        """

        to_sync = []

        for site, site_config in self.config.items():
            if site not in ['default', 'main']:
                if site_config.get('multi_das_calls', False):
                    for prefix in list(string.letters + string.digits):
                        to_sync.append((site, prefix))
                else:
                    to_sync.append((site, None))
        random.shuffle(to_sync)
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

        with monitor.record_timer_block('cms_sync.time_rse_datasets'):
            datasets = {dataset['name']: dataset['available_length']
                        for dataset in list_datasets_per_rse(rse=rse, filters=filters)}

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
    # parser.add_argument('--logs', dest='logs', default=DEFAULT_LOGFILE,
    #                     help='Logs file. Default %s.' % DEFAULT_LOGFILE)
    # parser.add_argument('--nodaemon', dest='daemon', action='store_false',
    #                     help='Runs in foreground.')

    options = parser.parse_args()
    syncer = SiteSyncer(options)

    site_pairs = syncer.chunks_to_sync()

    # Multi-process version of the syncer
    pool = Pool(processes=6)  # start N worker processes
    sites_and_options = [(site_pair, options) for site_pair in site_pairs]
    pool.map(sync_a_site, sites_and_options, chunksize=1)

    # Single process version of the syncer
    # for site_pair in syncer.chunks_to_sync():
    #     syncer.sync_site(site_pair)
