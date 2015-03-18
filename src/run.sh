#! /bin/bash
source ~/.bash_profile
REDIS_PID_FILE=/var/run/redis_$REDIS_PORT.pid

sudo service ssh start

if [ -f $REDIS_PID_FILE ]
then
	rm $REDIS_PID_FILE
fi

sudo service redis_$REDIS_PORT start

python coven.py start
if ([ $? -eq 0 ]); then
	echo "Coven is up and running!"
	tail -f /dev/null
else
	echo "Failed to start the coven."
fi