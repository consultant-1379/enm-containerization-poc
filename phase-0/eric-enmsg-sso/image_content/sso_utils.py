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

This script contains utility functions needed for SSO installation

Created by emapawl

"""

from sso_const import *
import os
import sys
import threading
import linecache
import socket
import re
import httplib
import urllib
import base64
import subprocess
import time
import datetime
from OpenSSL import SSL
import logging
import logging.handlers
import Queue
import signal


class sso_exception(Exception):
    """
    New exception, raised when SSO installation fails for some reason
    """
    def __init__(self, message):
        super(sso_exception, self).__init__(message)


def print_exception():
    """
    Prints unexpected exceptions
    """
    exc_type, exc_obj, tb = sys.exc_info()
    f = tb.tb_frame
    lineno = tb.tb_lineno
    filename = f.f_code.co_filename
    linecache.checkcache(filename)
    line = linecache.getline(filename, lineno, f.f_globals)
    return '({0}, line {1} "{2}"): {3}'.format(filename, lineno, line.strip(), exc_obj)

"""
For Python version 2.6.6 check_output function does not exist is subprocess module.
The below code adds check_output, as it is defined in higher Python versions
"""
if "check_output" not in dir(subprocess):
    def f(*popenargs, **kwargs):
        if 'stdout' in kwargs:
            raise ValueError('stdout argument not allowed, it will be overridden.')
        process = subprocess.Popen(stdout=subprocess.PIPE, *popenargs, **kwargs)
        output, unused_err = process.communicate()
        retcode = process.poll()
        if retcode:
            cmd = kwargs.get("args")
            if cmd is None:
                cmd = popenargs[0]
            raise subprocess.CalledProcessError(retcode, cmd, output=output)
        return output
    subprocess.check_output = f


class CalledProcessError(Exception):
    """
    For Python version 2.6.6 CalledProcessError does not provide useful information
    about command output. The below code adds command output to error data
    """
    def __init__(self, returncode, cmd, output=None):
        self.returncode = returncode
        self.cmd = cmd
        self.output = output

    def __str__(self):
        return "Command '%s' returned non-zero exit status %d" % (self.cmd, self.returncode)

subprocess.CalledProcessError = CalledProcessError

logger = logging.getLogger('basicLogger')
logger.setLevel(logging.INFO)
handler = logging.handlers.SysLogHandler('/dev/log')
formatter = logging.Formatter(SSO_LEVEL_FILE + '   %(message)s')
handler.formatter = formatter
logger.addHandler(handler)

function_logger = logging.getLogger('functionLogger')
function_logger.setLevel(logging.INFO)
function_handler = logging.handlers.SysLogHandler('/dev/log')
function_formatter = logging.Formatter(SSO_LEVEL_FILE + ' %(message)s function %(funcName)s')
function_handler.formatter = function_formatter
function_logger.addHandler(function_handler)

main_logger = logging.getLogger('mainLogger')
main_logger.setLevel(logging.INFO)
main_handler = logging.handlers.SysLogHandler('/dev/log')
main_formatter = logging.Formatter(SSO_LEVEL_FILE + '** %(message)s **')
main_handler.formatter = main_formatter
main_logger.addHandler(main_handler)


def check_if_sso_configured():
    """
    Simple verification whether SSO is configured. Check on existence of particular files/folders
    """
    value = False
    if os.path.isfile(SSO_CONFIGURED_FLAG):
        value = True

    logger.info("Checking if sso configured: " + str(value))
    return value


def check_if_sso_installed():
    """
    Simple verification whether SSO is installed already. Check on existence of particular files/folders
    """
    if os.path.isfile(SSO_DEPLOYMENT_DIR_BOOTSTRAP):
        if os.path.isdir(SSO_DEPLOYMENT_DIR_OPENDS):
            main_logger.info("Installation of SSO detected")
            return True
        else:
            main_logger.error("Incomplete SSO installation detected")
            return True
    else:
        if os.path.isdir(SSO_DEPLOYMENT_DIR_OPENDS):
            main_logger.error("Incomplete SSO installation detected")
            return True
        else:
            main_logger.info("No previous SSO installation detected")
            return False


def check_java_version():
    """
    Check and log Java versions used by SSO installation/configuration scripts
    """
    function_logger.info(ENTER_FUNCTION)
    logger.info("Checking java version set for keystore management at location " + JAVA_HOME_DEFAULT)
    output = subprocess.check_output(JAVA_HOME_DEFAULT + "/jre" + JAVA_VERSION, shell=True, stderr=subprocess.STDOUT)
    logger.info(output)
    function_logger.info(EXIT_FUNCTION)


def read_global_properties():
    """
    Read attributes from global.properties file
    """
    properties = {}
    repeat_time = MAX_REPEAT_WAIT_FOR_GLOBAL_PROPS
    sleep_time = SLEEP_TIME_WAIT_FOR_GLOBAL_PROPS
    for iter in range(0, repeat_time):
        if os.path.isfile(GLOBAL_PROPERTIES):
            break
        logger.info(WAITING_FOR_GLOBAL_PROPERTIES.format(iter + 1, repeat_time, GLOBAL_PROPERTIES))
        time.sleep(sleep_time)
    if os.path.isfile(GLOBAL_PROPERTIES):
        logger.info(FILE_EXISTS.format(GLOBAL_PROPERTIES))
    else:
        raise sso_exception(FILE_DOES_NOT_EXIST.format(GLOBAL_PROPERTIES))
    with open(GLOBAL_PROPERTIES, "rt") as f:
        for line in f:
            if GLOBAL_PROPS_SEPARATOR in line:
                name, value = line.split(GLOBAL_PROPS_SEPARATOR, 1)
                properties[name.strip()] = value.strip()
    return properties


def utility_manage_ports(option, hostname):
    """
    HTTP and HTTPS port management. Executes iptables
    * LOCK - reject all traffic on HTTP and HTTPS ports except own host
    * UNLOCK - allow all traffic
    """
    function_logger.info(ENTER_FUNCTION)
    #output = subprocess.check_output(IPTABLES_LIST, shell=True, stderr=subprocess.STDOUT)
    #logger.info("Ports status before change: " + output)
    #ports_locked = False
    #if option == LOCK:
    #    ports_locked = True
    #    logger.info(BLOCKING_PORTS.format(SSO_HTTP_PORT, SSO_HTTPS_PORT, hostname))
    #    subprocess.check_output(IPTABLES_REJECT.format(hostname, SSO_HTTP_PORT), shell=True, stderr=subprocess.STDOUT)
    #    subprocess.check_output(IPTABLES_REJECT.format(hostname, SSO_HTTPS_PORT), shell=True, stderr=subprocess.STDOUT)
    #    portCommand = TOUCH_LOCK_PORT_FILE_FLAG

    #elif option == UNLOCK:
    #    logger.info(OPENING_PORTS.format(SSO_HTTP_PORT, SSO_HTTPS_PORT, hostname))
    #    subprocess.check_output(IPTABLES_ALLOW, shell=True, stderr=subprocess.STDOUT)
    #    portCommand = CLEAR_LOCK_PORT_FILE_FLAG

    #output = subprocess.check_output(IPTABLES_LIST, shell=True, stderr=subprocess.STDOUT)
    #logger.info("Ports status after change: " + output)

    #logger.info("Executing command " + portCommand)
    #output = subprocess.check_output(portCommand, shell=True, stderr=subprocess.STDOUT)

    function_logger.info(EXIT_FUNCTION)
    #return ports_locked

def clear_configured_flag():
    function_logger.info(ENTER_FUNCTION)
    command = CLEAR_SSO_CONFIGURED_FLAG
    logger.info("Executing command " + command)
    output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    logger.info("Command " + command + " executed successfully")
    function_logger.info(EXIT_FUNCTION)


def clear_previous_configuration():
    function_logger.info(ENTER_FUNCTION)
    command = CLEAR_SSO_HOME
    logger.info("Executing command " + command)
    output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    logger.info("Command " + command + " executed successfully")

    command = CLEAR_SSO_TOOLS_HOME
    logger.info("Executing command " + command)
    output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    logger.info("Command " + command + " executed successfully")

    clear_configured_flag()

    command = CLEAR_LOCK_PORT_FILE_FLAG
    logger.info("Executing command " + command)
    output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    logger.info("Command " + command + " executed successfully")

    command = CLEAR_SSO_DATA
    logger.info("Executing command " + command)
    output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    logger.info("Command " + command + " executed successfully")

    function_logger.info(EXIT_FUNCTION)
    return True


def encode_output(msg):
    msg = urllib.unquote_plus(msg)
    return msg


def ssoadm_command(command, log_flag=True, real_time_log=False):
    """
    Execute SSO ssoadm command
    Log option:
    * True - log this output of this command (default)
    * False - do not log output of this command
    Real time log option:
    * True - log this output of this command in real-time
    * False - do not log output of this command in real-time (default)
    """
    logger.info("Executing ssoadm command: " + command)
    if not real_time_log:
        output = subprocess.check_output(SSO_ADM_COMMAND.format(command), shell=True, stderr=subprocess.STDOUT)
        output = encode_output(output)
        if log_flag:
            for line in output.splitlines():
                line = line.rstrip()
                if line:
                    logger.info(line)
        return output
    else:
        output = command_real_time_log(SSO_ADM_COMMAND.format(command))
        return output


def sso_configuring_flag(state):
    """
    SSO configuring flag handling. This flag is used when Jboss restarts to detect already started SSO installation.
    * CHECK - verify whether flag exists
    * CREATE - create SSO configuring flag
    * REMOVE - remove SSO configuring flag
    """
    if state == CHECK:
        if os.path.isfile(SSO_CONFIGURING_FLAG):
            return True
        else:
            return False
    if state == CREATE:
        logger.info("Creating file " + SSO_CONFIGURING_FLAG)
        if os.path.isfile(SSO_CONFIGURING_FLAG):
            logger.info("File already exists " + SSO_CONFIGURING_FLAG)
        else:
            with open(SSO_CONFIGURING_FLAG, 'w+'):
                pass
            logger.info("Created file " + SSO_CONFIGURING_FLAG)
        return True
    if state == REMOVE:
        logger.info("Removing file " + SSO_CONFIGURING_FLAG)
        if os.path.isfile(SSO_CONFIGURING_FLAG):
            logger.info("Sleeping " + str(SLEEP_TIME_FLAG_REMOVAL) + " seconds before removal to disable invocation of second installation script")
            time.sleep(SLEEP_TIME_FLAG_REMOVAL)
            os.remove(SSO_CONFIGURING_FLAG)
            logger.info("Removed file " + SSO_CONFIGURING_FLAG)
        else:
            logger.info("File does not exists, removal not needed for " + SSO_CONFIGURING_FLAG)
        return False


def ping_host(host):
    """
    Ping host provided
    """
    try:
        output = subprocess.check_output("ping -c 2 " + host, shell=True, stderr=subprocess.STDOUT)
    except CalledProcessError as e:
        logger.info("Server " + host + " is down")
        logger.info(e.output)
        return False
    logger.info("Server " + host + " is up")
    return True


def get_all_hostnames(ip):
    """
    Collects all hostname aliases for a given IP address
    """
    alias_list = []
    hosts = subprocess.check_output(GETENT_HOSTS, shell=True, stderr=subprocess.STDOUT)
    for line in hosts.splitlines():
        if line.find(ip) != NOT_FOUND:
            alias_list_tmp = line.split()
            if ip in alias_list_tmp:
                alias_list_tmp.remove(ip)
                alias_list = alias_list_tmp + alias_list
    return [element.lower() for element in alias_list]


def get_matching_hostnames(namePattern):
    """
    Collects all /etc/hosts hostnames for a given name pattern
    """
    hostname_list = []
    with open(ETC_HOSTS_FILENAME, "r") as file:
        for line in file:
            if line.find(namePattern) != NOT_FOUND:
                line_splitted = line.split()
                for element in line_splitted[1:]:
                    if namePattern in element:
                        hostname_list.append(element)
    return hostname_list


def get_hostname_match(name):
    """
    Collects all hostname aliases that point to the same host as name given
    """
    alias_list = []
    name = name.lower()
    ip_address_list = []
    hosts = subprocess.check_output(GETENT_HOSTS, shell=True, stderr=subprocess.STDOUT)
    for line in hosts.splitlines():
        if line.lower().find(name) != NOT_FOUND:
            ip_address_list.append(line.split()[0])
    for ip in set(ip_address_list):
        alias_list.append(socket.getfqdn(ip))
    return alias_list


def check_server(address, port, excepton_raise=False):
    """
    Check connection to given host on given port.
    Raise exception option:
    * True - raise exception on connection error when host accessible
    * False - do not raise exception on connection error when host accessible (default)
    """
    s = socket.socket()
    logger.info(ATTEMPTING_TO_CONNECT.format(address, str(port)))
    try:
        result = s.connect_ex((address, int(port)))
        if result == 0:
            logger.info("Connected. Application is listening on port %s for %s" % (port, address))
            return True
        else:
            if excepton_raise:
                raise sso_exception(NO_APPLICATION_LISTENING.format(address, str(port)))
            else:
                logger.info(NO_APPLICATION_LISTENING.format(address, str(port)))
            return False
    except socket.error, e:
        raise sso_exception(CONNECTION_FAILED.format(address, str(port), str(e)))
        return False


def get_status_code(host, port, path="/"):
    """
    Return HTTP status code for a given path on server
    """
    conn = httplib.HTTPConnection(host, port)
    conn.request("HEAD", path)
    return conn.getresponse().status


def get_response_body(host, port, path="/", user="", password=""):
    """
    Return HTTP response body for a given path on server.
    Optional basic authentication parameters
    """
    try:
        conn = httplib.HTTPConnection(host, port, timeout=22)
        if user:
            user_password = base64.b64encode(user + ":" + password).decode("ascii")
            headers = {'Authorization': 'Basic %s' % user_password}
            conn.request("GET", path, headers=headers)
        else:
            conn.request("GET", path)
        return conn.getresponse().read()
    except IOError as e:
        return NO_CONNECTION_TO_HOST.format(host, str(port), path)


def post_request(host, port, path="/"):
    """
    Execute a basic POST for a given path on server.
    """
    conn = httplib.HTTPConnection(host, port, timeout=22)
    conn.request("POST", path)
    return conn.getresponse()


def post_request_with_retries(host, port, path="/", acceptableCode=HTTP_STATUS_CODE__200):
    """
    Execute a basic POST N times for a given path on server.
    """
    status_code = ""
    tentative_nr = 0
    
    while ((status_code.find(acceptableCode) == NOT_FOUND) & (tentative_nr < MAX_NUMBER_OF_RETRIES_FOR_HTTP_POSTS)): 
        try:
            response = post_request(host, port, path)
        except IOError as e:
            return NO_CONNECTION_TO_HOST.format(host, str(port), path)
    
        status_code = str(response.status)            
        tentative_nr += 1
        time.sleep(5)
        
    return response.read()


def read_output(pipe, funcs):
    """
    Helper function to command_real_time_log function
    """
    for line in iter(pipe.readline, ''):
        for func in funcs:
            func(line)
    pipe.close()


def write_output(get):
    """
    Helper function to command_real_time_log function
    """
    for line in iter(get, None):
        for subline in encode_output(line).splitlines():
            if subline.rstrip() != "":
                logger.info(subline)


def command_real_time_log(command):
    """
    This command performs real time logging for long lasting commands
    """
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=1)
    q = Queue.Queue()
    out, err = [], []
    tout = threading.Thread(target=read_output, args=(process.stdout, [q.put, out.append]))
    terr = threading.Thread(target=read_output, args=(process.stderr, [q.put, err.append]))
    twrite = threading.Thread(target=write_output, args=(q.get,))
    for t in (tout, terr, twrite):
        t.daemon = True
        t.start()
    process.wait()
    for t in (tout, terr):
        t.join()
    q.put(None)
    return '\n'.join(out) + '\n'.join(err)


def execute_command_with_retries(command, command_hashed=None):
    """
    This command performs various retries for input command
    """
    tentative_nr = 0
    successfulCommand = False
    if (command_hashed is None):
        commandToLog = command
    else:
        commandToLog = command_hashed

    while (tentative_nr < MAX_NUMBER_OF_RETRIES_FOR_COMMANDS and (not successfulCommand)):
        logger.info(EXECUTING_COMMAND + commandToLog + " for tentative number: " + str(tentative_nr))
        try:
            output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
            successfulCommand = True
            logger.info(COMMAND_OUTPUT + output)
        except CalledProcessError as e:
            tentative_nr += 1
            main_logger.info(e.output)
            

def is_pib_parameter_value_valid(parameter):
    """
    This method checks if input pib parameter string represents a null value
    """
    if (parameter != "[]" and parameter != NULL_VALUE and not parameter.startswith(NO_CONNECTION)):
        return True
    else:
        return False

def get_sec_serv_hosts_list():
    host_list = get_hostname_match(SECSERV)
    if host_list:
        logger.info("The following " + SECSERV + " hosts were found: " + ', '.join(host_list))
    else:
        logger.info("No hosts available matching name " + SECSERV)
        host_list = get_hostname_match(SECURITY)
        if host_list:
            logger.info("The following " + SECURITY + " hosts were found: " + ', '.join(host_list))
        else:
            logger.info("No hosts available matching name " + SECURITY)
    return host_list

def get_sso_hosts_list():
    host_list = get_hostname_match(SSO)
    if host_list:
        logger.info("The following " + SSO + " hosts were found: " + ', '.join(host_list))
    else:
        logger.info("No hosts available matching name " + SECSERV)
    return host_list

def removeChangeLogFiles():
    """
    This method removes the changelogDb directory when the instance goes down or whenever the active instance 
    detects the other instance is down.
    """
    logger.info("Removing changelogDb")
    command = CLEAR_SSO_CHANGELOGDB
    output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    logger.info("Executed command " + command + " with result " + output)
    logger.info("Removed changelogDb")

def killDiskUsageMonitorProcess():
    logger.info("Getting monitor disk usage process pid ...")
    monitor_diskusage_pid = None
    try:
        with open(MONITOR_DISKUSAGE__PID, 'r', 0) as monitor_diskusage_pid_file:
            monitor_diskusage_pid = int(monitor_diskusage_pid_file.read())
    except IOError as e:
        logger.info("Problem in reading monitor disk usage process pid ...")
        logger.info("I/O Error: {0} {1}".format(e.errno, e.strerror))
        
    if monitor_diskusage_pid is not None:
        logger.info("Killing monitor disk usage process ...")
        try:
            os.kill(monitor_diskusage_pid, signal.SIGTERM)
        except OSError as e:
            logger.info("Problem in killing monitor disk usage process ...")
            logger.info("OS Error: {0} {1}".format(e.errno, e.strerror))

    logger.info("Completed kill of disk usage monitor process pid ...")

def killListenerOtherInstanceProcess():
    """
    This method will kill the listener of other instance signal process
    """
    logger.info("Getting sso listener process pid ...")
    sso_listener_pid = None
    try:
        with open(SSO_LISTENER__PID, 'r', 0) as sso_listener_pid_file:
            sso_listener_pid = int(sso_listener_pid_file.read())
    except IOError as e:
        logger.info("Problem in reading sso listener process pid ...")
        logger.info("I/O Error: {0} {1}".format(e.errno, e.strerror))
        
    if sso_listener_pid is not None:
        logger.info("Killing sso listener process ...")
        try:
            os.kill(sso_listener_pid, signal.SIGTERM)
        except OSError as e:
            logger.info("Problem in killing sso listener process ...")
            logger.info("OS Error: {0} {1}".format(e.errno, e.strerror))
    logger.info("Completed kill of sso listener process pid ...")
