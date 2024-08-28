"""
Copyright (c) 2016 Ericsson AB, 2010 - 2016.

All Rights Reserved. Reproduction in whole or in part is prohibited
without the written consent of the copyright owner.

ERICSSON MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE
SUITABILITY OF THE SOFTWARE, EITHER EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. ERICSSON
SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A
RESULT OF USING, MODIFYING OR DISTRIBUTING THIS SOFTWARE OR ITS
DERIVATIVES.

This is main script for SSO installation and configuration

Created by emapawl

"""

from sso_const import *
from sso_utils import *
from sso_class import *
from subprocess import *
import time
import sys
import datetime

# Prevent concurrent invocation of install_sso.py in case of Jboss restart

is_sso_configuring = False

try:
    is_sso_configuring = sso_configuring_flag(CHECK)
except:
    main_logger.error(UNEXPECTED_ERROR.format(print_exception()))

if is_sso_configuring:
    sys.exit(0)

# Do not execute in case of already installing/installed SSO
main_logger.info("Checking for existing SSO installation")

try:
    is_sso_installed = check_if_sso_installed()
except:
    main_logger.error(UNEXPECTED_ERROR.format(print_exception()))

# In case of already installed OpenAM, print warning and exit
if is_sso_installed:
    try:
        sso = Sso()
        main_logger.warning("SSO installation detected")
    except:
        main_logger.error(UNEXPECTED_ERROR.format(print_exception()))
    finally:
        sso.manage_ports(UNLOCK)
    sys.exit(0)

# Start installation
try:
    sso = Sso()
    main_logger.info("Initialising Single Sign On")
    start_time = datetime.datetime.now()
    main_logger.info("SSO installation start time: " + str(start_time))
    main_logger.info("Python version: " + (sys.version).replace('\n', ''))
    main_logger.info("Reading SSO data")
    sso.read_sso_data()
    main_logger.info("Blocking ports needed for configuration")
    sso.block_ports()
    main_logger.info("Waiting for SSO war file deployment")
    main_logger.info("Skipping wait for other sso...... de lads")
    #sso.wait_for_sso_deployment()
    main_logger.info("No previous installation of SSO found, continuing with initialisation")
    main_logger.info("Validating installation data")
    sso.validate_global_properties_data()
    main_logger.info("Validation of installation data successful")
    main_logger.info("Performing sanity check on environment")
    sso.check_environment()
    main_logger.info("Sanity check passed, continuing with initialisation")
    main_logger.info("Checking own SSO deployment status")
    sso.check_deployment(RESPONSE_302, 20)
    main_logger.info("Checking the other SSO deployment existence")
    sso.check_other_deployment()
    if sso.installation_status == INSTALL_AS_SECOND:
        sso.wait_primary_installation_completes(5, 100)
    main_logger.info("Starting SSO configuration")
    main_logger.info("Preparing SSO configuration file")
    sso.prepare_sso_configuration()
    main_logger.info("Creating base SSO configuration")
    sso.base_sso_installation()
    main_logger.info("Verify base SSO configuration")
    sso.check_base_sso_configuration()

    """
    main_logger.info("Checking if additional restart is needed")
    if sso.secondary_sso_jboss_restart_needed():
        main_logger.info("Restarting Jboss")
        sso.perform_jboss_stop_and_start__inst_phase()
    else:
        main_logger.info("No Jboss restart needed for secondary server")
    """

    main_logger.info("SSO timeouts configuration")
    sso.configure_timeouts()
    main_logger.info("SSO session constraint configuration")
    sso.read_session_constraint_parameters()
    main_logger.info("Preparing SSO configuration files")
    sso.prepare_sso_configuration_files()
    main_logger.info("Configuring SSO")
    sso.configure_sso_deployment()

    main_logger.info("Checking if additional restart is needed")
    if sso.secondary_sso_jboss_restart_needed():
        main_logger.info("Restarting Jboss")
        sso.perform_jboss_stop_and_start__inst_phase()
    else:
        main_logger.info("No Jboss restart needed for secondary server")

    main_logger.info("Finalizing configuration")
    sso.finalize_configuration()
    main_logger.info("Creating SSO data file")
    sso.store_installation_data()
    #main_logger.info("Set SSO log script")
    #sso.runSSOLogScript()

    main_logger.info("Doing SSO configurations to do necessary after online")
    sso.configure_sso_deployment_after_online()

    main_logger.info("SSO installation and configuration successfully finished")
    end_time = datetime.datetime.now()
    main_logger.info("SSO instance installation end time: " + str(end_time))
    duration_time = end_time - start_time
    main_logger.info("SSO instance installation duration: " + str(duration_time))
    main_logger.info("Listening other instances")
    sso.listen_other_instances()
    main_logger.info("Checking disk usage ...")
    sso.monitoring_diskusage()
    main_logger.info("Waiting for deployment of second SSO instance")
    sso.wait_for_other_sso_instance()
    if sso.restart_jboss:
        main_logger.info("Restarting Jboss")
        sso.perform_jboss_stop_and_start__inst_phase()
    else:
        main_logger.info("No Jboss restart needed for primary server")
    main_logger.info("Set replication-purge-delay property to: " + REPLICATION_PURGE_DELAY)
    sso.update_replication_purge_delay()
    main_logger.info("Disabling change number indexer for embedded OpenDJ")
    sso.disable_changenumber_indexer()
    main_logger.info("Tuning log policies for embedded OpenDJ")
    sso.tune_log_policies()
    main_logger.info("Enabling entries compression on embedded OpenDJ backend")
    sso.set_entries_compression_on_opends_backend()
    main_logger.info("Installation of SSO finished")
except sso_exception as e:
    main_logger.error(str(e))
except IOError as e:
    main_logger.error(str(e.strerror) + ": " + str(e.filename))
except CalledProcessError as e:
    main_logger.error(e.output)
except BaseException as e:
    main_logger.error(UNEXPECTED_ERROR.format(print_exception()))
except:
    main_logger.error(UNEXPECTED_ERROR.format(print_exception()))
finally:
    if sso.ports_locked:
        sso.manage_ports(UNLOCK)
    if sso.is_configuring:
        sso_configuring_flag(REMOVE)
