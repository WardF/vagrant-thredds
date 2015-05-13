#!/usr/bin/env bash
apt-get update
apt-get -y install wget default-jdk links

####
# Download and Install Tomcat
####

TCSRC="apache-tomcat-8.0.22"
TCTAR="$TCSRC.tar.gz"

if [ ! -f $TCSRC ]; then
    wget http://download.nextag.com/apache/tomcat/tomcat-8/v8.0.22/bin/apache-tomcat-8.0.22.tar.gz
fi

mv $TCTAR /usr/local
cd /usr/local
tar -zxf $TCTAR

cd $TCSRC

# Create a sentenv.sh script
cd bin/
echo '#!/bin/sh' > setenv.sh
echo 'export JAVA_HOME=/usr/lib/jvm/default-java' >> setenv.sh
echo 'export JAVA_OPTS="-Xmx4096m -Xms512m -server -Djava.awt.headless=true -Djava.util.prefs.systemRoot=$CATALINA_BASE/content/thredds/javaUtilPrefs"' >> setenv.sh
echo 'export CATALINE_BASE="/usr/local/$TCSRC"' >> setenv.sh
chmod 755 setenv.sh
##
# Configure tomcat
##
# Create a tomcat user for system service.
useradd tomcat

# Configure tomcat user file
TCUSERS="/usr/local/$TCSRC/conf/tomcat-users.xml"

echo "<?xml version='1.0' encoding='utf-8'?>" > $TCUSERS

echo '<tomcat-users>' >> $TCUSERS
echo '<role rolename="tomcat"/>' >> $TCUSERS
echo '<role rolename="manager-gui"/>' >> $TCUSERS
echo '<role rolename="manager-status"/>' >> $TCUSERS
echo '<user username="tomcat" password="tomcat" roles="tomcat,manager-gui,manager-status"/>' >> $TCUSERS

echo '</tomcat-users>' >> $TCUSERS

chown -R tomcat /usr/local/$TCSRC

###
# End tomcat configuration
###

#####
# Create a tomcat system init script.
# /etc/init.d/tomcat
#####

#echo '#!/bin/bash' > /etc/init.d/tomcat
echo '# Tomcat auto-start' > /etc/init.d/tomcat
echo '#' >> /etc/init.d/tomcat
echo '# description: Auto-starts tomcat' >> /etc/init.d/tomcat
echo '# processname: tomcat' >> /etc/init.d/tomcat
echo '#' >> /etc/init.d/tomcat
echo '# tomcat' >> /etc/init.d/tomcat
echo '#' >> /etc/init.d/tomcat
echo '# chkconfig:' >> /etc/init.d/tomcat
echo '# description: 	Start up the Tomcat servlet engine.' >> /etc/init.d/tomcat
echo '' >> /etc/init.d/tomcat
echo 'CATALINA_HOME="/usr/local/apache-tomcat-8.0.22"' >> /etc/init.d/tomcat

echo 'case "$1" in' >> /etc/init.d/tomcat
echo ' start)' >> /etc/init.d/tomcat
echo '        if [ -f $CATALINA_HOME/bin/startup.sh ];' >> /etc/init.d/tomcat
echo '          then' >> /etc/init.d/tomcat
echo '	    echo $"Starting Tomcat"' >> /etc/init.d/tomcat
echo '            /bin/su tomcat $CATALINA_HOME/bin/startup.sh' >> /etc/init.d/tomcat
echo '        fi' >> /etc/init.d/tomcat
echo '	;;' >> /etc/init.d/tomcat
echo ' stop)' >> /etc/init.d/tomcat
echo '        if [ -f $CATALINA_HOME/bin/shutdown.sh ];' >> /etc/init.d/tomcat
echo '          then' >> /etc/init.d/tomcat
echo '	    echo $"Stopping Tomcat"' >> /etc/init.d/tomcat
echo '            /bin/su tomcat $CATALINA_HOME/bin/shutdown.sh' >> /etc/init.d/tomcat
echo '        fi' >> /etc/init.d/tomcat
echo ' 	;;' >> /etc/init.d/tomcat
echo ' *)' >> /etc/init.d/tomcat
echo ' 	echo $"Usage: $0 {start|stop}"' >> /etc/init.d/tomcat
echo '	exit 1' >> /etc/init.d/tomcat
echo '	;;' >> /etc/init.d/tomcat
echo 'esac' >> /etc/init.d/tomcat

echo 'exit $RETVAL' >> /etc/init.d/tomcat
chmod 755 /etc/init.d/tomcat
update-rc.d tomcat defaults


#####
# End tomcat init script
#####

#####
# Start tomcat
#####
/etc/init.d/tomcat start

#####
# Install TDS server
#####

# Fetch latest tds WAR
TDSWAR="thredds.war"
if [ ! -f $TDSWAR ]; then
    wget ftp://ftp.unidata.ucar.edu/pub/thredds/4.3/current/$TDSWAR
fi
chown tomcat $TDSWAR
mv $TDSWAR /usr/local/$TCSRC/webapps

# Wait 10 seconds, then do some symbolic linkage.
echo "Waiting 10 seconds then setting up symbolic links."

count=0

TDDIR="/usr/local/$TCSRC/content/thredds"
echo "Constructing links to thredd configuration."
echo "Waiting for thredds to be installed."
while [ $count -lt 10 ]; do
    if [ -d "$TDDIR" ]; then
	count=50
    else
	echo "Sleeping 10 Seconds"
	sleep 10
    fi
done


rm $TDDIR/catalog.xml
rm $TDDIR/threddsConfig.xml
ln -s /vagrant/tds_config_plain/catalog.xml $TDDIR/catalog.xml
ln -s /vagrant/tds_config_plain/threddsConfig.xml $TDDIR/threddsConfig.xml
chown -R tomcat $TDDIR/

#####
# Clean Up
#####
mkdir -p /home/vagrant/installation_files
mv /home/vagrant/* /home/vagrant/installation_files/

chown -R vagrant:vagrant /home/vagrant

#####
# Set the proper timezone.
#####
echo "US/Mountain" | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata
