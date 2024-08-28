#!/usr/bin/python

import os
import logging.handlers
import sys
import time
import subprocess
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT


hostname = os.getenv('THIS_HOST')

SERVICE = "EXTRJBossconfig"

LOGGING = True

db_server = "postgresql01"
postgresql_pass_key = "postgresql01_admin_password"
postgres_key_file = "/ericsson/tor/data/idenmgmt/postgresql01_passkey"
global_properties_file = "/ericsson/tor/data/global.properties"


try:
    if os.name != 'nt':
        logger = logging.getLogger('EXTRjbossconfig')
        handler = logging.handlers.SysLogHandler(address='/dev/log')
        logger.setLevel(logging.INFO)
        fmt = " %(name)s %(message)s"
        fmtter = logging.Formatter(fmt, "%b %d %H:%M:%S")
        handler.setFormatter(fmtter)
        logger.addHandler(handler)
except socket.error, e:
    if LOGGING:
        print >> sys.stderr, "WARNING: " + str(SERVICE)
        + " could not connect to rsyslog! Script will continue without logging"
        print >> sys.stderr, "WARNING: " + str(SERVICE)
        + " caught a socket.error exception: " + str(e)
        LOGGING = False


def log(message, service='jboss-as', level='INFO', echo=False):
    """
    Print and log the supplied message
    """
    prefix = ' '
    if echo:
        print str(message)
    try:
        if level == 'INFO':
            logger.info(str(prefix) + str(service) + str(prefix) + str(message))
        elif level == 'DEBUG':
            logger.debug(str(prefix) + str(service)
                         + str(prefix) + str(message))
        elif level == 'ERROR':
            logger.error(str(prefix) + str(service)
                         + str(prefix) + str(message))
        else:
            logger.error("Error is logging invalid level:" + str(level))
    except socket.error, e:
        if LOGGING:
            print >> sys.stderr, "WARNING: " + str(SERVICE)
            + " could not connect to RSYSLOG!"
            + " Script will continue without logging"
            print >> sys.stderr, "WARNING: " + str(SERVICE)
            + " caught a socket.error exception: " + str(e)
            LOGGING = False


class db_connection(object):

    def __init__(self, connection_url=None):
        """
        Constructor to the context manager.

        :param connection_url: The connection url to be used to connect to db.
        by default
        """
        self.connection_url = connection_url
        self.cursor = None
        self.conn = None

    def __enter__(self):
        self.conn = psycopg2.connect(self.connection_url)
        self.conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        self.cursor = self.conn.cursor()
        return self.cursor

    def __exit__(self, exc_type, exc_val, exc_tb):
        try:
            self.cursor.close()
            self.conn.commit()
        finally:
            if 'conn' in locals():
                self.conn.close()


def check_database_is_available(db_name):
    """
    Checks if the database is available for connections
    :param db_name:
    :return: true is database available
    """
    try:
        db_postgres_password = decrypt_password(get_global_property(postgresql_pass_key))

        postgres_connection_url = "host='%s' user='%s' password='%s' port=5432" % (db_server, 'postgres', db_postgres_password)

        with db_connection(postgres_connection_url + " dbname='{0}'".format(db_name)) as cursor:
            cursor.execute("Select 1")
            return True
    except Exception as err:
        return False


def decrypt_password(enc_password):
    """
    Helper function to decrypt the password supplied
    decrypted

    :param enc_password: encrypted password
    :return: The decrypted password
    """

    cmd = 'echo {0} | openssl enc -a -d -aes-128-cbc -salt -kfile {1}'. \
        format(enc_password, postgres_key_file)

    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out, err = proc.communicate()

    if proc.returncode:
        return None

    return out.strip()


def get_global_property(prop_name):
    """Returns the value of a given property, if found from global properties

    :param prop_name: Name of the property used to retrieve the value.
    :return: Value of the property
    :raises KeyError if not property was found for the given name
    """
    global_properties = None
    with open(global_properties_file, "r") as f:
        lines = f.read().splitlines()
    global_properties = dict(line.strip().split("=", 1)
                                              for line in lines
                                              if "=" in line and
                                              not line.startswith("#"))
    return global_properties[prop_name]


def get_database_name():
    tokenlist = str(hostname).strip().split("-")
    tokencount = hostname.count('-');

    if tokenlist[tokencount].isdigit():
        # isdigit must be a cloud deployment
        if tokenlist[tokencount-1].lower().__eq__('security'):
            dbname = 'wfsdb_secserv'
        else:
            dbname = 'wfsdb_' + tokenlist[tokencount-1]
    else:
        if tokenlist[tokencount].lower().__eq__('security'):
            dbname = 'wfsdb_secserv'
        else:
            dbname = 'wfsdb_' + tokenlist[tokencount]

    return 'wfsdb_secserv'


def check_database():
    db_name='wfsdb_secserv'
    log("about to check database connection for: %s" % (db_name), SERVICE, 'INFO')
    while True:
        if check_database_is_available(db_name):
	    log("database connection was successfully established for: %s" % (db_name), SERVICE, 'INFO')
            break
        else:
	    log("Unable to establish a database connection for %s, waiting 5 seconds before trying again ..." % (db_name), SERVICE, 'INFO')
            time.sleep(5)



check_database()


