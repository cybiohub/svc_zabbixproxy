![alt text][logo]

# Cybionet - Ugly Codes Division

## SUMMARY

Easy installation script of Zabbix Proxy service with SQLite3.

You can choose between different options, such as:
- the Zabbix Proxy version supported by your distribution.
- the source repository of the package (Zabbix or the distribution).

Works on Ubuntu, Debian and Rasbpian.


## REQUIRED

The `vx_zbxproxy.sh` application does not require any additional packages to work.


## INSTALLATION

1. Download files from this repository directly with git or via https.
	```bash
	wget -o svc_zabbixproxy.zip https://github.com/cybiohub/svc_zabbixproxy/archive/refs/heads/main.zip
	```

2. Unzip the zip file.
	```bash
	unzip svc_zabbixproxy.zip
	```

3. Make changes to the installation script to configure it to match your environment.
	
	You can customize the following settings: 

	- Choose between Zabbix repository version or distribution version. By default, this is the Zabbix repository version.
	- The version of Zabbix Proxy you want to install.
	- Directory location for additional scripts. By default in `/opt/zabbix`.

4. Once completed, set the `Configured` parameter to `true`.

5. Adjust permissions.
	```bash
	chmod 500 vx_zbxproxy.sh
	```

6. Run the script.
	```bash
	./vx_zbxproxy.sh
	```

7. Configure Zabbix Proxy service.
	```bash
	vim /etc/zabbix/zabbix_proxy.conf
	```
	```
	# TLS PSK Identity for your Zabbix Proxy.
	TLSPSKIdentity=YOURZABBIXPROXY
	
	# IP address of the Zabbix server.
	Server=W.X.Y.Z
	
	# Name identifying the Zabbix Proxy to the Zabbix server.
	Hostname=YOURZABBIXPROXY
	```

8. Activate and start the service.
	```bash
	systemctl enable zabbix-proxy
	systemctl start zabbix-proxy
	systemctl status zabbix-proxy
	```
9. Voilà! Enjoy!
---
[logo]: ./md/logo.png "Cybionet"



