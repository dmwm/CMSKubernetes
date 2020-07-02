#! /usr/bin/env python
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

block = '/WprimeToWhToWhadhinc_narrow_M-800_TuneCP5_13TeV-madgraph-pythia8/RunIIAutumn18NanoAODv5-Nano1June2019_102X_upgrade2018_realistic_v19-v1/NANOAODSIM#ae4ef901-537b-4747-912a-22eeda04d39f'
site = 'T0_CERN_CH_Tape'
pnn = 'T0_CH_CERN_MSS'

logging.info('Constructing syncer for: %s at %s', block, site)
bs = BlockSyncer(block_name=block, pnn=pnn, rse=site)
logging.info('Adding to rucio: %s at %s', block, site)
bs.add_to_rucio()
