#!/usr/bin/env bash
apt-get update
apt-get -y install wget


# Fetch latest tds WAR
wget https://artifacts.unidata.ucar.edu/content/repositories/unidata-releases/edu/ucar/tds/4.3.21/tds-4.3.21.war
