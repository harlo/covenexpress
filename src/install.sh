#! /bin/bash

function parse_directive {
	echo $(echo $1 | python -c "import re, sys; r = sys.stdin.read().split(\";\"); rx = re.compile(r[0]); print \"\".join(re.findall(rx, r[1]))")
}

function resolve_git {
	file $1/.git | grep "directory"
	if ([ $? -eq 0 ]); then
		return
	fi

	cd $1 && pwd
	rm .git
	git init

	git remote add origin $2

	cat >> $1/.git/config <<'_EOF'
[branch "master"]
	remote = origin
	merge = refs/head/master
_EOF

	file $1/.gitmodules
	if ([ $? -eq 0 ]); then
		SUBMODULES=$(cat $1/.gitmodules | grep "submodule" -A 2)

		IFS=$'\n'
		PATH_RX='\tpath\s=\s(.*)'
		URL_RX='\turl\s=\s(.*)'
		U_PATH=""
		S_PATH=""

		for SUBMODULE in $SUBMODULES; do
			if [[ -z "$S_PATH" ]]; then
				echo $SUBMODULE | grep -Po $PATH_RX
				if ([ $? -eq 0 ]); then
					S_PATH=$(parse_directive "$PATH_RX;$SUBMODULE")
				fi
			fi

			if [[ -z "$U_PATH" ]]; then
				echo $SUBMODULE | grep -Po $URL_RX
				if ([ $? -eq 0 ]); then
					U_PATH=$(parse_directive "$URL_RX;$SUBMODULE")
				fi
			fi

			if [[ -z "$U_PATH" ]] || [[ -z "$S_PATH" ]]; then
				continue
			else
				resolve_git $1/$S_PATH $U_PATH
				U_PATH=""
				S_PATH=""
			fi
		done
	fi
}

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

# RESOLVE GIT
git config --global user.name "$(whoami)"
git config --global user.email "coven@deeplab.net"

resolve_git ~/Coven "git@github.com:harlo/coven.git"

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