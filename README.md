# cuckoo-config

This repository contains documentation and configuration settings for Cuckoo Sandbox environment

## Current

This repository contains information related to setting up cuckoo in a ESXi/vSphere environment.

## Shell Script

I have provided a shell script but it has been awhile since I have ran this so you may run into issues.  Please try to troubleshoot any issues on your own and if you are still running into issues please open an issue in this repository.

> You will need to modify this script first with variables at the top of the script.

You can find this script [here](cuckoo_setup.sh). 

### Host

It is expected that you have a Ubuntu host (Ubunutu 18.04.1 LTS) running in your ESXi environment.  You will need the following information:

IP: (static)
Login: `username`
Pass:  `password`

#### Cuckoo Configuration Files

You can find the following configuration files in this repository.  These are setup to work with a single Windows 7 Guest VM on ESXi.

These files are currently located in the ~/.cuckoo/conf/ folder on the Cuckoo Host VM:

* [cuckoo.conf](host/conf/cuckoo.conf)
* [memory.conf](host/conf/memory.conf)
* [reporting.conf](host/conf/reporting.conf)
* [processing.conf](host/conf/processing.conf)
* [vsphere.conf](host/conf/vsphere.conf)
* [auxiliary.conf](host/conf/auxiliary.conf)

Additonally, I have included the `.vmx` file that is saved in ESXi for the Windows 7 Guest VM.  

**NOTE** This needs to be added to the host machine if you make changes to the Guest VM.  You can access this by logging into vSphere and going to the folder that holds the Virtual Machine
via the UI DataStore

* [cuckoo-win7-guest.vmx](host/cuckoo-win7-guest/cuckoo-win7-guest.vmx)

Lastly, we had to make a slight change to the our `supervisord.conf` file.  Change the host to include this file, then you can run the following to start all services at once:

```shell
sudo supervisord -c supervisord.conf
supervisorctl start cuckoo:
```

The Cuckoo Sandbox host is running in a virtual environment as per cuckoo's recommendation.  The following was installed and ran to setup the virtual environment:

```shell
sudo pip install -U pip setuptools
sudo pip install -U cuckoo
sudo pip2 install supervisor
```

Although the above, a global installation of Cuckoo in your OS works mostly fine, I highly recommend installing Cuckoo in a virtualenv, which looks roughly as follows:

```
virtualenv venv
. venv/bin/activate
(venv)$ pip install -U pip setuptools
(venv)$ pip install -U cuckoo
```

#### Cuckoo

##### Networking

[Netplan Configuration File](host/etc/netplan/50-cloud-init.yaml)

The cuckoo host is currently configured with a static IP address which you can find in the above file. Please modify this file with your static IP address.

##### Packages

```bash
sudo apt-get install python python-pip python-dev libffi-dev libssl-dev
sudo apt-get install python-virtualenv python-setuptools
sudo apt-get install libjpeg-dev zlib1g-dev swig
sudo apt-get install mongodb
sudo apt-get install postgresql libpq-dev
```

TCPDump

```bash
sudo apt-get install tcpdump apparmor-utils
sudo aa-disable /usr/sbin/tcpdump

# Tcpdump requires root privileges, but since you don’t want Cuckoo to run as root you’ll have to set specific Linux capabilities to the binary:
sudo groupadd pcap
sudo usermod -a -G pcap cuckoo
sudo chgrp pcap /usr/sbin/tcpdump
sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

#You can verify the results of the last command with:
getcap /usr/sbin/tcpdump
# /usr/sbin/tcpdump = cap_net_admin,cap_net_raw+eip
```

Volatility
```bash

```

M2Crypto
```bash
sudo apt-get install swig
sudo pip install m2crypto==0.24.0
```

Remote Control Support
```bash
sudo apt install libguac-client-rdp0 libguac-client-vnc0 libguac-client-ssh0 guacd
```

