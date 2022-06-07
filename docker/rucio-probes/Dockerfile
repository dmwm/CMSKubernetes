# Copyright European Organization for Nuclear Research (CERN) 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Authors:
# - Eric Vaandering, <ewv@fnal.gov>, 2019-2020

ARG RUCIO_VERSION

# For now CMS versions use python3 explicitly. Can be removed when main container goes to python3
FROM rucio/probes:latest
#FROM rucio/probes:py3
RUN ln -s /usr/bin/python3 /usr/local/bin/python

ADD https://raw.githubusercontent.com/dmwm/CMSRucio/master/docker/CMSRucioClient/scripts/cmstfc.py  /usr/local/lib/python3.6/site-packages/cmstfc.py
RUN chmod 755 /usr/local/lib/python3.6/site-packages/cmstfc.py

# Temporary additions

# PR 49
#ADD https://raw.githubusercontent.com/ericvaandering/probes/cms_check_expired_locked/common/check_expired_locked_rules /probes/common

# PR 56
ADD https://raw.githubusercontent.com/FernandoGarzon/probes/check_rules_state_PROBE_2/cms/check_rules_states_by_account /probes/cms

# PR 57
#ADD https://raw.githubusercontent.com/FernandoGarzon/probes/cms_free_space_probe_2/cms/check_free_space /probes/cms

# PR 62 - Merged on July 6 2021
#ADD https://raw.githubusercontent.com/rucio/probes/master/cms/check_report_used_space /probes/cms

# Until Fernando ports to SQLAlchemy and/or merged

ADD https://raw.githubusercontent.com/ericvaandering/probes/hack_obsolete_replicas/common/check_obsolete_replicas /probes/common
ADD https://raw.githubusercontent.com/nsmith-/probes/hack_replicas/common/check_deletable_replicas /probes/common

# TODO: Merge Donata's probes somewhere

#ADD https://raw.githubusercontent.com/ericvaandering/probes/donata_sqlalchemy/common/check_expiring_rules_per_rse /probes/common
#ADD https://raw.githubusercontent.com/ericvaandering/probes/donata_sqlalchemy/common/check_missing_data_at_rse /probes/common
#ADD https://raw.githubusercontent.com/ericvaandering/probes/donata_sqlalchemy/common/check_expected_total_number_of_files_per_rse /probes/common
# Suplanted by PR 57 ADD https://raw.githubusercontent.com/dmielaikaite/probes/dmielaik_probes/common/check_free_space /probes/common
#ADD https://raw.githubusercontent.com/ericvaandering/probes/donata_sqlalchemy/common/check_not_OK_rules_per_rse /probes/common
#ADD https://raw.githubusercontent.com/dmielaikaite/probes/dmielaik_probes/common/check_report_free_space /probes/common
#ADD https://raw.githubusercontent.com/ericvaandering/probes/donata_sqlalchemy/common/check_rules_with_0_completion_volume /probes/common
ADD https://raw.githubusercontent.com/dmielaikaite/probes/dmielaik_probes/common/check_used_space /probes/common


# PR-o-rama for 1.27
# PR 73 - merged 3/15/22
# ADD https://raw.githubusercontent.com/rucio/probes/master/cms/check_number_of_missing_files_per_rse /probes/cms
# PR 79 - merged 3/15/22
# ADD https://raw.githubusercontent.com/rucio/probes/master/cms/check_rule_counts /probes/cms
# ADD https://raw.githubusercontent.com/FernandoGarzon/probes/check_rules_state_PROBE_2/cms/check_rules_states_by_account /probes/cms


# PR 80 ADD https://raw.githubusercontent.com/ericvaandering/probes/missing_data_rse_127/cms/check_missing_data_at_rse /probes/cms

# PR 71
ADD https://raw.githubusercontent.com/ericvaandering/probes/expiring_rules_rse_127/cms/check_expiring_rules_per_rse /probes/cms

# PR 72
ADD https://raw.githubusercontent.com/ericvaandering/probes/update_check_expected_total_number_of_files_per_rse/cms/check_expected_total_number_of_files_per_rse /probes/cms

# PR 69
ADD https://raw.githubusercontent.com/ericvaandering/probes/127_cms_fixes/cms/check_report_used_space /probes/cms

# PR 75 - merged 3/15/22
# ADD https://raw.githubusercontent.com/rucio/probes/master/cms/check_not_OK_rules_per_rse  /probes/cms
# ADD https://raw.githubusercontent.com/rucio/probes/master/cms/check_rules_with_0_completion_volume  /probes/cms
# ADD https://raw.githubusercontent.com/rucio/probes/master/cms/check_unlocked_replicas_per_rse /probes/cms

# PR 77 - merged 3/15/22
# ADD https://raw.githubusercontent.com/rucio/probes/master/cms/check_report_free_space /probes/cms

ADD https://raw.githubusercontent.com/ericvaandering/probes/cms_check_expired_rules/common/check_expired_rules /probes/common
ADD https://raw.githubusercontent.com/ericvaandering/probes/cms_check_expired_locked/common/check_expired_locked_rules /probes/common

# PR 74 ADD https://raw.githubusercontent.com/rucio/probes/new_dids_127/common/check_new_dids /probes/common
# PR 70 ADD https://raw.githubusercontent.com/rucio/probes/expired_dids_127/common/check_expired_dids /probes/common
# PR 76 ADD https://raw.githubusercontent.com/rucio/probes/stuck_rules_127/common/check_stuck_rules /probes/common
# PR 78 ADD https://raw.githubusercontent.com/rucio/probes/updated_dids_127/common/check_updated_dids /probes/common
# PR 81 ADD https://raw.githubusercontent.com/rucio/probes/fts_127/common/check_fts_backlog /probes/common

# PR 85 - merged 3/18/22
# RUN mkdir -p /probes/common/utils
# ADD https://raw.githubusercontent.com/rucio/probes/master/common/check_expired_rules /probes/common
# ADD https://raw.githubusercontent.com/rucio/probes/master/common/utils/common.py /probes/common/utils
# ADD https://raw.githubusercontent.com/rucio/probes/master/common/utils/__init__.py /probes/common/utils
# ADD https://raw.githubusercontent.com/rucio/probes/master/cms/utils.py /probes/cms

# PR 98

ADD https://raw.githubusercontent.com/FernandoGarzon/probes/check_rules_counts_vs_time/cms/check_rule_counts /probes/cms

# CMS Specific probes
# Removed 3/17 presumably no longer needed
# ADD https://raw.githubusercontent.com/FernandoGarzon/CMSRucio/cms-only-probes/probes/common/check_space_uniquely_used_by_rucio /probes/common
# FIXME: Remove this from the ones to run

RUN chmod +x /probes/common/check_*
RUN chmod +x /probes/cms/check_*

# Temporary while we are adding variables to the config. Push to rucio-containers
ADD https://raw.githubusercontent.com/ericvaandering/containers/probes_prom/probes/rucio.cfg.j2 /tmp/
