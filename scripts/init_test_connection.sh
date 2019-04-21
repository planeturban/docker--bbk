#!/bin/bash
FILE="/app/bbk.log"

if [ -z $INFLUX_HOST ]
then
	export INFLUX_HOST=influxdb
fi
if [ -z $TEST_INTERVAL ]
then
	export TEST_INTERVAL=300
fi

echo Influx host:   $INFLUX_HOST
echo Test interval: $TEST_INTERVAL

UPLOAD="-1"
while true 
do 
	/usr/bin/timeout 120 /app/bbk --quiet > $FILE
	TIMESTAMP=$(date '+%s')
	UPLOAD=$(awk '{print $3}' $FILE)
	PING=$(awk '{print $1}' $FILE)
	DOWNLOAD=$(awk '{print $2}' $FILE)

	while [ "$UPLOAD" == "-1" ]
	do
		echo "Retry!" | tee -a out.log
# oh, we're banned. let's use another server..
		/usr/bin/timeout 120 /app/bbk --quiet --server=$(/app/bbk --check-servers |grep -v Network| awk '{print $3}' | shuf -n 1) > $FILE
		TIMESTAMP=$(date '+%s')
		UPLOAD=$(awk '{print $3}' $FILE)
		PING=$(awk '{print $1}' $FILE)
		DOWNLOAD=$(awk '{print $2}' $FILE)
	done
	echo "Download: $DOWNLOAD Upload: $UPLOAD Ping: $PING ms Sleep: $TEST_INTERVAL $TIMESTAMP" | tee -a out.log
	curl -s -i -XPOST http://$INFLUX_HOST:8086/write?db=bbk --data-binary "ping,host=local value=$PING" > /dev/null
	curl -s -i -XPOST http://$INFLUX_HOST:8086/write?db=bbk --data-binary "download,host=local value=$DOWNLOAD" > /dev/null
	curl -s -i -XPOST http://$INFLUX_HOST:8086/write?db=bbk --data-binary "upload,host=local value=$UPLOAD" > /dev/null
	sleep $TEST_INTERVAL

	UPLOAD="-1"
done
