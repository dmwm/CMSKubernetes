from __future__ import absolute_import, division, print_function

"""
import re
import time
from random import randint
import argparse
import traceback
import multiprocessing
import argparse
import copy
import functools
import random
import re
import string
import sys
import time
import traceback
from datetime import datetime, timedelta
"""

import logging
import os

from CMSRucio import replica_file_list

from phedex import PhEDEx
from rucio.api.did import add_did, attach_dids, get_did, list_files
from rucio.api.replica import list_replicas, add_replicas, delete_replicas
from rucio.api.rse import list_rses
from rucio.api.rule import add_replication_rule, list_replication_rules, delete_replication_rule
from rucio.common.exception import (DataIdentifierNotFound, DataIdentifierAlreadyExists, DuplicateContent,
                                    FileAlreadyExists)
from rucio.common.utils import chunks
from rucio.core import monitor

from syncaccounts import SYNC_ACCOUNT_FMT

REMOVE_CHUNK_SIZE = 20
DEFAULT_SCOPE = 'cms'


# From https://stackoverflow.com/questions/1158076/implement-touch-using-python
def touch(fname='/tmp/sync-alive.txt', times=None, text=None):
    fhandle = open(fname, 'a')
    try:
        os.utime(fname, times)
        if text:
            fhandle.write(text + '\n')
    finally:
        fhandle.close()


class BlockSyncer(object):
    """
    Class representing the replica at a site af a CMS Dataset (PhEDEx FileBlock)
    """

    def __init__(self, block_name, pnn, rse=None, lifetime=None, dry_run=False):
        """
        Get the status of replica of pditem at pnn
        considering only closed blocks completely replicated at site.

        :rds:    PhEDEx block name.
        :pnn:    PhEDEx node name.
        :rse:    Rucio RSE. If None (default) inferred by the pnn using DEFAULT_RSE_FMT.
        :scope:  Scope. Default: DEFAULT_SCOPE.
        """

        self.phedex_svc = PhEDEx()
        self.dry_run = dry_run

        self.pnn = pnn
        if rse is None:
            self.rse = list_rses('cms_type=real&pnn=%s' % self.pnn)[0]['rse']
        else:
            self.rse = rse

        self.account = SYNC_ACCOUNT_FMT % self.pnn.lower()
        self.container = self.phedex_svc.check_data_item(pditem=block_name)['pds']
        self.scope = DEFAULT_SCOPE
        self.block_name = block_name
        self.lifetime = lifetime

        self.is_at_pnn = self.phedex_svc.block_at_pnn_phedex(block=self.block_name, pnn=self.pnn)
        if self.is_at_pnn:
            self.replicas = self.phedex_svc.fileblock_files_phedex(pnn=pnn, pfb=block_name)
        else:
            self.replicas = {}

        self.container_exists = None
        self.block_exists = None
        self.rule_exists = None

        touch(text=self.rse)
        # pdb.set_trace()

    def add_to_rucio(self):
        """"""
        with monitor.record_timer_block('cms_sync.time_add_block'):
            self.register_container()
            block_exists = self.register_block()
            if block_exists:
                self.update_replicas()
                self.update_rule()

    def remove_from_rucio(self):
        """"""
        with monitor.record_timer_block('cms_sync.time_remove_block'):
            self.update_replicas()
            self.update_rule()

    def register_container(self):
        self.container_exists = False
        if self.is_at_pnn and self.dry_run:
            logging.info('Dry Run: Create container %s in scope %s.', self.container, self.scope)
            self.container_exists = True
            return self.container_exists

        try:
            get_did(scope=self.scope, name=self.container)
            monitor.record_counter('cms_sync.container_exists')
            self.container_exists = True
        except DataIdentifierNotFound:
            if self.is_at_pnn:
                logging.debug('Create container %s in scope %s.', self.container, self.scope)
                try:
                    add_did(scope=self.scope, name=self.container, type='CONTAINER',
                            issuer=self.account, lifetime=self.lifetime)
                    monitor.record_counter('cms_sync.container_created')
                    self.container_exists = True
                except DataIdentifierAlreadyExists:
                    logging.warning('Container was created in the meanwhile')
                    monitor.record_counter('cms_sync.container_collision')
                    self.container_exists = True

        return self.container_exists

    def register_block(self):
        """
        Register the dataset (if there is a replica at the pnn) and attach to container
        :dry: Dry run. Default false.
        """

        # FIXME: The logic here could use some improvement as we try to create a block even if it exists already

        try:
            get_did(scope=self.scope, name=self.block_name)
            self.block_exists = True
            monitor.record_counter('cms_sync.dataset_exists')
        except DataIdentifierNotFound:
            self.block_exists = False

        if self.is_at_pnn and self.dry_run:
            logging.info('Dry Run: Create dataset %s in scope %s.', self.block_name, self.scope)
            self.block_exists = True
        elif self.is_at_pnn:
            logging.debug('Create dataset %s in scope %s.', self.block_name, self.scope)
            try:
                if not self.block_exists:
                    add_did(scope=self.scope, name=self.block_name, type='DATASET',
                            issuer=self.account, lifetime=self.lifetime)
                    monitor.record_counter('cms_sync.dataset_created')
            except DataIdentifierAlreadyExists:
                logging.warning('Attempt to add %s:%s failed, already exists.', self.scope, self.block_name)

            try:
                attach_dids(scope=self.scope, name=self.container,
                            attachment={'dids': [{'scope': self.scope, 'name': self.block_name}]}, issuer=self.account)
            except DuplicateContent:
                logging.warning('Attempt to add %s:%s to %s failed, already exists.',
                                self.scope, self.block_name, self.container)
            except DataIdentifierNotFound:
                logging.error('Attempt to add %s:%s to %s failed. Container does not exist.',
                              self.scope, self.block_name, self.container)
                return False
            monitor.record_counter('cms_sync.dataset_created')
            self.block_exists = True

        return self.block_exists

    def update_rule(self):
        """
        Adds or removes the rule for the block.
        """

        rules = list_replication_rules(filters={'scope': self.scope, 'name': self.block_name})
        # rules = self.rcli.list_did_rules(scope=self.scope, name=self.block_name)
        rse_expression = 'rse=' + self.rse

        remove_rules = [rule for rule in rules
                        if rule['account'] == self.account and rule['rse_expression'] == rse_expression]

        if not remove_rules and self.is_at_pnn:
            self.rule_exists = False
            if self.dry_run:
                logging.info("Dry run: Adding rule for dataset %s at rse %s.", self.block_name, self.rse)
            else:
                self.add_replication_rule_with_defaults(dids=[{'scope': self.scope, 'name': self.block_name}],
                                                        copies=1, rse_expression=rse_expression, account=self.account)
                monitor.record_counter('cms_sync.rules_added')
            self.rule_exists = True
        elif remove_rules and not self.is_at_pnn:
            self.rule_exists = True
            if self.dry_run:
                logging.info("Removing rules for dataset %s at rse %s.", self.block_name, self.rse)
            else:
                for rule in remove_rules:
                    delete_replication_rule(rule['id'], purge_replicas=False, issuer=self.account)
                    monitor.record_counter('cms_sync.rules_removed')
            self.rule_exists = False

    def update_replicas(self):
        """
        Add or removes replicas for the dataset at rse.
        """
        with monitor.record_timer_block('cms_sync.time_update_replica'):
            logging.debug('Updating replicas for %s:%s at %s' % (self.scope, self.block_name, self.rse))
            replicas = list_replicas(dids=[{'scope': self.scope, 'name': self.block_name}],
                                     rse_expression='rse=%s' % self.rse)

            try:
                rucio_replicas = {repl['name'] for repl in replicas}
            except TypeError:
                rucio_replicas = set()

            phedex_replicas = set(self.replicas.keys())
            missing = list(phedex_replicas - rucio_replicas)
            to_remove = list(rucio_replicas - phedex_replicas)

            if missing:
                lfns_added = self.add_missing_replicas(missing)
                monitor.record_counter('cms_sync.files_added', delta=lfns_added)
            if to_remove:
                lfns_removed = self.remove_extra_replicas(to_remove)
                monitor.record_counter('cms_sync.files_removed', delta=lfns_removed)

        return

    def remove_extra_replicas(self, to_remove):
        """
        :param to_remove: replicas to remove from Rucio
        :return:
        """

        with monitor.record_timer_block('cms_sync.time_remove_replica'):
            if to_remove and self.dry_run:
                logging.info('Dry run: Removing replicas %s from rse %s.', str(to_remove), self.rse)
            elif to_remove:
                logging.debug('Removing %s replicas from rse %s.', len(to_remove), self.rse)
                for to_remove_chunk in chunks(to_remove, REMOVE_CHUNK_SIZE):
                    delete_replicas(rse=self.rse, issuer=self.account,
                                    files=[{'scope': self.scope, 'name': lfn} for lfn in to_remove_chunk])
                    # FIXME: Do we need a retry here on DatabaseException? If so, use the retry module
                return len(to_remove)

    def add_missing_replicas(self, missing):
        """
        :param missing: possible missing lfns
        :return:
        """
        with monitor.record_timer_block('cms_sync.time_add_replica'):
            if missing and self.dry_run:
                logging.info('Dry run: Adding replicas %s to rse %s.', str(missing), self.rse)
            elif missing:
                logging.debug('Adding %s replicas to rse %s.', len(missing), self.rse)

                replicas_to_add = [self.replicas[lfn] for lfn in missing]
                files = replica_file_list(replicas=replicas_to_add, scope=self.scope)
                add_replicas(rse=self.rse, files=files, issuer=self.account)
                lfns = [item['name'] for item in list_files(scope=self.scope, name=self.block_name, long=False)]

                missing_lfns = list(set(missing) - set(lfns))
                if missing_lfns:
                    logging.debug('Attaching %s lfns to %s at %s', len(missing_lfns), self.block_name, self.rse)
                    dids = [{'scope': self.scope, 'name': lfn} for lfn in missing_lfns]
                    try:
                        attach_dids(scope=self.scope, name=self.block_name, attachment={'dids': dids},
                                    issuer=self.account)
                    except FileAlreadyExists:
                        logging.warning('Trying to attach already existing files to %s', self.block_name)
                return len(missing_lfns)

    @staticmethod
    def add_replication_rule_with_defaults(dids, copies, rse_expression, account):

        """
        Add replication rule requires one to send all the values. Add a list of defaults.
        If true options are required, move them into the parameter list.

        :param dids: List of dids (scope/name dictionary)
        :param copies: Number of copies
        :param rse_expression: RSE expression
        :param account: Account for the rule
        :return: None
        """

        (grouping, weight, lifetime, locked, subscription_id, source_replica_expression, activity, notify,
         purge_replicas, ignore_availability, comment, ask_approval, asynchronous, priority, split_container, meta) = (
            'DATASET', None, None, False, None, None, None, None, False, False, None, False, False, 3, False, None)

        add_replication_rule(dids=dids, copies=copies, rse_expression=rse_expression, account=account,
                             grouping=grouping, weight=weight, lifetime=lifetime, locked=locked,
                             subscription_id=subscription_id, source_replica_expression=source_replica_expression,
                             activity=activity, notify=notify, purge_replicas=purge_replicas,
                             ignore_availability=ignore_availability, comment=comment, ask_approval=ask_approval,
                             asynchronous=asynchronous, priority=priority, split_container=split_container, meta=meta,
                             issuer=account)
