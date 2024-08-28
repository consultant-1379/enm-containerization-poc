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

This script defines SSO class and contains all SSO installation and configuration functions

Created by emapawl

"""

from sso_utils import *
from sso_const import *
from sso_consul_utils import *
from sso_consul_const import *
from sso_monitor_replication import *
import fileinput
import sys
import os.path
import socket
import os
import subprocess
import locale
from string import Template
import time
import shutil
import stat


class Sso(object):

    def __init__(self):
        """
        Definition of variables
        """
        self.properties = {}
        self.hostname = ""
        self.ui_fqdn = ""
        self.cookie_domain = ""
        self.sso_instance_fqdn = ""
        self.ip_address = ""
        self.sso_instance_name = ""
        self.second_instance_name = ""
        self.second_sso_instance_fqdn = ""
        self.sso_frontend_name = ""
        self.alias_list = []
        self.locale = LOCAL_LANGUAGE
        self.sso_rpm_version = ""
        self.admin_pwd = ""
        self.am_policy_pwd = ""
        self.am_cofig_pwd = ""
        self.agent_access_pwd = ""
        self.ldap_pwd = ""
        self.installation_status = ""
        self.other_sso_lowercase = True
        self.sso_versions_equal = False
        self.sso_socket = ""
        self.install_time = ""
        self.is_configuring = False
        self.ports_locked = False
        self.second_instance_exists = False
        self.restart_jboss = False
        self.other_sso_monitoring_enabled = False
        self.enmOnCloud = False
        self.domain_name = ""
        self.datacenter = ""
        self.auth_type = DEFAULT_AUTH_TYPE
        self.ext_auth_profile = DEFAULT_EXTERNAL_AUTH_PROFILE
        self.ext_base_dn = ""
        self.ext_primary_server = ""
        self.ext_secondary_server = ""
        self.ext_ldap_connection_mode = DEFAULT_EXT_LDAP_CONNECTION_MODE
        self.ext_bind_dn = ""
        self.ext_search_filter = ""
        self.ext_search_scope = DEFAULT_EXT_SEARCH_SCOPE
        self.ext_search_attributes = ""
        self.ext_search_controls = ""
        self.ext_user_bind_dn_format = ""
        self.ext_user_search_attributes = ""
        self.ext_user_naming_attribute = ""
        self.ext_idp_parameters_to_set = dict()
        self.detectedPrimaryInstallation = False
        self.maxSessionTimeout = DEFAULT_MAX_SESSION_TIME
        self.maxIdleSessionTimeout = DEFAULT_IDLE_SESSION_TIME
        self.enable_monitoring_diskusage = True
        self.enable_session_constraint = DEFAULT_ENABLE_SESSION_CONSTRAINT
        self.hosts_list = []
        self.amIReadyToAvoidSSOToken = False

    def read_sso_data(self, initialize_all=True):
        """
        Initialization of variables: hostnames, locale, passwords, socket creation
        """
        function_logger.info(ENTER_FUNCTION)
        self.properties = read_global_properties()
        if ENM_ON_CLOUD_GLOBAL_PROPERTY in self.properties:
            if self.properties[ENM_ON_CLOUD_GLOBAL_PROPERTY].lower() == "true":
                self.enmOnCloud = False
        logger.info("ENM on Cloud: " + str(self.enmOnCloud))
        if self.properties['UI_PRES_SERVER']:
            self.ui_fqdn = self.properties['UI_PRES_SERVER'].lower()
        else:
            raise sso_exception("Required property UI_PRES_SERVER not found in global.properties or empty")
        if self.properties['SSO_COOKIE_DOMAIN']:
            self.cookie_domain = self.properties['SSO_COOKIE_DOMAIN'].lower()
        else:
            raise sso_exception("Required property SSO_COOKIE_DOMAIN not found in global.properties or empty")
        self.hostname = socket.gethostname()
        logger.info("SSO version in installation file: " + SSO_VERSION)

        command = QUERY_SSO_RPM_VERSION
        logger.info("Executing command " + QUERY_SSO_RPM_VERSION)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        if output is not None:
            self.sso_rpm_version = output
            logger.info("SingleSignOn Rpm version: " + self.sso_rpm_version)
        else:
            logger.info("SingleSignOn Rpm version not got!")

        logger.info("Hostname set: " + self.hostname)
        self.ip_address = socket.gethostbyname(self.hostname)
        logger.info("Host IP address: " + self.ip_address)

        if (self.enmOnCloud):
            self.read_sso_data_on_cloud()
        else:
            self.read_sso_data_on_physical()
        self.setHostsList()

        with open(AM_CONFIG_ACCESS_FILE, 'r') as file:
            self.am_cofig_pwd = file.read()
        if initialize_all:
            with open(AM_ACCESS_FILE, 'r') as file:
                self.admin_pwd = file.read()
            with open(AM_POLICY_ACCESS_FILE, 'r') as file:
                self.am_policy_pwd = file.read()
            with open(AGENT_ACCESS_FILE, 'r') as file:
                self.agent_access_pwd = file.read()
            self.sso_frontend_name = "sso." + self.ui_fqdn
            if LOCAL_LANGUAGE != locale.getdefaultlocale()[0]:
                self.locale = locale.getdefaultlocale()[0]
                logger.info("Default locale " + LOCAL_LANGUAGE + " changed to " + locale.getdefaultlocale()[0])
            else:
                logger.info("Default locale " + LOCAL_LANGUAGE + " is equal to system locale")
            self.sso_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            logger.info("Socket created")
            self.install_time = time.strftime("%Y%m%d-%H%M%S")
            logger.info("Setting timestamp to " + self.install_time + " to indicate files creation ")

            self.read_external_auth_parameters()
        function_logger.info(EXIT_FUNCTION)


    def read_sso_data_on_cloud(self, initialize_all=True):
        """
        Initialization of variables
        """
        function_logger.info(ENTER_FUNCTION)
        self.domain_name = get_self_agent_domain()
        logger.info("SSO domain name: " + self.domain_name)
        self.datacenter = get_self_agent_datacenter()
        logger.info("SSO datacenter: " + self.datacenter)
        self.sso_instance_name = get_tag_for_service()
        logger.info("SSO instance alias: " + self.sso_instance_name)
        #self.sso_instance_fqdn = SSO_SERVICE_INSTANCE_FQDN.format(self.sso_instance_name,self.datacenter,self.domain_name)
        self.sso_instance_fqdn = self.sso_instance_name
        logger.info("SSO instance FQDN: " + self.sso_instance_fqdn)

        second_instance_name_list = get_catalog_service("sso")
        """if len(second_instance_name_list) == 1:
            sso_instances_fqdn_list = get_matching_hostnames(SSO_SERVICE_INSTANCE_FQDN.format("",self.datacenter,self.domain_name))
            self.second_sso_instance_fqdn = sso_instances_fqdn_list.remove(self.sso_instance_fqdn)
            self.second_instance_name = self.second_sso_instance_fqdn.split(".")[0]
        else:"""
        second_instance_name_list.remove(self.sso_instance_name)
        self.second_instance_name = None if len(second_instance_name_list) == 0 else second_instance_name_list[0]
        #self.second_sso_instance_fqdn = SSO_SERVICE_INSTANCE_FQDN.format(self.second_instance_name,self.datacenter,self.domain_name)
        self.second_sso_instance_fqdn = self.second_instance_name

        try:
            second_instance_ip = socket.gethostbyname(self.second_sso_instance_fqdn)
            self.second_instance_exists = True
            #second_alias_list = get_all_hostnames(second_instance_ip)
            logger.info("SSO second instance FQDN: " + self.second_sso_instance_fqdn)
            logger.info("Second SSO instance alias: " + self.second_instance_name)
        except:
            self.second_instance_name = None
            self.second_sso_instance_fqdn = None
            self.second_instance_exists = False
            logger.info("Second SSO instance alias not found")

        self.ldap_hosts = [OPENDJ_SERVICE.format(self.datacenter,self.domain_name)]
        function_logger.info(EXIT_FUNCTION)


    def read_sso_data_on_physical(self, initialize_all=True):
        """
        Initialization of variables
        """
        function_logger.info(ENTER_FUNCTION)
        self.alias_list = get_all_hostnames(self.ip_address)
        logger.info("All SSO aliases: " + ', '.join(self.alias_list))
        self.sso_instance_fqdn = next(alias for alias in self.alias_list if self.ui_fqdn in alias)
        logger.info("SSO instance FQDN: " + self.sso_instance_fqdn)

        self.sso_instance_name = next(iter(set(self.alias_list).intersection(SSOSITE_HOSTNAMES)))
        logger.info("SSO instance alias: " + self.sso_instance_name)

        second_instance_name_list = SSOSITE_INSTANCES
        second_instance_name_list.remove(self.sso_instance_name)
        self.second_instance_name = None if len(second_instance_name_list) == 0 else second_instance_name_list[0]
        try:
            second_instance_ip = socket.gethostbyname(self.second_instance_name)
            self.second_instance_exists = True
            second_alias_list = get_all_hostnames(second_instance_ip)
            self.second_sso_instance_fqdn = next(alias for alias in second_alias_list if self.ui_fqdn in alias)
            logger.info("SSO second instance FQDN: " + self.second_sso_instance_fqdn)
            logger.info("Second SSO instance alias: " + self.second_instance_name)
        except:
            self.second_instance_name = None
            self.second_sso_instance_fqdn = None
            self.second_instance_exists = False
            logger.info("Second SSO instance alias not found")

        self.ldap_hosts = COM_INF_LDAP_HOSTS
        function_logger.info(EXIT_FUNCTION)


    def read_external_auth_parameters(self):
        """
        Read main IdP PIB parameters to understand if and how to use external Idp authentication
        """
        function_logger.info(ENTER_FUNCTION)

        logger.info("Configuring remote Idp")
        hosts_list = self.hosts_list

        for host in hosts_list:
            auth_type = get_response_body(host, SSO_HTTP_PORT, PIB_PARAMETER_PATH.format(PIB_AUTH_TYPE), PIB_USER, PIB_PASSWORD)
            logger.info("Auth type getted from " + host + " -> " + auth_type)
            if (is_pib_parameter_value_valid(auth_type)):
                self.auth_type = auth_type
                logger.info("Auth type value valid!")
                break
            else:
                logger.info("Auth type value not valid!")

        for host in hosts_list:
            ext_auth_profile = get_response_body(host, SSO_HTTP_PORT, PIB_PARAMETER_PATH.format(PIB_REMOTE_AUTH_PROFILE), PIB_USER, PIB_PASSWORD)
            logger.info("External Remote Auth Profile getted from " + host + " -> " + ext_auth_profile)
            if (is_pib_parameter_value_valid(ext_auth_profile)):
                self.ext_auth_profile = ext_auth_profile
                logger.info("External Remote Auth Profile value valid!")
                break
            else:
                logger.info("External Remote Auth Profile value not valid!")

        for host in hosts_list:
            ext_base_dn = get_response_body(host, SSO_HTTP_PORT, PIB_PARAMETER_PATH.format(PIB_BASE_DN), PIB_USER, PIB_PASSWORD)
            logger.info("External Base DN getted from " + host + " -> " + ext_base_dn)
            if (is_pib_parameter_value_valid(ext_base_dn)):
                self.ext_base_dn = ext_base_dn
                logger.info("External Base DN value valid!")
                self.ext_idp_parameters_to_set['base-dn'] = self.ext_base_dn
                break
            else:
                logger.info("External Base DN value not valid!")

        for host in hosts_list:
            ext_primary_server = get_response_body(host, SSO_HTTP_PORT, PIB_PARAMETER_PATH.format(PIB_PRIMARY_SERVER_ADDRESS), PIB_USER, PIB_PASSWORD)
            logger.info("External Primary Server Address getted from " + host + " -> " + ext_primary_server)
            if (is_pib_parameter_value_valid(ext_primary_server)):
                self.ext_primary_server = ext_primary_server
                logger.info("External Primary Server Address value valid!")
                self.ext_idp_parameters_to_set['server'] = self.ext_primary_server
                break
            else:
                logger.info("External Primary Server Address not valid!")

        for host in hosts_list:
            ext_secondary_server = get_response_body(host, SSO_HTTP_PORT, PIB_PARAMETER_PATH.format(PIB_SECONDARY_SERVER_ADDRESS), PIB_USER, PIB_PASSWORD)
            logger.info("External Secondary Server Address getted from " + host + " -> " + ext_secondary_server)
            if (is_pib_parameter_value_valid(ext_secondary_server)):
                self.ext_secondary_server = ext_secondary_server
                logger.info("External Secondary Server Address value valid!")
                self.ext_idp_parameters_to_set['server2'] = self.ext_secondary_server
                break
            else:
                logger.info("External Secondary Server Address not valid!")

        for host in hosts_list:
            ext_ldap_connection_mode = get_response_body(host, SSO_HTTP_PORT, PIB_PARAMETER_PATH.format(PIB_LDAP_CONNECTION_MODE), PIB_USER, PIB_PASSWORD)
            logger.info("External Ldap connection mode getted from " + host + " -> " + ext_ldap_connection_mode)
            if (is_pib_parameter_value_valid(ext_ldap_connection_mode)):
                self.ext_ldap_connection_mode = ext_ldap_connection_mode
                logger.info("External Ldap connection mode value valid!")
                break
            else:
                logger.info("External Ldap connection mode not valid!")

        for host in hosts_list:
            ext_bind_dn = get_response_body(host, SSO_HTTP_PORT, PIB_PARAMETER_PATH.format(PIB_BIND_DN), PIB_USER, PIB_PASSWORD)
            logger.info("External Bind DN getted from " + host + " -> " + ext_bind_dn)
            if (is_pib_parameter_value_valid(ext_bind_dn)):
                self.ext_bind_dn = ext_bind_dn
                logger.info("External Bind DN value valid!")
                self.ext_idp_parameters_to_set['bind-dn'] = self.ext_bind_dn
                break
            else:
                logger.info("External Bind DN not valid!")

        for host in hosts_list:
            ext_user_bind_dn_format = get_response_body(host, SSO_HTTP_PORT, PIB_PARAMETER_PATH.format(PIB_USER_BIND_DN_FORMAT), PIB_USER, PIB_PASSWORD)
            logger.info("External User Bind format getted from " + host + " -> " + ext_user_bind_dn_format)
            if (is_pib_parameter_value_valid(ext_user_bind_dn_format)):
                self.ext_user_bind_dn_format = ext_user_bind_dn_format
                logger.info("External User Bind DN Format value valid!")
                self.ext_idp_parameters_to_set['user-bind-dn-format'] = self.ext_user_bind_dn_format

                self.ext_user_search_attributes = self.ext_user_bind_dn_format.split("=")[0]
                self.ext_idp_parameters_to_set['user-search-attributes'] = self.ext_user_search_attributes
                logger.info("Using User search attributes -> " + self.ext_user_search_attributes)
                self.ext_user_naming_attribute =  self.ext_user_bind_dn_format.split("=")[0]
                self.ext_idp_parameters_to_set['user-naming-attribute'] = self.ext_user_naming_attribute
                logger.info("Using User naming attribute -> " + self.ext_user_naming_attribute)
                break
            else:
                logger.info("External User Bind DN Format not valid!")

        function_logger.info(EXIT_FUNCTION)


    def store_installation_data(self):
        function_logger.info(ENTER_FUNCTION)
        logger.info(CREATING_FILE.format(SSO_DATA_FILE))
        with open(SSO_DATA_FILE, "a") as file:
            file.write(SERVER_CONTAINS_LOWERCASE_RESPONSE)
            file.write('\n' + SSO_3PP)
            file.write('\n' + MONITORING_ENABLED)
        logger.info(FILE_CREATED.format(SSO_DATA_FILE))
        function_logger.info(EXIT_FUNCTION)

    def block_ports(self):
        """
        Binding socket to port SSO_ALIVE_PORT (4320)
        and blocking HTTP and HTTPS ports except own host traffic
        """
        function_logger.info(ENTER_FUNCTION)
        """
        logger.info("Binding socket for host " + self.sso_instance_fqdn + " on port " + str(SSO_ALIVE_PORT))
        self.sso_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sso_socket.bind((self.sso_instance_fqdn, SSO_ALIVE_PORT))
        self.manage_ports(LOCK)
        """
        function_logger.info(EXIT_FUNCTION)

    def manage_ports(self, option):
        """
        HTTP and HTTPS port management. Executes iptables
        * LOCK - reject all traffic on HTTP and HTTPS ports except own host
        * UNLOCK - allow all traffic
        """
        function_logger.info(ENTER_FUNCTION)
        """
        output = subprocess.check_output(IPTABLES_LIST, shell=True, stderr=subprocess.STDOUT)
        logger.info("Ports status before change: " + output)
        if option == LOCK:
            self.ports_locked = True
            logger.info(BLOCKING_PORTS.format(SSO_HTTP_PORT, SSO_HTTPS_PORT, self.hostname))
            subprocess.check_output(IPTABLES_REJECT.format(self.hostname, SSO_HTTP_PORT), shell=True, stderr=subprocess.STDOUT)
            subprocess.check_output(IPTABLES_REJECT.format(self.hostname, SSO_HTTPS_PORT), shell=True, stderr=subprocess.STDOUT)
        elif option == UNLOCK:
            logger.info(OPENING_PORTS.format(SSO_HTTP_PORT, SSO_HTTPS_PORT, self.hostname))
            subprocess.check_output(IPTABLES_ALLOW, shell=True, stderr=subprocess.STDOUT)
            self.ports_locked = False
        output = subprocess.check_output(IPTABLES_LIST, shell=True, stderr=subprocess.STDOUT)
        logger.info("Ports status after change: " + output)
        """
        function_logger.info(EXIT_FUNCTION)

    def wait_for_sso_deployment(self):
        """
        Waiting for existence of SSO .deployed file or
        .failed file in Jboss deployment folder
        """
        function_logger.info(ENTER_FUNCTION)
        sso_deployment_pattern = JBOSS_DEPLOYMENT_DIR + SSO_DEPLOYMENT_NAME_PREFIX + "*" + EAR_FILE
        command = LS_COMMAND.format(sso_deployment_pattern)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        if output is not None:
            sso_deployment = output.strip('\n')
        else:
            raise sso_exception(FILE_DOES_NOT_EXIST.format(sso_deployment_pattern))

        sso_not_deployed = True
        while(sso_not_deployed):
            if os.path.isfile(sso_deployment + DEPLOYED_INDICATOR):
                sso_not_deployed = False
            else:
                logger.info("Waiting for deployment of " + sso_deployment)
                time.sleep(SLEEP_TIME_DEPLOYMENT)
            if os.path.isfile(sso_deployment + FAILED_INDICATOR):
                raise sso_exception("Failed deployment: " + sso_deployment)
        logger.info("Deployed " + sso_deployment)
        function_logger.info(EXIT_FUNCTION)

    def validate_global_properties_data(self):
        """
        Validates existence of properties of global.properties that
        are essential to proper SSO installation
        """
        function_logger.info(ENTER_FUNCTION)
        for key in GLOBAL_PROPERTIES_KEYS:
            if self.properties[key] == "":
                raise sso_exception(key + " variable is empty. Please set it before running script again. Exiting")
            if GLOBAL_PROPERTIES_KEYS[key] == "show":
                logger.info(key + " set to: " + self.properties[key])
            else:
                logger.info(key + " set to: *********")
        if self.ui_fqdn != self.cookie_domain:
            main_logger.warning("SSO cookie domain SSO_COOKIE_DOMAIN is not set as FQDN, that is UI_PRES_SERVER attribute in global.properties file. Some features, like multi-tab support for ENM could work incorrectly")
        function_logger.info(EXIT_FUNCTION)
        return

    def check_environment(self):
        """
        Environment check: pinging SSO frontend, LDAP hosts,
        keystore aliases check, LDAPS connection test, password decryption
        """
        function_logger.info(ENTER_FUNCTION)
        if os.path.isdir(TEMP_PATH.format(self.install_time)):
            logger.info("Directory already exists: " + TEMP_PATH.format(self.install_time))
        else:
            os.makedirs(TEMP_PATH.format(self.install_time))
            logger.info("Created temporary directory to store configuration: " + TEMP_PATH.format(self.install_time))
        logger.info("Checking if SSO hostname is reachable")
        is_reachable = ping_host(self.hostname)
        if not is_reachable:
            raise sso_exception("Own host " + self.hostname + " is not available")
        logger.info("Skipping K8s - Checking if LDAP hosts are reachable")
        #available = False
        #for host in self.ldap_hosts:
        #    output = ping_host(host)
        #    available = available or output
        #if not available:
        #    raise sso_exception("LDAP hosts are not reachable")
        logger.info("Checking keystore for aliases")
        for alias in KEYSTORE_ALIAS_LIST:
            output = subprocess.check_output(KEYTOOL_ALIAS.format(alias), shell=True, stderr=subprocess.STDOUT)
            logger.info("Alias " + alias + " exists in keystore")
        logger.info("Checking LDAP hosts connection")
        available = False
        for host in self.ldap_hosts:
            output = check_server(host, self.properties['COM_INF_LDAP_PORT'])
            available = available or output
        if not available:
            raise sso_exception("LDAP hosts are not available at port " + self.properties['COM_INF_LDAP_PORT'])
        output = subprocess.check_output(KEYTOOL_GENERATE.format(self.install_time), shell=True, stderr=subprocess.STDOUT)
        logger.info(output)
        file = open(TMP_CERT_FILE.format(self.install_time), 'r')
        lines = file.read()
        if lines.find('BEGIN CERTIFICATE') == NOT_FOUND:
            raise sso_exception("Certificate not in PEM format")
        ldap_available = []
        available = False
        for host in self.ldap_hosts:
            try:
                logger.info("Connecting " + host + " via LDAPS")
                output = subprocess.check_output(LDAP_SECURE_CURL.format(TMP_CERT_FILE.format(self.install_time), host, self.properties['COM_INF_LDAP_PORT'], self.properties['COM_INF_LDAP_ROOT_SUFFIX']), shell=True, stderr=subprocess.STDOUT)
                logger.info("LDAPS connection to " + host + " successful")
                ldap_available.append(True)
                available = True
            except CalledProcessError as e:
                logger.info("LDAPS connection to " + host + " unsuccessful")
                ldap_available.append(False)
        if not available:
            raise sso_exception("LDAP hosts are not available via LDAPS")
        if not ldap_available[0]:
            logger.info("Server " + self.ldap_hosts[0] + " is not available, reversing LDAP hosts order")
            self.ldap_hosts.reverse()

        logger.info("Decrypting LDAP password")
        if not os.path.isfile(KEY_LOCATION):
            raise sso_exception(FILE_DOES_NOT_EXIST.format(KEY_LOCATION))
        if os.path.getsize(KEY_LOCATION) == 0:
            raise sso_exception(FILE_IS_EMPTY.format(KEY_LOCATION))
        self.ldap_pwd = subprocess.check_output(OPENSSL_DECRYPT.format(self.properties['COM_INF_LDAP_ADMIN_ACCESS'], KEY_LOCATION), shell=True, stderr=subprocess.STDOUT)
        """ PLEASE NOTE
            self.ldap_pwd contains as last char the carriage return \n. We need to skip it in the following code to have the
            right password decoded.
        """
        self.ldap_pwd = self.ldap_pwd.rstrip('\n')
        logger.info("Correctly decrypted SSO LDAP password")

        """ LDAP search via CURL """
        logger.info("Performing LDAP search via CURL")
        ldap_available = []
        available = False
        ldapString = ""
        for host in self.ldap_hosts:
            try:
                ldapString = LDAP_SEARCH_SECURE_CURL.format(TMP_CERT_FILE.format(self.install_time), host, self.properties['COM_INF_LDAP_PORT'], self.properties['COM_INF_LDAP_ROOT_SUFFIX'], str(self.ldap_pwd))
                logger.info("Performing LDAP search via CURL on host " + host + " with data "+ldapString.replace(self.ldap_pwd, '***'))
                output = subprocess.check_output(ldapString, shell=True, stderr=subprocess.STDOUT)
                logger.info("Performed successfully LDAP search via CURL on host " + host)
                ldap_available.append(True)
                available = True
            except CalledProcessError as e:
                logger.info("LDAPS search to " + host + " unsuccessful")
                ldap_available.append(False)
        if not available:
            raise sso_exception("LDAP search failed via CURL")
        if not ldap_available[0]:
            logger.info("Server " + self.ldap_hosts[0] + " is not available for LDAP search, reversing LDAP hosts order")
            self.ldap_hosts.reverse()

        os.remove(TMP_CERT_FILE.format(self.install_time))
        logger.info("File removed: " + TMP_CERT_FILE.format(self.install_time))
        function_logger.info(EXIT_FUNCTION)
        return True

    def check_deployment(self, type, no_repeats):
        """
        Verification via HTTP whether SSO is deployed correctly
        """
        function_logger.info(ENTER_FUNCTION)
        response_ok = False
        for iter in range(0, no_repeats):
            time.sleep(SLEEP_TIME_DEPLOYMENT)
            logger.info(CHECK_SERVER.format(iter + 1, no_repeats, self.sso_instance_fqdn))
            http_status = get_status_code(self.sso_instance_fqdn, SSO_HTTP_PORT, KEEP_ALIVE_PATH)
            logger.info(SERVER_RETURNED_CODE.format(self.sso_instance_fqdn, str(http_status)))
            if type == RESPONSE_200:
                if http_status == 200:
                    response_ok = True
                    break
            elif type == RESPONSE_200_500:
                if http_status == 200 or http_status == 500:
                    response_ok = True
                    break
            elif type == RESPONSE_302:
                if http_status == 302:
                    response_ok = True
                    break
        if not response_ok:
            raise sso_exception("Could not reach SSO deployment. " + SERVER_RETURNED_CODE.format(self.sso_instance_fqdn, str(http_status)) + ". Check the JBoss logs of the SSO instance on this machine")
        function_logger.info(EXIT_FUNCTION)

    def is_second_configured(self, is_logged=True):
        """
        This function tries to connect second SSO instance status page.
        When accessible, it provides information about second SSO successful configuration
        and additional information about SSO configuration
        """
        response_body = get_response_body(self.second_sso_instance_fqdn, SSO_HTTP_PORT, SSO_CONFIGURED_PATH)
        if is_logged:
            logger.info("Second SSO instance response: " + response_body)
        if response_body.find(SSO_INSTALLATION_COMPLETE) != NOT_FOUND:
            if response_body.find(SSO_3PP) != NOT_FOUND:
                logger.info("SSO 3pp versions equal")
                self.sso_versions_equal = True
            else:
                logger.info("SSO 3pp versions differ")
                self.sso_versions_equal = False
            if response_body.find(SERVER_CONTAINS_LOWERCASE) != NOT_FOUND:
                self.other_sso_lowercase = True
            else:
                self.other_sso_lowercase = False
            if response_body.find(MONITORING_ENABLED) != NOT_FOUND:
                self.other_sso_monitoring_enabled = True
            else:
                self.other_sso_monitoring_enabled = False
            return True
        else:
            return False

    def is_sso_up_for_haproxy(self, is_logged=False):
        """
        This function tries to query the jsp used by haproxy to detected UP sso instances
        """
        response_body = get_response_body(self.sso_frontend_name, SSO_HTTP_PORT, SSO_HEALTH_CHECK__FOR_HAPROXY)
        if is_logged:
            logger.info("SSO fronted haproxy check response: " + response_body)
        if response_body.find(SSO_INSTALLATION_COMPLETE) != NOT_FOUND:
            logger.info("SSO frontend UP for haproxy")
            return True
        else:
            logger.info("SSO frontend DOWN for haproxy")
            return False

    def are_sso3pp_equal(self):

        response_body = get_response_body(self.second_sso_instance_fqdn, SSO_HTTP_PORT, SSO_CONFIGURED_PATH)
        logger.info("Configuration info from other server:")
        logger.info(response_body)
        if response_body.find(SSO_3PP) != NOT_FOUND:
            return True
        else:
            return False

    def check_other_deployment(self):
        """
        Verification of second SSO instance status.
        Accessibility of second SSO instance status page, information
        contained on this page and SSO_ALIVE_PORT (4320) status of
        second SSO instance are input to decision to:
        * INSTALL_AS_FIRST - installs as primary SSO instance (creates the SSO site)
        * INSTALL_AS_SECOND - installs as secondary SSO instance (joins the SSO site)
        * INSTALL_AS_SINGLE - installs as one SSO instance
        * RESTART - installs as secondary SSO instance but waits for VM restart
        VM restart is needed due to rare cases when second SSO instance was
        unable to finalize its configuration before VCS online timeout.
        Due to possible unexpected behavior of unfinished configuration it
        is advisable to configure SSO on second VM start attempt
        """
        function_logger.info(ENTER_FUNCTION)
        if self.second_instance_exists:
            if self.is_second_configured():
                logger.info("Second instance already configured")
                if self.other_sso_lowercase:
                    logger.info("Second instance url is lowercase")
                    if self.sso_versions_equal:
                        logger.info("Second instance uses compatible software version")
                        self.installation_status = INSTALL_AS_SECOND
                        logger.info("To be configured as secondary server")
                    else:
                        logger.info("Second instance uses incompatible software version")
                        self.installation_status = INSTALL_AS_FIRST
                        logger.info("To be configured as primary server")
                        logger.info(START_LISTENING.format(str(SSO_ALIVE_PORT)))
                        self.sso_socket.listen(10)
                else:
                    logger.info("Second instance url may contain uppercase letters")
                    self.installation_status = INSTALL_AS_FIRST
                    logger.info("To be configured as primary server")
                    logger.info(START_LISTENING.format(str(SSO_ALIVE_PORT)))
                    self.sso_socket.listen(10)
            else:
                logger.info("Second instance not configured")
                if check_server(self.second_sso_instance_fqdn, SSO_ALIVE_PORT):
                    logger.info("Installation of primary server ongoing")
                    #                self.installation_status = RESTART
                    self.installation_status = INSTALL_AS_SECOND
                    logger.info("To be configured as secondary server")
                else:
                    if self.is_second_configured():
                        logger.info("Second check: other instance already configured")
                        logger.info("To be configured as secondary server")
                        self.installation_status = INSTALL_AS_SECOND
                    else:
                        logger.info(START_LISTENING.format(str(SSO_ALIVE_PORT)))
                        self.sso_socket.listen(10)
                        logger.info("Waiting for check of second server on port " + str(SSO_ALIVE_PORT))
                        time.sleep(SLEEP_TIME_PARALLEL_INSTALLATION)
                        if check_server(self.second_sso_instance_fqdn, SSO_ALIVE_PORT):
                            logger.info("Parallel installation detected")
                            if self.sso_instance_name == SSO_INSTANCE_1:
                                logger.info("To be configured as primary server")
                                self.installation_status = INSTALL_AS_FIRST
                            else:
                                logger.info("To be configured as secondary server")
                                self.sso_socket.shutdown(socket.SHUT_RDWR)
                                self.sso_socket.close()
                                logger.info(STOP_LISTENING.format(str(SSO_ALIVE_PORT)))
                                #                           self.installation_status = RESTART
                                self.installation_status = INSTALL_AS_SECOND
                        else:
                            logger.info("To be configured as primary server")
                            self.installation_status = INSTALL_AS_FIRST
        else:
            logger.info("To be configured as one server")
            self.installation_status = INSTALL_AS_SINGLE
        function_logger.info(EXIT_FUNCTION)

    def wait_primary_installation_completes(self, sleep_time, no_of_tries):
        function_logger.info(ENTER_FUNCTION)
        i = 0
        while not self.is_second_configured() and i < no_of_tries:
            logger.info("Waiting until primary server completes installation")
            time.sleep(sleep_time)
            i += 1
            if not self.detectedPrimaryInstallation:
                logger.info("Setting detectedPrimaryInstallation to True")
                self.detectedPrimaryInstallation = True
        function_logger.info(EXIT_FUNCTION)

    def prepare_sso_configuration(self):
        """
        Main SSO configuration file preparation
        """
        function_logger.info(ENTER_FUNCTION)
        options = {'server_url': SSO_HTTP.format(self.sso_instance_fqdn), 'deployment_uri': SSO_NAME, 'base_dir': SSO_DEPLOYMENT_DIR, 'locale': self.locale, 'platform_locale': self.locale,
                   'admin_pwd': self.admin_pwd, 'amldapuserpasswd': self.am_policy_pwd, 'cookie_domain': self.cookie_domain, 'directory_server': self.sso_instance_fqdn,
                   'root_suffix': DATA_STORE_ROOT_SUFFIX, 'ds_dirmgrpasswd': self.am_cofig_pwd, 'userstore_host': self.ldap_hosts[0], 'userstore_port': self.properties['COM_INF_LDAP_PORT'],
                   'userstore_suffix': self.properties['COM_INF_LDAP_ROOT_SUFFIX'], 'userstore_mgrdn': self.properties['COM_INF_LDAP_ADMIN_CN'], 'userstore_passwd': self.ldap_pwd,
                   'lb_primary_url': SSO_HTTP_PATH.format(self.sso_frontend_name), 'ds_emb_repl_host2': self.second_sso_instance_fqdn,
                   'existingserverid': SSO_HTTP_PATH.format(self.second_sso_instance_fqdn), 'ds_adminport': str(DS_ADMIN_PORT), 'ds_emb_adminport': str(DS_ADMIN_PORT)}
        with open(CONFIGURATION_TEMPLATE, "r") as input:
            read_file = Template(input.read())
            substituted = read_file.substitute(options)
        with open(SSO_CONFIGURATOR_OPTIONS.format(self.install_time), "w") as output:
            for line in substituted.splitlines():
                found = False
                if self.installation_status == INSTALL_AS_FIRST or self.installation_status == INSTALL_AS_SINGLE:
                    for property in SECOND_SSO_PROPERTIES:
                        if line.find(property) != NOT_FOUND:
                            found = True
                if not found:
                    output.write(line + "\n")
        logger.info("Prepared SSO configuration file: " + SSO_CONFIGURATOR_OPTIONS.format(self.install_time) + " for " + self.installation_status + " server")
        function_logger.info(EXIT_FUNCTION)

    def move_file(self, file, operation):
        """
        This function moves OCF scripts to temporary location to
        prevent treating by VCS the required Jboss restart as failure
        * TO_TMP - moves OCF file to temporary location
        * RESTORE - restores OCF file from temporary location
        """
        function_logger.info(ENTER_FUNCTION)
        if operation == TO_TMP:
            logger.info("Moving file " + RESOURCE_D + file + " to temporary location " + VAR_TMP_FILE.format(self.install_time, file))
            shutil.move(RESOURCE_D + file, VAR_TMP_FILE.format(self.install_time, file))
        elif operation == RESTORE:
            logger.info("Restoring file " + RESOURCE_D + file + " from temporary location " + VAR_TMP_FILE.format(self.install_time, file))
            shutil.move(VAR_TMP_FILE.format(self.install_time, file), RESOURCE_D + file)
        else:
            raise sso_exception("Incorrect option of file move " + operation)
        function_logger.info(EXIT_FUNCTION)

    def base_sso_installation(self):
        """
        This function starts SSO installation, modifies file permissions, if
        improperly set, modifies Java environment variables to data used by SSO
        and restarts Jboss to finalize basic SSO installation
        """
        function_logger.info(ENTER_FUNCTION)

        if (self.installation_status == INSTALL_AS_FIRST) or (self.installation_status == INSTALL_AS_SINGLE):
            self.sleepExtraTimeforDeployment(SLEEP_TIME_AFTER_DEPLOYMENT_II)
        elif (self.installation_status == INSTALL_AS_SECOND and self.detectedPrimaryInstallation == False):
            self.sleepExtraTimeforDeployment(SLEEP_TIME_AFTER_DEPLOYMENT_UPG)
        else:
            logger.info("No need to wait extra time for deployment...")

        command = OPENAM_CONFIGURATOR.format(self.install_time, SSO_DEBUG_LOG_DIR)
        logger.info("Executing command " + command)
        output = command_real_time_log(command)
        logger.info("Tool openam-configurator-tool executed.")
        if output.find('Already configured!') != NOT_FOUND:
            raise sso_exception("SSO already configured")
        if output.find('Configuration failed') != NOT_FOUND:
            raise sso_exception("SSO configuration failed")
        logger.info("Tool openam-configurator-tool executed successfully")
        command = COPY_OPENDS_PATCHES
        logger.info("Executing command " + command)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + command + " executed successfully")
        ### TORF-254836 (repl params setting for other instance: FG issue?)
        if (not self.detectedPrimaryInstallation) and (self.installation_status == INSTALL_AS_SECOND):
            # setting replication purge-delay of other sso instance/primary server during upgrade
            command = UPDATE_REPLICATION_PURGE_DELAY.format(self.second_sso_instance_fqdn, self.am_cofig_pwd)
            command_password_hashed = UPDATE_REPLICATION_PURGE_DELAY.format(self.second_sso_instance_fqdn, "xxxxxxx")
            logger.info(EXECUTING_COMMAND + command_password_hashed)
            try:
                output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
                logger.info(COMMAND_OUTPUT + output)
            except CalledProcessError as e:
                main_logger.info(e.output)

            # setting replication compute-change-number of other sso instance/primary server during upgrade
            command = DISABLE_CHANGE_NUMBER_INDEXER.format(self.second_sso_instance_fqdn, self.am_cofig_pwd)
            command_password_hashed = DISABLE_CHANGE_NUMBER_INDEXER.format(self.second_sso_instance_fqdn, "xxxxxxx")
            logger.info(EXECUTING_COMMAND + command_password_hashed)
            try:
                output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
                logger.info(COMMAND_OUTPUT + output)
            except CalledProcessError as e:
                main_logger.info(e.output)
        ###   ---
        logger.info("Checking permissions of file " + SSO_SSOADM_HOME + SETUP)
        st = os.stat(SSO_SSOADM_HOME + SETUP)
        if (st.st_mode & (stat.S_IXOTH | stat.S_IXGRP | stat.S_IXUSR)) == (stat.S_IXOTH | stat.S_IXGRP | stat.S_IXUSR):
            logger.info("Execute permissions are already set for file " + SSO_SSOADM_HOME + SETUP)
        else:
            logger.info("Setting execute permissions for file " + SSO_SSOADM_HOME + SETUP)
            os.chmod(SSO_SSOADM_HOME + SETUP,  st.st_mode | (stat.S_IXOTH | stat.S_IXGRP | stat.S_IXUSR))
            logger.info("Execute permissions set for " + SSO_SSOADM_HOME + SETUP)
        logger.info("Executing command " + SSO_ADM_SCRIPT)
        output = subprocess.check_output(SSO_ADM_SCRIPT, shell=True, stderr=subprocess.STDOUT)
        logger.info(str(output))
        with open(SSO_ADM_FILE, "r+") as file:
            newfile = ""
            for line in file:
                if line.find(COMMAND_MANAGER) != NOT_FOUND:
                    linetoadd = MAP_SITE_TO_SERVER.format(SSO_HTTP_PATH.format(self.sso_frontend_name), SSO_HTTP_PATH.format(self.sso_instance_fqdn))
                    logger.info("Adding entry " + linetoadd.rstrip() + " to file " + SSO_ADM_FILE)
                    newfile = newfile + linetoadd + line
                elif line.find(JAVA_XMS) != NOT_FOUND:
                    linetoadd = JAVA_SECURITY_EGD
                    logger.info("Adding entry " + linetoadd.rstrip() + " to file " + SSO_ADM_FILE)
                    newfile = newfile + line + linetoadd
                elif line.find(DEBUG_DIRECTORY) != NOT_FOUND:
                    linetoadd = NEW_DEBUG_DIRECTORY.format(SSO_DEBUG_LOG_DIR)
                    logger.info("Replacing entry " + line.rstrip() + " by entry " + linetoadd.rstrip() + " in file " + SSO_ADM_FILE)
                    newfile = newfile + linetoadd
                elif line.find(LOG_DIRECTORY) != NOT_FOUND:
                    linetoadd = NEW_LOG_DIRECTORY.format(SSO_LOG_DIR)
                    logger.info("Replacing entry " + line.rstrip() + " by entry " + linetoadd.rstrip() + " in file " + SSO_ADM_FILE)
                    newfile = newfile + linetoadd
                else:
                    newfile = newfile + line
            file.seek(0)
            file.write(newfile)
        if not os.path.isfile(SSO_ADM_FILE):
            raise sso_exception(FILE_DOES_NOT_EXIST.format(SSO_ADM_FILE) + ". Command line tools were not installed. SSO initialisation may have failed")
        logger.info("Successfully modified file " + SSO_ADM_FILE)

        output = subprocess.call(COPY_ADD_MATCHING_RULE, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + COPY_ADD_MATCHING_RULE + " returned code " + str(output))
        command = CHANGE_OWNER_TO_JBOSS_USER.format(ADD_MATCHING_RULE_SCRIPT_DEPLOYED)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + command + " executed, returned code " + str(output))
        command = CHANGE_GROUP_TO_JBOSS.format(ADD_MATCHING_RULE_SCRIPT_DEPLOYED)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + command + " executed, returned code " + str(output))

        output = subprocess.call(COPY_MATCHING_RULE_LDIF, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + COPY_MATCHING_RULE_LDIF + " returned code " + str(output))
        command = CHANGE_OWNER_TO_JBOSS_USER.format(MATCHING_RULE_LDIF_DEPLOYED)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + command + " executed, returned code " + str(output))
        command = CHANGE_GROUP_TO_JBOSS.format(MATCHING_RULE_LDIF_DEPLOYED)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + command + " executed, returned code " + str(output))
        function_logger.info(EXIT_FUNCTION)

    def check_base_sso_configuration(self):
        """
        Verification of base SSO installation. Check of realms provides information
        about correct base installation and (if existing) on SSO replication status
        """
        function_logger.info(ENTER_FUNCTION)
        logger.info("Check existing configuration")

        i = 0
        while not self.am_i_ready_toAvoidSSOToken() and i < NUMBER_OF_MAX_RETRIES_TO_WAIT_FOR_SERVER_TO_BE_READY:
            i += 1
            logger.info("Waiting until this server is ready to proceed, "+str(i)+" / "+str(NUMBER_OF_MAX_RETRIES_TO_WAIT_FOR_SERVER_TO_BE_READY) +" tentatives...")
            time.sleep(SLEEP_TIME_WAIT_FOR_SERVER_TO_BE_READY)

        if self.amIReadyToAvoidSSOToken:
            output = ssoadm_command(LIST_REALMS)
            if output.find(REALM_NAME) != NOT_FOUND:
                logger.info("SSO baseline configuration exists, realm " + REALM_NAME + " found")
                logger.info("SSO configuration replication is working correctly")
            else:
                logger.info("SSO baseline configuration does not exist, realm " + REALM_NAME + " not found")
                if self.installation_status == INSTALL_AS_SECOND:
                    logger.info("SSO configuration replication does not work correctly")
                else:
                    logger.info("SSO configuration replication not verified, no other instance to check")
        else:
            logger.info("SSO seems to be not ready...")
        function_logger.info(EXIT_FUNCTION)

    def prepare_sso_configuration_files(self):
        """
        SSO configuration files preparation form templates. Placeholders are replaced by proper data.
        Configuration files are stored in temporary location but they are not removed.
        Files created:
        * Referral policy rules XML file
        * SSO policy rules XML file
        * Web agent configuration files
        * Main batch SSO configuration file
        * Last login datastore file
        * Security patch batch configuration file
        """
        function_logger.info(ENTER_FUNCTION)
        batch_options = {'REALM_NAME_PLACEHOLDER': REALM_NAME, 'SSO_HTTP_PLACEHOLDER': SSO_HTTP_PATH.format(self.sso_frontend_name), 'SSO_SERVER_PLACEHOLDER': self.sso_frontend_name,
                         'SSO_HTTP_INSTANCE_PLACEHOLDER': SSO_HTTP_PATH.format(self.sso_instance_fqdn), 'DS_FOR_PREVIOUS_LOGIN_PLACEHOLDER': LAST_LOGIN_DATASTORE.format(self.install_time),
                         'WEB_AGENT_NAME_PLACEHOLDER': WEB_AGENT_NAME, 'COOKIE_DOMAIN_PLACEHOLDER': self.cookie_domain, 'UI_SERVER_NAME_PLACEHOLDER': UI_HTTPS.format(self.ui_fqdn), 'AGENT_ACCESS_PWD_PLACEHOLDER': self.agent_access_pwd,
                         'LDAP_HOST_1_PLACEHOLDER': self.ldap_hosts[0], 'LDAP_HOST_2_PLACEHOLDER': self.ldap_hosts[0], 'LDAP_PORT_PLACEHOLDER': self.properties['COM_INF_LDAP_PORT'],
                         'AUTH_SERVICE_NAME_PLACEHOLDER': AUTH_SERVICE_NAME, 'MAX_SESSION_TIME_PLACEHOLDER': self.maxSessionTimeout,
                         'IDLE_SESSION_TIME_PLACEHOLDER': self.maxIdleSessionTimeout, 'WHITELIST_PROPERTIES_PLACEHOLDER': WHITELIST_PROPERTIES_FILE,
                         'REST_SEC_ATTRIBUTES_PLACEHOLDER': REST_SEC_ATTRIBUTES_FILE, 'SSO_DEBUG_LOG_PLACEHOLDER': SSO_DEBUG_LOG_DIR,
                         'CONFIGURATION_STORE_CONF_PLACEHOLDER' :  CONFIGURATION_STORE_CONF.format(self.install_time), 'EXTERNAL_AUTH_CHAIN__PLACEHOLDER': EXTERNAL_AUTH_CHAIN,
                         'INTERNAL_LDAP_SEARCH_FILTER_PLACEHOLDER' : INTERNAL_LDAP_SEARCH_FILTER, 'EXTERNAL_AUTH_MODE_OPENDJ_FIELD_PLACEHOLDER' : EXTERNAL_AUTH_MODE_OPENDJ_FIELD,
                         'AUDIT_LOG_SERVICE_PLACEHOLDER': AUDIT_LOG_SERVICE, 'AUDIT_LOG_GLOBAL_CSV_HANDLER_PLACEHOLDER': AUDIT_LOG_GLOBAL_CSV_HANDLER,
                         'EXTERNAL_AUTH_MODE_OPENDJ_VALUE__LOCAL_PLACEHOLDER' : EXTERNAL_AUTH_MODE_OPENDJ_VALUE__LOCAL, 'EXTERNAL_REMOTE_AUTH_PROFILE_PLACEHOLDER': self.ext_auth_profile,
                         'EXTERNAL_LDAP_CONNECTION_MODE_PLACEHOLDER': self.ext_ldap_connection_mode, 'LDAP_PASSWORD_PLACEHOLDER' : self.ldap_pwd,
                         'ENABLE_SESSION_CONSTRAINT_PLACEHOLDER':self.enable_session_constraint}

        if not (self.enmOnCloud):
            batch_options['LDAP_HOST_2_PLACEHOLDER'] = self.ldap_hosts[1]
        with open(BATCH_CONFIG_TEMPLATE, "r") as input:
            with open(BATCH_CONFIG.format(self.install_time), "w") as output:
                for line in input:
                    for key in batch_options:
                        line = line.replace(key, batch_options[key])
                    output.write(line)
        logger.info("Prepared SSO batch configuration file: " + BATCH_CONFIG.format(self.install_time))

        with open(EXTERNAL_AUTHENTICATION_BATCH_CONFIG_TEMPLATE, "r") as input:
            with open(EXTERNAL_AUTHENTICATION_BATCH_CONFIG.format(self.install_time), "w") as output:
                for line in input:
                    for key in batch_options:
                        line = line.replace(key, batch_options[key])
                    output.write(line)
        logger.info("Prepared SSO external authentication batch configuration file: " + EXTERNAL_AUTHENTICATION_BATCH_CONFIG.format(self.install_time))

        batch_options['EXTERNAL_MODULE_NAME_PLACEHOLDER'] = EXTERNAL_MODULE_NAME__CUSTOMLDAP
        batch_options['EXTERNAL_MODULE_ID_PLACEHOLDER'] = EXTERNAL_MODULE_ID__CUSTOMLDAP

        with open(EXTERNAL_AUTH_UPDATE_BATCH_CONFIG_TEMPLATE, "r") as input:
            with open(EXTERNAL_AUTH_UPDATE_BATCH_CONFIG.format(self.install_time), "w") as output:
                for line in input:
                    for key in batch_options:
                        line = line.replace(key, batch_options[key])
                    output.write(line)
                for ext_id_parameter in self.ext_idp_parameters_to_set:
                    output.write(UPDATE_MODULE.format(EXTERNAL_MODULE_NAME__CUSTOMLDAP, CUSTOMLDAP_GENERIC_ATTRIBUTE.format(ext_id_parameter), self.ext_idp_parameters_to_set[ext_id_parameter]) + '\n')
        logger.info("Prepared SSO external auth update batch configuration file: " + EXTERNAL_AUTH_UPDATE_BATCH_CONFIG.format(self.install_time))

        show_datastore = ssoadm_command(SHOW_DATASTORE, False)
        datastore_data = ""
        for line in show_datastore.splitlines():
            if (line.find(LDAP_CFG_USER_ATTR) != NOT_FOUND) or (line.find(LDAP_CFG_USER_OBJ_CLASS_ATTR) != NOT_FOUND):
                datastore_data = datastore_data + line + "\n"
        datastore_data = datastore_data + LAST_LOGIN_DATASTORE_DATA
        datastore_data = datastore_data + EXTERNAL_AUTH_DATASTORE_DATA

        with open(LAST_LOGIN_DATASTORE.format(self.install_time), "w") as output:
            output.write(datastore_data)
        logger.info("Prepared last login datastore file: " + LAST_LOGIN_DATASTORE.format(self.install_time))

        ssoadm_command(GET_SVRCFG_XML.format(SSO_HTTP_PATH.format(self.sso_instance_fqdn), CONFIGURATION_STORE_CONF_TEMPLATE))
        with open (CONFIGURATION_STORE_CONF_TEMPLATE, "r") as input:
            with open(CONFIGURATION_STORE_CONF.format(self.install_time), "w") as output:
                for line in input:
                    line = line.replace(MAX_CONN_POOL_ATTR.format(DEFAULT_SMS_MAX_CONN_POOL_SIZE), MAX_CONN_POOL_ATTR.format(SMS_MAX_CONN_POOL_SIZE))
                    output.write(line)
        logger.info("Prepared configuation store config file: " + CONFIGURATION_STORE_CONF.format(self.install_time))
        function_logger.info(EXIT_FUNCTION)

    def configure_sso_deployment(self):
        """
        This function executes main batch SSO configuration file
        and last login batch configuration file.
        Redeployment of SSO follows, to activate changed configuration
        """
        function_logger.info(ENTER_FUNCTION)

        """
        MERGED_BATCH_CONFIG
        """

        batch_file = BATCH_CONFIG.format(self.install_time)
        external_batch_file = EXTERNAL_AUTHENTICATION_BATCH_CONFIG.format(self.install_time)
        external_auth_batch_file = EXTERNAL_AUTH_UPDATE_BATCH_CONFIG.format(self.install_time)

        merged_batch_file = MERGED_BATCH_CONFIG.format(self.install_time)

        batch_files = []
        batch_files.append(external_batch_file)
        batch_files.append(external_auth_batch_file)

        if (self.installation_status == INSTALL_AS_FIRST) or (self.installation_status == INSTALL_AS_SINGLE):
            logger.info("As primary, configuring SSO deployment with input batch file " + batch_file)
            ssoadm_command(DO_BATCH.format(batch_file), real_time_log=True)
            logger.info("Configuration succeeded with batch file " + batch_file)
        elif (self.installation_status == INSTALL_AS_SECOND):
            #prepend the batch file to the top of file list
            batch_files.insert(0, batch_file)
            logger.info("Building complete merged file...")
        else:
            logger.info("Nothing to do here...")

        logger.info("Merging together batch files into " + merged_batch_file)
        with open(merged_batch_file, 'wb') as outfile:
            for fname in batch_files:
                with open(fname) as infile:
                    logger.info("Merging "+fname+" batch files into " + merged_batch_file)
                    outfile.write(infile.read())
                    #outfile.write('\n')

        chain_command = ""
        if self.auth_type == REMOTE_AUTH_TYPE:
           logger.info("Using chain " + EXTERNAL_AUTH_CHAIN)
           chain_command = SET_AUTH_CHAIN.format(EXTERNAL_AUTH_CHAIN)
        else:
           logger.info("Using chain " + AUTH_SERVICE_NAME)
           chain_command = SET_AUTH_CHAIN.format(AUTH_SERVICE_NAME)

        with open(merged_batch_file, 'a') as file:
            file.write(chain_command)

        logger.info("Configuring SSO deployment with merged input batch file " + merged_batch_file)
        ssoadm_command(DO_BATCH.format(merged_batch_file), real_time_log=True)
        logger.info("Configuration succeeded with merged batch file " + merged_batch_file)

        """
        logger.info("Configuring SSO deployment with input batch file " + BATCH_CONFIG.format(self.install_time))
        ssoadm_command(DO_BATCH.format(BATCH_CONFIG.format(self.install_time)), real_time_log=True)
        logger.info("Configuration succeeded with batch file " + BATCH_CONFIG.format(self.install_time))

        logger.info("Configuring SSO deployment with input batch file " + EXTERNAL_AUTHENTICATION_BATCH_CONFIG.format(self.install_time))
        ssoadm_command(DO_BATCH.format(EXTERNAL_AUTHENTICATION_BATCH_CONFIG.format(self.install_time)))
        logger.info("Configuration succeeded with batch file " + EXTERNAL_AUTHENTICATION_BATCH_CONFIG.format(self.install_time))

        logger.info("Configuring SSO deployment with input batch file " + EXTERNAL_AUTH_UPDATE_BATCH_CONFIG.format(self.install_time))
        ssoadm_command(DO_BATCH.format(EXTERNAL_AUTH_UPDATE_BATCH_CONFIG.format(self.install_time)))
        logger.info("Configuration succeeded with batch file " + EXTERNAL_AUTH_UPDATE_BATCH_CONFIG.format(self.install_time))


        if self.auth_type == REMOTE_AUTH_TYPE:
           logger.info("Using chain " + EXTERNAL_AUTH_CHAIN)
           ssoadm_command(SET_AUTH_CHAIN.format(EXTERNAL_AUTH_CHAIN))
        else:
           logger.info("Using chain " + AUTH_SERVICE_NAME)
           ssoadm_command(SET_AUTH_CHAIN.format(AUTH_SERVICE_NAME))
        """

        command = CHANGE_OWNER_TO_JBOSS_USER.format(SSO_LOG_DIR)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + command + " executed")
        command = CHANGE_GROUP_TO_JBOSS.format(SSO_LOG_DIR)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + command + " executed")
        function_logger.info(EXIT_FUNCTION)

    def configure_sso_deployment_after_online(self):
        """
        For the moment the only configuration done in this step is the bind Password writing
        on Custom LDAP module for External Idp.
        """
        function_logger.info(ENTER_FUNCTION)

        logger.info("Waiting until some SSO instance is up for haproxy")
        MAX_TENTATIVE_NR = 5
        tentative_nr = 0

        while ((not self.is_sso_up_for_haproxy()) and (tentative_nr < MAX_TENTATIVE_NR)):
            time.sleep(2)
            tentative_nr += 1
        if (tentative_nr == MAX_TENTATIVE_NR):
            logger.warn("Max tentatives number reached while waiting for any of SSO instances to be UP for haproxy!")
            logger.warn("Skipping remaining steps of SSO configuration ...")
        else:
            logger.info("Some SSO instance UP for haproxy")

            logger.info("Calling rest api on sso to trigger bind Password writing on OpenAM Custom LDAP module")
            hosts_list = self.hosts_list

            for host in hosts_list:
                response = post_request_with_retries(host, SSO_HTTP_PORT, REST_ENDPOINT_TO_SET_PASSWORD_ON_MODULE, HTTP_STATUS_CODE__200)
                logger.info("Result to post request: " + response)
                if response.find(SUCCESS_ON_WRITING_BIND_PASSWORD) != NOT_FOUND:
                    break
        function_logger.info(EXIT_FUNCTION)


    def configure_timeouts(self):
        """
        SSO maximum and idle timeout values configuration.
        If accessible, PIB is queried for the above values.
        If PIB is not accessible, default values are used.
        In case of PIB data inconsistency, maximal obtained values are chosen
        """

        function_logger.info(ENTER_FUNCTION)
        idle_timeout_list = []
        max_timeout_list = []
        hosts_list = self.hosts_list

        for host in hosts_list:
            max_output = get_response_body(host, SSO_HTTP_PORT, PIB_MAX_SESSION_TIMEOUT_PATH, PIB_USER, PIB_PASSWORD)
            if max_output.find(NO_CONNECTION) == NOT_FOUND:
                if max_output.isdigit():
                    max_timeout_list.append(max_output)
                else:
                    logger.info("Skipping non-numeric value received: " + max_output)
            idle_output = get_response_body(host, SSO_HTTP_PORT, PIB_IDLE_SESSION_TIMEOUT_PATH, PIB_USER, PIB_PASSWORD)
            if idle_output.find(NO_CONNECTION) == NOT_FOUND:
                if idle_output.isdigit():
                    idle_timeout_list.append(idle_output)
                else:
                    logger.info("Skipping non-numeric value received: " + idle_output)
        if max_timeout_list:
            if(len(set(max_timeout_list))) != 1:
                output = ", ".join(str(element) for element in set(max_timeout_list))
                logger.info("Inconsistency in PIB database, maximum timeouts are " + output)
                logger.info("Setting maximum timeout as highest of above values: " + max(max_timeout_list))
            else:
                logger.info("Setting maximum timeout to value received from PIB: " + max(max_timeout_list))
            self.maxSessionTimeout = str(max(max_timeout_list))
        else:
            logger.info("No connection to PIB database while fetching maximum timeout")
            logger.info("Setting default maximum session timeout to " + DEFAULT_MAX_SESSION_TIME)
            self.maxSessionTimeout = DEFAULT_MAX_SESSION_TIME
        if idle_timeout_list:
            if(len(set(idle_timeout_list))) != 1:
                output = ", ".join(str(element) for element in set(idle_timeout_list))
                logger.info("Inconsistency in PIB database, idle timeouts are " + output)
                logger.info("Setting maximum idle timeout as highest of above values: " + max(idle_timeout_list))
            else:
                logger.info("Setting maximum idle timeout to value received from PIB: " + max(idle_timeout_list))
            self.maxIdleSessionTimeout = str(max(idle_timeout_list))
        else:
            logger.info("No connection to PIB database while fetching idle timeout")
            logger.info("Setting default idle session timeout to " + DEFAULT_IDLE_SESSION_TIME)
            self.maxIdleSessionTimeout = DEFAULT_IDLE_SESSION_TIME

        function_logger.info(EXIT_FUNCTION)

    def read_session_constraint_parameters(self):
        """
        Read main enableSessionConstraint PIB parameters to limit sessions number
        """
        function_logger.info(ENTER_FUNCTION)

        logger.info("Configuring enable session constraint")
        hosts_list = self.hosts_list
        for host in hosts_list:
            enable_session_constraint = get_response_body(host, SSO_HTTP_PORT, PIB_PARAMETER_PATH.format(PIB_ENABLE_SESSION_CONSTRAINT), PIB_USER, PIB_PASSWORD)
            logger.info("enable session constraint from " + host + " -> " + enable_session_constraint)
            if is_pib_parameter_value_valid(enable_session_constraint):
                if enable_session_constraint == 'true':
                    self.enable_session_constraint = 'ON'
                    logger.info("Enable session constraint value valid!")
                    break
                else:
                    if enable_session_constraint == 'false':
                        self.enable_session_constraint = 'OFF'
                        logger.info("Enable session constraint value valid!")
                        break
                    else:
                        logger.info("Enable session constraint not valid boolean!")
            else:
                logger.info("Enable session constraint not valid!")
        function_logger.info(EXIT_FUNCTION)

    def create_configured_flag(self):
        """
        Create flag to indicate that SSO is configured already
        """
        function_logger.info(ENTER_FUNCTION)
        logger.info("Creating file " + SSO_CONFIGURED_FLAG)
        if os.path.isfile(SSO_CONFIGURED_FLAG):
            logger.info("File already exists " + SSO_CONFIGURED_FLAG)
        else:
            with open(SSO_CONFIGURED_FLAG, 'w+'):
                pass
            logger.info("Created file " + SSO_CONFIGURED_FLAG)
        function_logger.info(EXIT_FUNCTION)

    def finalize_base_configuration(self):
        """
        Finalize base-configuration: creation of configured flag
        """
        function_logger.info(ENTER_FUNCTION)
        self.create_configured_flag()
        self.manage_ports(UNLOCK)
        logger.info("SSO instance base-configured successfully")
        function_logger.info(EXIT_FUNCTION)


    def am_i_ready_toAvoidSSOToken(self, is_logged=True):
        response_body = get_response_body(self.sso_instance_fqdn, SSO_HTTP_PORT, SSO_SERVER_INFO_PATH)
        if is_logged:
            logger.info("Own SSO instance response: " + response_body)
        if response_body.find(SECURECOOKIE) != NOT_FOUND:
            logger.info("Own SSO instance is ready")
            self.amIReadyToAvoidSSOToken = True
            return True
        else:
            logger.info("Own SSO instance is not ready")
            return False


    def am_i_configured(self, is_logged=True):
        """
        Utility method to get own instance if configuration is done
        """
        response_body = get_response_body(self.sso_instance_fqdn, SSO_HTTP_PORT, SSO_CONFIGURED_PATH)
        if is_logged:
            logger.info("Own SSO instance response: " + response_body)
        if response_body.find(SSO_INSTALLATION_COMPLETE) != NOT_FOUND:
            logger.info("Own SSO instance configuration completed")
            return True
        else:
            logger.info("Own SSO instance configuration not completed")
            return False

    def finalize_configuration(self):
        """
        Finalize configuration: return to SSO error debug level,
        SSO configured flag creation, opening previously blocked
        ports and release of SSO_ALIVE_PORT
        """
        function_logger.info(ENTER_FUNCTION)
        self.create_configured_flag()
        self.manage_ports(UNLOCK)
        if self.installation_status == INSTALL_AS_FIRST:
            self.sso_socket.shutdown(socket.SHUT_RDWR)
            self.sso_socket.close()
            logger.info(STOP_LISTENING.format(str(SSO_ALIVE_PORT)))
        logger.info("SSO instance configured successfully")
        function_logger.info(EXIT_FUNCTION)

    def wait_for_other_sso_instance(self):
        """
        If more than one SSO instance exists, already configured instances
        should be restarted when new instance joins SSO site.
        This is obtained by restarting Jboss. This function waits for

        other SSO to be configured, and then restarts own Jboss to
        finalize site configuration
        """
        function_logger.info(ENTER_FUNCTION)
        if self.installation_status == INSTALL_AS_FIRST:
            counter = 0
            logger.info("Waiting for second SSO instance to configure")
            log_message = True
            for index in range(0, MAX_REPEAT_WAIT_SECOND_SSO):
                time.sleep(SLEEP_TIME_WAIT_SECOND_SSO)
                counter = counter + 1
                if counter == PRINT_SKIP_COUNT:
                    counter = 0
                    log_message = True
                    logger.info("Waiting for second SSO instance to configure")
                if self.is_second_configured(log_message) and self.are_sso3pp_equal():
                    break
                log_message = False
            if self.is_second_configured() and self.are_sso3pp_equal():
                self.restart_jboss = True
            else:
                logger.info("Second SSO instance not detected in time required. Assuming one SSO instance exists")
        elif self.installation_status == INSTALL_AS_SINGLE:
            logger.info("SSO started one instance, other SSO instance does not exist")
            self.restart_jboss = False
        else:
            logger.info("SSO started as second instance, other SSO instance already configured")

        function_logger.info(EXIT_FUNCTION)

    def secondary_sso_jboss_restart_needed(self):
        """
        Performs various check to verify whether additional container restart is needed for secondary server
        First check: if the other OpenAM has not enabled SSO monitoring, perform restart to turn this feature on
        """
        function_logger.info(ENTER_FUNCTION)
        result = False
        if (self.installation_status == INSTALL_AS_SECOND and self.is_second_configured()) or self.installation_status == INSTALL_AS_SINGLE:
            result = True
        function_logger.info(EXIT_FUNCTION)
        return result

    def perform_jboss_restart(self):
        """
        Performs container restart
        """
        function_logger.info(ENTER_FUNCTION)
        if self.installation_status == INSTALL_AS_FIRST:
            message = "Subsequent server joined the site"
        else:
            message = "Joining the site as secondary server"

        logger.info(RESTARTING_JBOSS.format(message))
        #self.move_file(JBOSS_VCS_SCRIPT, TO_TMP)
        self.is_configuring = sso_configuring_flag(CREATE)
        output = subprocess.call(JBOSS_RESTART, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + JBOSS_RESTART + " returned code " + str(output))
        #self.move_file(JBOSS_VCS_SCRIPT, RESTORE)
        self.is_configuring = sso_configuring_flag(REMOVE)
        logger.info(RESTARTED_JBOSS)
        function_logger.info(EXIT_FUNCTION)

    def perform_jboss_stop_and_start__inst_phase(self):
        """
        Performs container stop, application of add-matching-rule.sh Forgerock script and container start
        """
        function_logger.info(ENTER_FUNCTION)
        if self.installation_status == INSTALL_AS_FIRST:
            message = "Subsequent server joined the site"
        else:
            message = "Joining the site as standalone or secondary server"
        logger.info(STOPPING_JBOSS.format(message))
        #self.move_file(JBOSS_VCS_SCRIPT, TO_TMP)
        self.is_configuring = sso_configuring_flag(CREATE)
        output = subprocess.call(JBOSS_STOP, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + JBOSS_STOP + " returned code " + str(output))
        output = subprocess.call(EXECUTE_ADD_MATCHING_RULE, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + EXECUTE_ADD_MATCHING_RULE + " returned code " + str(output))
        command = CHANGE_OWNER_TO_JBOSS_USER.format(CONFIG_LDIF)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + command + " executed, returned code " + str(output))
        command = CHANGE_GROUP_TO_JBOSS.format(CONFIG_LDIF)
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + command + " executed, returned code " + str(output))
        output = subprocess.call(JBOSS_START, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + JBOSS_START + " returned code " + str(output))
        #self.move_file(JBOSS_VCS_SCRIPT, RESTORE)
        self.is_configuring = sso_configuring_flag(REMOVE)
        logger.info(RESTARTED_JBOSS)
        function_logger.info(EXIT_FUNCTION)

    def disable_replication(self):
        """
        This function disables replication between two OpenAM instances
        """
        function_logger.info(ENTER_FUNCTION)
        command = DISABLE_REPLICATION.format(self.sso_instance_fqdn, self.am_cofig_pwd)
        command_password_hashed = DISABLE_REPLICATION.format(self.sso_instance_fqdn, "xxxxxxx")
        logger.info(EXECUTING_COMMAND + command_password_hashed)
        try:
            output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
            logger.info(COMMAND_OUTPUT + output)
        except CalledProcessError as e:
            main_logger.info(e.output)
        function_logger.info(EXIT_FUNCTION)

    def update_replication_purge_delay(self):
            """
            This function sets replication-purge-delay property to 1 day
            """
            function_logger.info(ENTER_FUNCTION)
            """
            FORGEROCK CONFIGURATION IMPROVEMENT
            Related to unnecessary steps to be skipped by secondary instance, to save time
            Ticket: https://backstage.forgerock.com/support/tickets?id=23146
            """
            if self.installation_status != INSTALL_AS_SINGLE:
                command = UPDATE_REPLICATION_PURGE_DELAY.format(self.sso_instance_fqdn, self.am_cofig_pwd)
                command_password_hashed = UPDATE_REPLICATION_PURGE_DELAY.format(self.sso_instance_fqdn, "xxxxxxx")
                logger.info(EXECUTING_COMMAND + command_password_hashed)
                try:
                    output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
                    logger.info(COMMAND_OUTPUT + output)
                except CalledProcessError as e:
                    main_logger.info(e.output)
            else:
                logger.info("No replication, replication purge delay will not be changed")
            function_logger.info(EXIT_FUNCTION)

    def disable_changenumber_indexer(self):
            """
            This function disables change number indexer for embedded OpenDJ
            Workaround for https://jira-nam.lmera.ericsson.se/browse/TORF-168019
            Related ForgeRock ticket https://backstage.forgerock.com/support/tickets?id=17150
            Related ForgeRock Jira ticket: https://bugster.forgerock.org/jira/browse/OPENDJ-3706
            """
            function_logger.info(ENTER_FUNCTION)
            command = DISABLE_CHANGE_NUMBER_INDEXER.format(self.sso_instance_fqdn, self.am_cofig_pwd)
            command_password_hashed = DISABLE_CHANGE_NUMBER_INDEXER.format(self.sso_instance_fqdn, "xxxxxxx")
            logger.info(EXECUTING_COMMAND + command_password_hashed)
            try:
                output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
                logger.info(COMMAND_OUTPUT + output)
            except CalledProcessError as e:
                main_logger.info(e.output)
            function_logger.info(EXIT_FUNCTION)

    def tune_log_policies(self):
            """
            This function tunes log policies for embedded opendj and openam
            """
            function_logger.info(ENTER_FUNCTION)
            log_publishers_map = {FILE_BASED_ACCESS_LOGGER__OPENDS_LOG_PUBLISHER: FILE_BASED_ACCESS_LOGGER__LOGFILE,
                                  FILE_BASED_ERROR_LOGGER__OPENDS_LOG_PUBLISHER: FILE_BASED_ERROR_LOGGER__LOGFILE,
                                  REPLICATION_REPAIR_LOGGER__OPENDS_LOG_PUBLISHER: REPLICATION_REPAIR_LOGGER__LOGFILE}

            command = SET_FILE_SIZE_LIMIT_FOR_ROTATION_POLICY.format(self.sso_instance_fqdn, self.am_cofig_pwd)
            command_password_hashed = SET_FILE_SIZE_LIMIT_FOR_ROTATION_POLICY.format(self.sso_instance_fqdn, "xxxxxxx")
            execute_command_with_retries(command, command_password_hashed)

            command = SET_SIZE_LIMIT_FOR_RETENTION_POLICY.format(self.sso_instance_fqdn, self.am_cofig_pwd)
            command_password_hashed = SET_SIZE_LIMIT_FOR_RETENTION_POLICY.format(self.sso_instance_fqdn, "xxxxxxx")
            execute_command_with_retries(command, command_password_hashed)

            for log_publisher in log_publishers_map:

                log_file_rel_path = log_publishers_map[log_publisher]
                log_file_new_abs_path = SSO_LOG_DIR + "/opends/" + log_file_rel_path
                log_file_old_abs_path = SSO_DEPLOYMENT_DEFAULT_LOG_DIR_OPENDS + "/" + log_file_rel_path

                command = SET_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, self.am_cofig_pwd, log_publisher, ENABLED_PROPERTY_FOR_OPENDS_LOG_PUBLISHERS ,"false")
                command_password_hashed = SET_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, "xxxxxxx", log_publisher, ENABLED_PROPERTY_FOR_OPENDS_LOG_PUBLISHERS, "false")
                execute_command_with_retries(command, command_password_hashed)

                command = CP_LOG_FILE_FOR_OPENDS.format(log_file_old_abs_path)
                execute_command_with_retries(command)

                command = CHANGE_OWNER_TO_JBOSS_USER.format(log_file_new_abs_path)
                execute_command_with_retries(command)

                command = CHANGE_GROUP_TO_JBOSS.format(log_file_new_abs_path)
                execute_command_with_retries(command)

                command = SET_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, self.am_cofig_pwd, log_publisher, LOG_FILE_ROPERTY, log_file_new_abs_path)
                command_password_hashed = SET_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, "xxxxxxx", log_publisher, LOG_FILE_ROPERTY, log_file_new_abs_path)
                execute_command_with_retries(command, command_password_hashed)

                command = SET_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, self.am_cofig_pwd, log_publisher, LOG_ROTATION_POLICY_PROPERTY, SIZE_LIMIT_ROTATION_POLICY)
                command_password_hashed = SET_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, "xxxxxxx", log_publisher, LOG_ROTATION_POLICY_PROPERTY, SIZE_LIMIT_ROTATION_POLICY)
                execute_command_with_retries(command, command_password_hashed)

                command = SET_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, self.am_cofig_pwd, log_publisher, LOG_RETENTION_POLICY_PROPERTY, SIZE_LIMIT_RETENTION_POLICY)
                command_password_hashed = SET_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, "xxxxxxx", log_publisher, LOG_RETENTION_POLICY_PROPERTY, SIZE_LIMIT_RETENTION_POLICY)
                execute_command_with_retries(command, command_password_hashed)

                command = ADD_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, self.am_cofig_pwd, log_publisher, LOG_RETENTION_POLICY_PROPERTY, FILE_COUNT_RETENTION_POLICY)
                command_password_hashed = ADD_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, "xxxxxxx", log_publisher, LOG_RETENTION_POLICY_PROPERTY, FILE_COUNT_RETENTION_POLICY)
                execute_command_with_retries(command, command_password_hashed)

                command = SET_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, self.am_cofig_pwd, log_publisher, ENABLED_PROPERTY_FOR_OPENDS_LOG_PUBLISHERS ,"true")
                command_password_hashed = SET_PROPERTY_FOR_OPENDS_LOG_PUBLISHER.format(self.sso_instance_fqdn, "xxxxxxx", log_publisher, ENABLED_PROPERTY_FOR_OPENDS_LOG_PUBLISHERS, "true")
                execute_command_with_retries(command, command_password_hashed)

            function_logger.info(EXIT_FUNCTION)

    def set_entries_compression_on_opends_backend(self):
            """
            This function set compressed entries properties for userRoot backend for embedded OpenDJ
            """
            function_logger.info(ENTER_FUNCTION)
            command = SET_ENTRIES_COMPRESSED_FOR_BACKEND.format(self.sso_instance_fqdn, self.am_cofig_pwd, USER_ROOT_OPENDS_BACKEND)
            command_password_hashed = SET_ENTRIES_COMPRESSED_FOR_BACKEND.format(self.sso_instance_fqdn, "xxxxxxx", USER_ROOT_OPENDS_BACKEND)
            logger.info(EXECUTING_COMMAND + command_password_hashed)
            try:
                output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
                logger.info(COMMAND_OUTPUT + output)
            except CalledProcessError as e:
                main_logger.info(e.output)
            function_logger.info(EXIT_FUNCTION)

    def listen_other_instances(self):
            """
            Listen to other instances -- a primitive form of signals exchange
            Currently a connection to the listening port by the other instance represents the triggering
            signal to disable replication
            """
            function_logger.info(ENTER_FUNCTION)
            if self.second_instance_exists:
                logger.info("Start child process to listen other instances signals")
                pid = os.fork()
                if pid == 0:
                    """Child execution"""
                    logger.info("Child process starting execution to listen other instances")
                    os.execv(PYTHON, ['-c', LISTENER_SCRIPT, self.sso_instance_name, str(LISTENER_PORT), self.second_sso_instance_fqdn])
                else:
                    """Father execution"""
                    logger.info("Main install script process going on ... Child pid: {0}".format(str(pid)))
                    with open(SSO_LISTENER__PID, 'w', 0) as sso_listener_pid_file:
                        sso_listener_pid_file.write(str(pid))
            else:
                logger.info("No need to listen other instances signals")

            function_logger.info(EXIT_FUNCTION)

    def signal_other_instance(self):
        """
        This method is useful to the current instance to signal to the other one that it's shutting down;
        signalation happens after the current instance has disabled replication and the other instance will decide if
        it's the moment to disable replication by itself (more than two instances could be present in the site)
        """
        function_logger.info(ENTER_FUNCTION)
        if check_server(self.second_instance_name, LISTENER_PORT) == True:
            logger.info("Signalation done to the other instance!")
        else:
            logger.info("Signalation not done to the other instance!")

        function_logger.info(EXIT_FUNCTION)

    def setHostsList(self):
        """
        This method to set the list of valid hosts fqdn, handling None fqdn if needed
        """
        logger.info("Setting fqdn hosts list")
        self.hosts_list = [self.sso_instance_fqdn]
        if self.second_sso_instance_fqdn is not None :
            logger.info("Appending {0} as second sso fqdn instance".format(self.second_sso_instance_fqdn))
            self.hosts_list.append(self.second_sso_instance_fqdn)
        else:
            logger.info("Just one sso fqdn instance found")

    def sleepExtraTimeforDeployment(self, sleep):
        """
        This method to wait extra time before proceeding with any configurator.jar tool, to avoid possible SSO token admin exception
        """
        logger.info("Sleeping for extra {0} s before proceeding".format(sleep))
        time.sleep(sleep)


    def runSSOLogScript(self):
        function_logger.info(ENTER_FUNCTION)
        output = subprocess.call(EXECUTE_SSO_LOGS_SCRIPT, shell=True, stderr=subprocess.STDOUT)
        logger.info("Command " + EXECUTE_SSO_LOGS_SCRIPT + " returned code " + str(output))
        function_logger.info(EXIT_FUNCTION)


    def monitoring_diskusage(self):
            """
            This function will continuously check disk usage,
            as per workaround to avoid problem when  storage is going to fill space
            """
            function_logger.info(ENTER_FUNCTION)
            if self.enable_monitoring_diskusage:
                #Start thread to monitor the other instance status
                logger.info("Start child process to monitor disk usage")
                pid = os.fork()
                if pid == 0:
                    """Child execution"""
                    logger.info("Child process starting execution to monitor disk usage")
                    os.execv(PYTHON, ['-c', DISKUSAGE_MONITORING_SCRIPT, self.sso_instance_name, str(DISKUSAGE_INT), str(DISKUSAGE_THRESHOLD)])
                else:
                    """Father execution"""
                    logger.info("Main install script process going on ... Child pid: {0}".format(str(pid)))
                    with open(MONITOR_DISKUSAGE__PID, 'w', 0) as monitor_diskusage_pid_file:
                        monitor_diskusage_pid_file.write(str(pid))
                    return pid
            else:
                logger.info("Nothing to do, no disk usage monitoring must be managed")
            function_logger.info(EXIT_FUNCTION)
