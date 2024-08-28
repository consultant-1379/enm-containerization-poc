#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi

/bin/mkdir -p /root/.ssh
/bin/cp /var/tmp/postgres_key.pem /root/.ssh/id_rsa
/bin/chmod 600 /root/.ssh/id_rsa

/bin/chmod 777 /ericsson/3pp/jboss/bin/post-start/rename_currentxml.sh
#Remove the file to tag a previous SPS correct restart if it exists
#rm -f /ericsson/tor/data/spsrestartcomplete.txt

#workaround #1 sps scripts
#Configure Postgres, ssh to be removed with a better solution
ssh -o 'StrictHostKeyChecking no' -tt cloud-user@postgresql01 "sudo yum install -y ERICpkiservicedb_CXP9031995;\n
sudo su - postgres -c 'createdb pkicoredb';\n
sudo bash /ericsson/pki_postgres/db/pkicore/install_update_pkicore_db.sh;\n
sudo su - postgres -c 'createdb pkimanagerdb';\n
sudo bash /ericsson/pki_postgres/db/pkimanager/install_update_pkimanager_db.sh;\n
sudo su - postgres -c 'createdb pkirascepdb';\n
sudo bash /ericsson/pki_postgres/db/pkirascep/install_update_pkirascep_db.sh;\n
sudo su - postgres -c 'createdb pkiracmpdb';\n
sudo bash /ericsson/pki_postgres/db/pkiracmp/install_update_pkiracmp_db.sh;\n
sudo su - postgres -c 'createdb pkiratdpsdb';\n
sudo bash /ericsson/pki_postgres/db/pkiratdps/install_update_pkiratdps_db.sh;\n
sudo su - postgres -c 'createdb pkicdpsdb';\n
sudo bash /ericsson/pki_postgres/db/pkicdps/install_update_pkicdps_db.sh;\n
sudo su - postgres -c 'createdb kapsdb';\n
sudo bash /ericsson/pki_postgres/db/kaps/install_update_kaps_db.sh"

