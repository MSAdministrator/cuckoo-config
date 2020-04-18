
# This shell script will walk through and configure a Cuckoo Sandbox host running Ubunutu Server 18.04 LTS

CUCKOO_HOST_IP = '10.32.x.x'
VSPHERE_IP = '10.32.10.x'
VSPHERE_USERNAME = 'vsphere_username'
VSPHERE_PASS = 'vsphere_pass'
CUCKOO_GUEST_NAME = 'cuckoo-win7-guest'
CUCKOO_HOST_NET_ADAPTER = ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}'
CUCKOO_GUEST_LABEL = 'INTERNAL-Cuckoo-Win7-Guest'
CUCKOO_GUEST_SNAPSHOT = 'cuckoo-win7-guest-15JAN2019'
CUCKOO_GUEST_IP = '10.32.10.x'
CUCKOO_GUEST_OS_PROFILE = 'Win7SP1x64'

CUCKOO_CONFIGURATION = './host/conf/cuckoo.conf'
PROCESSING_CONFIGURATION = './host/conf/processing.conf'
VSPHERE_CONFIGURATION = './host/conf/vsphere.conf'
MEMORY_CONFIGURATION = './host/conf/memory.conf'
REPORTING_CONFIGURATION = './host/conf/reporting.conf'



PACKAGE_LIST = "python2.7 python-pip python-dev libffi-dev libssl-dev python-virtualenv python-setuptools libjpeg-dev zlib1g-dev swig mongodb postgresql libpq-dev ssdeep libfuzzy-dev build-essential git libcap2-bin swig volatility libtool automake tcpdump apparmor-utils libjansson-dev libmagic-dev python-m2crypto"

sudo apt-get install $PACKAGE_LIST -y

pip install ssdeep
sudo ldconfig

echo "Creating download directory"
mkdir Downloads && cd Downloads

# Installing pydeep
git clone https://github.com/kbandla/pydeep.git
cd pydeep
sudo python2 setup.py install
cd ..

#installing yara
wget https://github.com/VirusTotal/yara/archive/v3.8.1.tar.gz
tar -xvzf v3.8.1.tar.gz
cd yara-3.8.1/
./bootstrap.sh
./configure --enable-cuckoo --enable-magic --enable-dotnet
make
sudo make install
cd ~
pip install yara-python

#Configuring tcpdump
sudo aa-disable /usr/sbin/tcpdump
sudo groupadd pcap
sudo usermod -a -G pcap cuckoo
sudo chgrp pcap /usr/sbin/tcpdump
sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

#Installing Guacd
sudo apt install libguac-client-rdp0 libguac-client-vnc0 libguac-client-ssh0 guacd -y


echo "Installing Cuckoo into virtualenv"
virtualenv cuckoo-env
. cuckoo-env/bin/activate
pip2 install -U pip setuptools
pip2 install -U cuckoo


cuckoo_config()
{
    CONF_PATH = '/home/cuckoo/.cuckoo/conf/cuckoo.conf'

    sudo sed -i 's/delete_original = no/delete_original = yes/' $CONF_PATH
    sudo sed -i 's/delete_bin_copy = no/delete_bin_copy = yes/' $CONF_PATH
    sudo sed -i 's/machinery = virtualbox/machinery = vsphere/' $CONF_PATH
    sudo sed -i 's/processing_results = yes/processing_results = no/' $CONF_PATH
    sudo sed -i 's/memory_dump = no/memory_dump = yes/' $CONF_PATH
    sudo sed -i 's/max_machines_count = 0/max_machines_count = 2/' $CONF_PATH
    sudo sed -i 's/max_vmstartup_count = 10/max_vmstartup_count = 2/' $CONF_PATH
    sudo sed -i "s/ip = /ip = $CUCKOO_HOST_IP/" $CONF_PATH
}

cuckoo_config

vsphere_config()
{
    CONF_PATH = '/home/cuckoo/.cuckoo/conf/vsphere.conf'

    sudo sed -i "s/host = 10.0.0.1/host = $VSPHERE_IP/" $CONF_PATH
    sudo sed -i "s/username_goes_here/$VSPHERE_USERNAME/" $CONF_PATH
    sudo sed -i "s/password_goes_here/$VSPHERE_PASS/" $CONF_PATH
    sudo sed -i "s/analysis1/$CUCKOO_GUEST_NAME/" $CONF_PATH
    sudo sed -i "s/eth0/$CUCKOO_HOST_NET_ADAPTER/" $CONF_PATH
    sudo sed -i 's/unverified_ssl = no/unverified_ssl = yes/' $CONF_PATH
    sudo sed -i "s/ip = /ip = $CUCKOO_HOST_IP/" $CONF_PATH
    sudo sed -i "s/label = cuckoo1/label = $CUCKOO_GUEST_LABEL/" $CONF_PATH
    sudo sed -i "s/snapshot_name/$CUCKOO_GUEST_SNAPSHOT/" $CONF_PATH
    sudo sed -i "s/192.168.1.100/$CUCKOO_GUEST_IP/" $CONF_PATH
    sudo sed -i "s/osprofile = /osprofile = $CUCKOO_GUEST_OS_PROFILE/" $CONF_PATH
}

vsphere_config

memory_config()
{
    CONF_PATH='/home/cuckoo/.cuckoo/conf/memory.conf'

    sudo sed -i "s/WinXPSP2x86/$CUCKOO_GUEST_OS_PROFILE/" $CONF_PATH
    sudo sed -i "s/delete_memdump = no/delete_memdump = yes/" $CONF_PATH
}

memory_config

processing_config()
{
    CONF_PATH='/home/cuckoo/.cuckoo/conf/processing.conf'

    cp -f $CONF_PATH $PROCESSING_CONFIGURATION
}

processing_config


reporting_config()
{
    CONF_PATH='/home/cuckoo/.cuckoo/conf/reporting.conf'
    cp -f $CONF_PATH $REPORTING_CONFIGURATION
}

reporting_config

echo "Setting up networking"

cp -f '/etc/netplan/50-cloud-init.yml' './host/etc/netplan/50-cloud-init.yml'

sudo netplan apply

echo "installing PyVmomi"
pip2 install -U pyvmomi

echo "Downloading Community Content"
cuckoo community

echo "Running cuckoo manually"
cuckoo

echo "Installing Supervisor"
pip2 install supervisor

echo "starting supervisor"
supervisord -c ~/.cuckoo/supervisord.conf
cd ~/.cuckoo/
supervisorctl start cuckoo:

echo "Setting up robust webserver"
sudo apt-get install uwsgi uwsgi-plugin-python nginx -y

echo "Setting uwsgi configuration"
sudo touch /etc/uwsgi/apps-available/cuckoo-web.ini
cuckoo web --uwsgi | sudo tee /etc/uwsgi/apps-available/cuckoo-web.ini 

sudo ln -s /etc/uwsgi/apps-available/cuckoo-web.ini /etc/uwsgi/apps-enabled/

echo "Setting up nginx"
sudo touch /etc/nginx/sites-available/cuckoo-web
cuckoo web --nginx | sudo tee /etc/nginx/sites-available/cuckoo-web 

sudo adduser www-data cuckoo

sudo ln -s /etc/nginx/sites-available/cuckoo-web /etc/nginx/sites-enabled/
sudo service nginx start

echo "Setting up API"
sudo touch /etc/uwsgi/apps-available/cuckoo-api.ini
cuckoo api --uwsgi | sudo tee /etc/uwsgi/apps-available/cuckoo-api.ini

sudo ln -s /etc/uwsgi/apps-available/cuckoo-api.ini /etc/uwsgi/apps-enabled/
sudo service uwsgi start cuckoo-api

echo "Setting up nginx for API"
sudo touch /etc/nginx/sites-available/cuckoo-api
cuckoo api --nginx | sudo tee /etc/nginx/sites-available/cuckoo-api

sudo adduser www-data cuckoo

sudo ln -s /etc/nginx/sites-available/cuckoo-api /etc/nginx/sites-enabled/
sudo service nginx start

echo "Finally running Cuckoo Sandbox"
cd ~/.cuckoo 
cuckoo