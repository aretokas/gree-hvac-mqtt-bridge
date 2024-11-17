#!/usr/bin/env bashio
set -e

CONFIG_PATH=/data/options.json

MQTT_BROKER_URL=$(jq -r ".mqtt.broker_url" $CONFIG_PATH)
MQTT_USERNAME=$(jq -r ".mqtt.username" $CONFIG_PATH)
MQTT_PASSWORD=$(jq -r ".mqtt.password" $CONFIG_PATH)
MQTT_RETAIN=$(jq -r ".mqtt.retain" $CONFIG_PATH)
if [ "$MQTT_RETAIN" = null ]; then
  MQTT_RETAIN=false
fi

npm install

INSTANCES=$(jq '.devices | length' $CONFIG_PATH)

if [ "$INSTANCES" -gt 1 ]; then
	for i in $(seq 0 $(($INSTANCES - 1))); do
		HVAC_HOST=$(jq -r ".devices[$i].hvac_host" $CONFIG_PATH);
		MQTT_TOPIC_PREFIX=$(jq -r ".devices[$i].mqtt_topic_prefix" $CONFIG_PATH);
		ZIGBEE2MQTT_SENSOR_TOPIC=$(jq -r ".devices[$i].zigbee2mqtt_sensor_topic" $CONFIG_PATH);
		AUTO_LIGHTS=$(jq -r ".devices[$i].auto_lights" $CONFIG_PATH);
		AUTO_XFAN=$(jq -r ".devices[$i].auto_xfan" $CONFIG_PATH);
		if [[ $HVAC_HOST = null ]]; then echo "[ERROR] Missing hvac_host for device $i. Skipping." && continue; fi
		echo "Running instance $i for $HVAC_HOST"
		npx pm2 start index.js --silent -m --merge-logs --name="HVAC_${i}" -- \
			--hvac-host="${HVAC_HOST}" \
			--mqtt-broker-url="${MQTT_BROKER_URL}" \
			--mqtt-topic-prefix="${MQTT_TOPIC_PREFIX}" \
			--mqtt-username="${MQTT_USERNAME}" \
			--mqtt-password="${MQTT_PASSWORD}" \
			--mqtt-retain="${MQTT_RETAIN}" \
			--auto-lights="${AUTO_LIGHTS}" \
			--auto-xfan="${AUTO_XFAN}" \
        	--homeassistant-mqtt-discovery \
            --homeassistant-mqtt-discovery-enable=sleep,turbo,powersave,lights,blow,quiet,swinghor \
			--zigbee2mqtt-sensor-topic="${ZIGBEE2MQTT_SENSOR_TOPIC}"
	done
	npx pm2 logs /HVAC_/
else
	HVAC_HOST=$(jq -r ".devices[0].hvac_host" $CONFIG_PATH);
	MQTT_TOPIC_PREFIX=$(jq -r ".devices[0].mqtt_topic_prefix" $CONFIG_PATH);
	ZIGBEE2MQTT_SENSOR_TOPIC=$(jq -r ".devices[0].zigbee2mqtt_sensor_topic" $CONFIG_PATH);
	AUTO_LIGHTS=$(jq -r ".devices[$i].auto_lights" $CONFIG_PATH);
	AUTO_XFAN=$(jq -r ".devices[$i].auto_xfan" $CONFIG_PATH);
	echo "Running single instance for $HVAC_HOST"
	/usr/bin/node index.js \
		--hvac-host="${HVAC_HOST}" \
		--mqtt-broker-url="${MQTT_BROKER_URL}" \
		--mqtt-topic-prefix="${MQTT_TOPIC_PREFIX}" \
		--mqtt-username="${MQTT_USERNAME}" \
		--mqtt-password="${MQTT_PASSWORD}" \
		--mqtt-retain="${MQTT_RETAIN}" \
		--auto-lights="${AUTO_LIGHTS}" \
		--auto-xfan="${AUTO_XFAN}" \
        --homeassistant-mqtt-discovery \
        --homeassistant-mqtt-discovery-enable=sleep,turbo,powersave,lights,blow,quiet,swinghor \
		--zigbee2mqtt-sensor-topic="${ZIGBEE2MQTT_SENSOR_TOPIC}"
fi
