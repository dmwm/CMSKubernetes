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

block = '/CITo2Mu_M300_CUETP8M1_Lam10TeVConLR_13TeV-pythia8/RunIISummer16NanoAODv3-PUMoriond17_94X_mcRun2_asymptotic_v3-v2/NANOAODSIM#451ee984-a4b7-429e-bf00-38db258bdfdd'
site = 'T1_US_FNAL_Tape'
pnn = 'T1_US_FNAL_MSS'

logging.info('Constructing syncer for: %s at %s', block, site)
bs = BlockSyncer(block_name=block, pnn=pnn, rse=site)
logging.info('Adding to rucio: %s at %s', block, site)
bs.add_to_rucio()
