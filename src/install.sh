#! /bin/bash

source ~/.bash_profile
cd ~/Coven/lib

# INSTALL REDIS
wget http://download.redis.io/redis-stable.tar.gz
tar -xvzf redis-stable.tar.gz
rm redis-stable.tar.gz

cd redis-stable
make
sudo cp src/redis-server /usr/local/bin
sudo cp src/redis-cli /usr/local/bin
sudo mkdir /etc/redis
sudo mkdir -p /var/redis/$REDIS_PORT
sudo cp utils/redis_init_script /etc/init.d/redis_$REDIS_PORT

# BUILD AND INSTALL PYTHON-NBXMPP
cd ../
hg clone https://hg.gajim.org/python-nbxmpp --insecure
cd python-nbxmpp
sudo python setup.py install

# INSTALL PYTHON-OTR
cd ../python-otr
sudo python setup.py install

cd ~/Coven

# INSTALL DEPENDENCIES
sudo pip install -r requirements.txt

# CONFIGURE
mkdir .otr
mkdir .monitor
python setup.py

DID_SETUP=$?
if ([ $DID_SETUP -eq 0 ])
then
	sudo mv lib/redis-stable/$REDIS_PORT.conf /etc/redis
	sudo update-rc.d redis_$REDIS_PORT defaults
else
	echo "FAILED SETUP"
fi