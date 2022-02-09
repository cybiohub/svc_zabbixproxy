#! /bin/bash
#set -x
# ****************************************************************************
# *
# * Creation:   	(c) 2004-2022  Cybionet - Ugly Codes Division
# *
# * File:    		vx_zbxproxy.sh
# * Version:    	0.1.1d
# *
# * Comment:    	Zabbix Proxy LTS installation script under Ubuntu LTS Server.
# *
# * Creation: October 03, 2014
# * Change:   January 30, 2022
# *
# ****************************************************************************


#############################################################################################
# ## CUSTOM VARIABLES

# ## Force configuration of the script.
# ## Value: enabled (true), disabled (false).
isConfigured='false'

# ## Do you want to install the distribution Zabbix Proxy [0=Zabbix Repo (recommended), 1=Distribution Repo].
installDefault=0

# ## Zabbix Proxy version.
# ## 3.x: 3.0, 3.4 (Obsolete)
# ## 4.x: 4.0, 4.5
# ## 5.x: 5.0, 5.5
# ## 3.0, 4.0 and 5.0 are LTS version.
zbxVers='5.0'

# ## (Without the trailing slash).
scriptLocation='/opt/zabbix'


#############################################################################################
# ## VARIABLES
declare -r isConfigured
declare -ir installDefault
declare -r zbxVers
declare -r scriptLocation


# ## Distribution: ubuntu, debian, raspbian.
osDist=$(lsb_release -i | awk '{print $3}')
declare -r osDist

# ## Supported version.
# ## Ubuntu: focal, bionic, trusty.
# ## Debian: bulleye, buster, jessie, stretch.
# ## Raspbian: buster, stretch.
osVers=$(lsb_release -c | awk '{print $2}')
declare -r osVers


#############################################################################################
# ## VERIFICATION

# ## Check if the script is configured.
if [ "${isConfigured}" == 'false' ] ; then
  echo -n -e '\e[38;5;208mWARNING: Customize the settings to match your environment. Then set the "isConfigured" variable to "true".\n\e[0m'    
  exit 0
fi

# ## Check if the script are running under root user.
if [ "${EUID}" -ne 0 ]; then
  echo -n -e "\n\n\n\e[38;5;208mWARNING:This script must be run with sudo or as root.\e[0m"
  exit 0
fi

# ## Last chance - Ask before execution.
echo -n -e "\n\e[38;5;208mWARNING:\e[0m You are preparing to install the Zabbix Proxy service. Press 'y' to continue, or any other key to exit: "
read -r ANSWER
if [[ "${ANSWER}" != 'y' && "${ANSWER}" != 'Y' ]]; then
  echo 'Have a nice day!'
  exit 0
fi

# ## Don't uses distribution repo message.
if [ ${installDefault} -eq 1 ]; then
  echo -e "Do you realy want to install the distribution Zabbix Proxy (Y/N) [default=N]?"
  echo -e "If not, change \"installDefault\" parameter to '0' in this script."
  read -r INSTALL
  if [[ "${INSTALL}" != 'n' && "${INSTALL}" != 'N' ]]; then
    echo 'Good choice!'
    exit 0
  fi
fi


#############################################################################################
# ## FUNCTIONS

# ##############
# ## DEPENDANCIES

# ## Installation basic packages required for internal scripts in Zabbix.
function zxScripts {
 # ## Script: Ping
 apt-get -y install fping
 
 # ## Script: Traceroute
 apt-get -y install traceroute

 # ## Script: Detect operating system
 apt-get -y install nmap
 echo "zabbix ALL=(ALL) NOPASSWD:/usr/bin/nmap" >> /etc/sudoers.d/zabbix
}

# ## Added Zabbix repository.
function zxRepo {
 if [ ! -f '/etc/apt/sources.list.d/zabbix.list' ]; then
   echo -e "# ## Zabbix ${zbxVers} Repository" > /etc/apt/sources.list.d/zabbix.list
   echo -e "deb https://repo.zabbix.com/zabbix/${zbxVers}/${osDist,,}/ ${osVers} main contrib non-free" >> /etc/apt/sources.list.d/zabbix.list
   echo -e "deb-src https://repo.zabbix.com/zabbix/${zbxVers}/${osDist,,}/ ${osVers} main contrib non-free" >> /etc/apt/sources.list.d/zabbix.list

   apt-key adv --keyserver hkps://keyserver.ubuntu.com --recv-keys 082AB56BA14FE591
   apt-get update
 else
   echo -e 'INFO: Source file already exist!'
 fi
}


# ##############
# ## SUPPORTED AGENT

# ## SSH support for SSH Agent (--with-ssh2).
function sshAgentSupport {
 apt-get -y install openssh-server
 apt-get -y install libssh2-1-dev
 apt-get -y install libcurl4-openssl-dev
}

# ## SNMP support for SNMP Agent (--with-net-snmp).
function snmpAgentSupport {
 apt-get -y install libsnmp-base libsnmp35
 apt-get -y install snmp-mibs-downloader # ## Not supported on Debian system.
}

# ## SNMP Trap support for SNMP Trap Agent (--with-net-snmp).
function snmpTrapAgentSupport {
 apt-get -y install snmptt
}

# ## Openipmi support for IPMI Agent (--with-openipmi).
function openipmiAgentSupport {
 apt-get -y install libopenipmi0
}

# ## Java support for JMX Agent (--with-java).
function jmxAgentSupport {
 #apt-get -y install default-jdk # ## By default openjdk-11-jdk
 apt-get -y install openjdk-17-jdk # ## openjdk-8-jdk on Debian.
}

# ## ODBC support for Database Agent (--with--unixodbc).
function odbcAgentSupport {
 apt-get -y install unixodbc unixodbc-dev
 apt-get -y install libmyodbc
 apt-get -y install odbc-postgresql
 apt-get -y install tdsodbc
 apt-get -y install unixodbc-bin
}


# ##############
# ## PROXY

# ## Installing the Zabbix Proxy with SQLite3 support.
function zxProxy {
 apt-get -y install zabbix-proxy-sqlite3
 systemctl enable zabbix-proxy.service
}

function zxDatabase {
 # ## Paclkage supposed to be already installed.
 apt-get -y install sqlite3

 if [ -f '/usr/share/doc/zabbix-proxy-sqlite3/schema.sql.gz' ]; then
   zcat /usr/share/doc/zabbix-proxy-sqlite3/schema.sql.gz | sqlite3 /etc/zabbix/zabbix.db
 else
   echo -e "\n\e[31mERROR: The source file to generate the database was not found.\e[0m\n"
 fi
}

# ## Download optimal Zabbix Proxy configuration.
function zxProxyConfig {
 if [ -f '/etc/zabbix/zabbix_proxy.conf' ]; then
   mv /etc/zabbix/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf.ori
 fi

 if [ "${installDefault}" -eq 0 ]; then
   cp configs/zabbix_proxy.conf /etc/zabbix/
 else
   cp configs/zabbix_proxy_notls.conf /etc/zabbix/zabbix_proxy.conf
 fi
}

# ## Generate the shared key (64-byte PSK).
function zxProxyTls {
 if [ "${installDefault}" -eq 0 ]; then
   echo -e 'Generation Zabbix Proxy 64 bit Pre-Shared Key (PSK).'
   openssl rand -hex 64 > /etc/zabbix/zabbix_proxy.psk
 else
   echo -e 'Zabbix Proxy from Ubuntu repository do not support TLS.'
 fi
}

# ## Creation of additional directories required.
function zxDir {
 if [ ! -d "${scriptLocation}" ]; then
   mkdir -p "${scriptLocation}"/{externalscripts,alertscripts}
   chown -R zabbix:zabbix "${scriptLocation}"/
 fi

 if [ ! -d '/var/run/zabbix/' ]; then
   mkdir -p /var/run/zabbix/
   chown -R zabbix:zabbix /var/run/zabbix/
 fi

 if [ ! -d '/var/log/zabbix-proxy/' ]; then
   mkdir -p /var/log/zabbix/
   chown -R zabbix:zabbix /var/log/zabbix/
 fi
}


# ##############
# ## EXTRA

# ## Installing the Zabbix Agent.
function zxAgent {
 apt-get install -y zabbix-agent
}

# ## Installing Zabbix tools.
function zxTools {
 apt-get install -y zabbix-get
 apt-get install -y zabbix-sender
}

# ## Installation of the Java gateway.
function zxJavaGw {
 apt-get install -y zabbix-java-gateway
}


#############################################################################################
# ## EXECUTION

# ## Installation basic packages required for internal scripts in Zabbix.
zxScripts

# ## Set Zabbix repository for installation.
if [ "${installDefault}" -eq 0 ]; then
 # ## Added Zabbix repository as per setting.
 zxRepo
 zxProxy
else
 # ## Installing Zabbix Proxy.
 zxProxy
fi

# ## Generate the shared key (64 byte PSK).
zxProxyTls

# ## Copy of the ready-to-use simplified configuration file.
zxProxyConfig

# ## Creation of the necessary directories for Zabbix.
zxDir

# ## Installing of all Agent services for the Proxy.
sshAgentSupport
snmpAgentSupport
snmpTrapAgentSupport
openipmiAgentSupport
odbcAgentSupport
jmxAgentSupport

# ## Populate the database.
zxDatabase



# ## Installing Zabbix Agent.
#zxAgent

# ## Installing Java Gateway.
#zxJavaGw

# ## Installing Zabbix tools.
#zxTools


# ## Exit.
exit 0

# ## END			
