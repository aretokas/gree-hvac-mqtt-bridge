#!/usr/bin/with-contenv bashio
set -e

MQTT_BROKER_URL=$(bashio::config 'mqtt.broker_url')
MQTT_USERNAME=$(bashio::config 'mqtt.username')
MQTT_PASSWORD=$(bashio::config 'mqtt.password')
MQTT_RETAIN=$(bashio::config 'mqtt.retain')
DISCOVERY_PREFIX=$(bashio::config 'mqtt.discovery_prefix')
DEBUG=$(bashio::config 'mqtt.debug')

declare -a PIDS=()

stop_children() {
  for pid in "${PIDS[@]}"; do kill "$pid" 2>/dev/null || true; done
  wait || true
}
trap stop_children EXIT INT TERM

INSTANCE_COUNT=$(bashio::config 'devices' | jq --raw-output 'length')
for i in $(seq 0 "$((INSTANCE_COUNT - 1))"); do
  HVAC_HOST=$(bashio::config "devices[$i].hvac_host")
  MQTT_TOPIC_PREFIX=$(bashio::config "devices[$i].mqtt_topic_prefix")
  ZIGBEE2MQTT_SENSOR_TOPIC=$(bashio::config "devices[$i].zigbee2mqtt_sensor_topic")
  AUTO_LIGHTS=$(bashio::config "devices[$i].auto_lights")
  AUTO_XFAN=$(bashio::config "devices[$i].auto_xfan")
  [[ "$ZIGBEE2MQTT_SENSOR_TOPIC" == "null" ]] && ZIGBEE2MQTT_SENSOR_TOPIC=''

  bashio::log.info "Starting bridge instance $i for $HVAC_HOST"
  node index.js \
    --hvac-host="$HVAC_HOST" \
    --mqtt-broker-url="$MQTT_BROKER_URL" \
    --mqtt-topic-prefix="$MQTT_TOPIC_PREFIX" \
    --mqtt-username="$MQTT_USERNAME" \
    --mqtt-password="$MQTT_PASSWORD" \
    --mqtt-retain="$MQTT_RETAIN" \
    --auto-lights="$AUTO_LIGHTS" \
    --auto-xfan="$AUTO_XFAN" \
    --homeassistant-mqtt-discovery \
    --homeassistant-discovery-prefix="$DISCOVERY_PREFIX" \
    --debug="$DEBUG" \
    --homeassistant-mqtt-discovery-enable=sleep,turbo,powersave,lights,blow,quiet,swinghor \
    --zigbee2mqtt-sensor-topic="$ZIGBEE2MQTT_SENSOR_TOPIC" &
  PIDS+=("$!")
done

wait -n "${PIDS[@]}"
