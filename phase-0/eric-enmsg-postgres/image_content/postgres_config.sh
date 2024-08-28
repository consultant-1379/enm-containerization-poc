#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi
# Set the envar to identify the server.
service rsyslog start

SCRIPT_NAME=$(basename ${0})
LOG_TAG="POSTGRES-$(hostname -s)"

GREP=/bin/grep
sed -i "s/$(hostname)/$(hostname) postgresql01/g" /etc/hosts

yum install -y expect openssh-server sudo
service sshd start

/bin/mkdir -p /root/.ssh
/bin/touch /root/.ssh/id_rsa
/bin/mkdir -p /home/cloud-user/.ssh
/bin/chmod 700 /root/.ssh
/bin/chmod 700 /home/cloud-user/.ssh
/bin/chmod 600 /root/.ssh/id_rsa

echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA7oblllZBqhMiz9t4bA7ydstzr5ydRrtEbKgP9m00OpoVkw5mFLiTDOsQMeQPPpz+jRZy1CluVq8Ue4C7e1HbCpJArQGgF5vueDuOu4yGS4UAiU9syTYuWzr8POBoox6tPAb+cIn521GOLCPO+OyMTj6s13y9taExzoocZyLVrvohtfcCvZHFUxAN/DBj1L4sFKJfZRP4XvcwRZSZ06huYJTo98Gj6SNOQLTVYFXSI5uJK8G19a/2YYASPyQNlgpog0NvjCudwZO4JRyp6K6YO4mxkI2Eukcw6N9HLNaPe0EpaqBEIuTk0qqYk3A2UHzwVMzRXTB+ySKAotwX4itXpQ== root@nfs-server.novalocal'>>/home/cloud-user/.ssh/authorized_keys

/bin/chown -R cloud-user:cloud-user /home/cloud-user/.ssh
/bin/chown  cloud-user:cloud-user /home/cloud-user/.ssh/authorized_keys

/bin/sed -i 's/# \%wheel/\%wheel/g' /etc/sudoers

/usr/sbin/usermod -aG wheel cloud-user

/bin/unlink /etc/localtime
/bin/ln -s /usr/share/zoneinfo/UTC /etc/localtime
yum install -y postgresql92-postgresql-contrib-9.2.7-1.1.el6.x86_64
yum install -y ERICenmsgpostgres_CXP9033553

# empty rc.local
sed -i  '/touch \/var\/lock\/subsys\/local/q' /etc/rc.local

#run postinstall again
/bin/chmod +x /var/tmp/sg_postinstall
/bin/chmod +x /var/tmp/postinstall
/var/tmp/sg_postinstall
/var/tmp/postinstall

# Modify the postgres user to be in the correct group
usermod -a -G enm postgres
# Set the timezone for postgres
export PGTZ=`cat /etc/sysconfig/clock | grep ZONE | awk -F'=' '{print $2}' | sed 's/"//g'`;
export PGTZ_SED=$(echo ${PGTZ} | sed 's/\//\\\//g')
sed -i "s/^timezone = .*/timezone = '${PGTZ_SED}'/g" /tmp/postgresql.conf

# Allow remote access
echo "host    all             all             0.0.0.0/0            trust" >> /tmp/pg_hba.conf

# database space crtitical threshold update
echo ". /var/tmp/update_critical_size_threshold.sh" >> /etc/rc.local
/etc/init.d/vmmonitord start
bash /etc/rc.local
