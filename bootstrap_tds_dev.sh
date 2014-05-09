#!/usr/bin/env bash

#####
# Install development tools when using this profile.
##### 

# Only do this if we haven't already provisioned the system.
if [ ! -d /home/vagrant/installation_files ]; then
    apt-get update
    apt-get -y install wget default-jdk links ubuntu-dev-tools git m4 libcurl4-openssl-dev htop libtool bison flex autoconf curl g++ midori libjpeg-dev
fi

## Install several packages from source.
# * cmake
# * hdf4
# * hdf5
# * netcdf

CMAKE_VER="cmake-2.8.12.2"
HDF4_VER="hdf-4.2.10"
HDF5_VER="hdf5-1.8.12"
NC_VER="v4.3.2"

# Install cmake from source
if [ ! -f /usr/local/bin/cmake ]; then
    CMAKE_FILE="$CMAKE_VER".tar.gz
    wget http://www.cmake.org/files/v2.8/$CMAKE_FILE
    tar -zxf $CMAKE_FILE
    pushd $CMAKE_VER
    ./configure --prefix=/usr/local
    make install
    popd
    rm -rf $CMAKE_VER
fi

# Install hdf4 from source.
if [ ! -f /usr/local/lib/libhdf4.settings ]; then
    HDF4_FILE="$HDF4_VER".tar.bz2
    wget http://www.hdfgroup.org/ftp/HDF/HDF_Current/src/$HDF4_FILE
    tar -jxf $HDF4_FILE
    pushd $HDF4_VER
    ./configure --disable-static --enable-shared --disable-netcdf --disable-fortran --prefix=/usr/local
    sudo make install
    popd
    rm -rf $HDF4_VER
fi

# Install hdf5 from source
if [ ! -f /usr/local/lib/libhdf5.settings ]; then
    HDF5_FILE="$HDF5_VER".tar.bz2
    wget http://www.hdfgroup.org/ftp/HDF5/current/src/$HDF5_FILE
    tar -jxf $HDF5_FILE
    pushd $HDF5_VER
    ./configure --disable-static --enable-shared --disable-fortran --enable-hl --disable-fortran --prefix=/usr/local
    make install
    popd
    rm -rf $HDF5_VER
fi

# Install netcdf from source
if [ ! -f /usr/local/include/netcdf.h ]; then
    NC_DIR="nc-$NC_VER"
    git clone http://github.com/Unidata/netcdf-c "$NC_DIR"
    cd "$NC_DIR"
    mkdir build
    cd build/
    cmake .. -DENABLE_HDF4=ON -DENABLE_DAP=ON -DENABLE_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_PREFIX_PATH=/usr/local
    make
    make install
    cd /home/vagrant
    rm -rf $NC_DIR
fi

####
# Download and Install Tomcat
####

TCSRC="apache-tomcat-7.0.53"
TCTAR="$TCSRC.tar.gz"

if [ ! -f $TCSRC ]; then
    wget http://www.webhostingjams.com/mirror/apache/tomcat/tomcat-7/v7.0.53/bin/apache-tomcat-7.0.53.tar.gz
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
echo 'CATALINA_HOME="/usr/local/apache-tomcat-7.0.53"' >> /etc/init.d/tomcat

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
ln -s /vagrant/tds_config_dev/catalog.xml $TDDIR/catalog.xml
ln -s /vagrant/tds_config_dev/threddsConfig.xml $TDDIR/threddsConfig.xml
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
