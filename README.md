# Gree HVAC MQTT bridge

Bridge service for communicating with Gree air conditioners using MQTT broadcasts. It is a [Home Assistant App](https://developers.home-assistant.io/docs/add-ons/) and uses MQTT Discovery by default, so no manual `climate.mqtt` YAML is needed.

## Requirements

- Node.js 22 or later with npm
- An MQTT broker and Gree smart HVAC device on the same network
- Docker (for building the Home Assistant App)

## Running locally

Make sure you have Node.js 22 or later installed and run the following (adjust the arguments to match your setup):

```shell
npm install
node index.js \
    --hvac-host="192.168.1.255" \
    --mqtt-broker-url="mqtt://localhost" \
    --mqtt-topic-prefix="home/greehvac" \
    --mqtt-username="" \
    --mqtt-password="" \
    [--controllerOnly]
```
When the host is only a controller and not an air conditioner, add `controllerOnly` option. VRF is usually the case.

## Supported commands

MQTT topic scheme:

- `MQTT_TOPIC_PREFIX/COMMAND/get` Get value
- `MQTT_TOPIC_PREFIX/[SubDev MAC]/COMMAND/get` Get value (accessing sub devices)
- `MQTT_TOPIC_PREFIX/COMMAND/set` Set value
- `MQTT_TOPIC_PREFIX/[SubDev MAC]/COMMAND/set` Set value (accessing sub devices)

Note: _boolean_ values are set using 0 or 1

| Command | Values | Description |
|-|-|-|
| **temperature** | any integer |In degrees Celsius by default |
| **mode** | _off_, _auto_, _cool_, _heat_, _dry_, _fan_only_|Operation mode |
| **fanspeed** | _auto_, _low_, _mediumLow_, _medium_, _mediumHigh_, _high_ | Fan speed |
| **swinghor** | _default_, _full_, _fixedLeft_, _fixedMidLeft_, _fixedMid_, _fixedMidRight_, _fixedRight_ | Horizontal Swing |
| **swingvert** | _default_, _full_, _fixedTop_, _fixedMidTop_, _fixedMid_, _fixedMidBottom_, _fixedBottom_, _swingBottom_, _swingMidBottom_, _swingMid_, _swingMidTop_, _swingTop_ | Vetical swing |
| **power** | _0_, _1_ | Turn device on/off |
| **health** | _0_, _1_ | Health ("Cold plasma") mode, only for devices equipped with "anion generator", which absorbs dust and kills bacteria |
| **powersave** | _0_, _1_ | Power Saving mode |
| **lights** | _0_, _1_ | Turn on/off device lights |
| **quiet** | _0_, _1_, _2_, _3_ | Quiet modes |
| **blow** | _0_, _1_ | Keeps the fan running for a while after shutting down (also called "X-Fan", only usable in Dry and Cool mode) |
| **air** | _off_, _inside_, _outside_, _mode3_ | Fresh air valve |
| **sleep** | _0_, _1_ | Sleep mode |
| **turbo** | _0_, _1_ | Turbo mode |

## Home Assistant App

1. Add this repository in **Settings → Apps → App Store → ⋮ → Repositories**.
2. Install **Gree HVAC MQTT Bridge**, configure the MQTT broker and device list, then start it.
3. Ensure the MQTT integration is configured. The climate entity and selected controls are created automatically through MQTT Discovery.

The bridge publishes retained discovery configuration and retained `online`/`offline` availability. A device is therefore restored automatically after a Home Assistant or broker restart. No `configuration.yaml` edits are required.

`mqtt.discovery_prefix` defaults to `homeassistant`; change it only when Home Assistant's MQTT discovery prefix has been changed. `zigbee2mqtt_sensor_topic` is optional. When omitted, the climate entity uses the Gree unit's own reported current temperature.

### Running addon locally

Create an `./data/options.json` file inside the repo with persistent addon configuration.

```shell
docker build \
    --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base:latest" \
    -t gree-hvac-mqtt-bridge .

docker run --rm -v "$PWD/data":/data gree-hvac-mqtt-bridge
```

### Run single device as a service

To run it when the PC starts, a systemd service has to be created by following the following commands.

```shell
sudo cp /opt/gree-hvac-mqtt-bridge/gree-bridge.service /etc/systemd/system/gree-bridge.service
sudo chmod +x /etc/systemd/system/gree-bridge.service
sudo systemctl enable gree-bridge
sudo systemctl start gree-bridge
```

### Multiple devices

The App supports multiple devices by supervising one bridge process per configured device. Each device must use a distinct MQTT topic prefix.

config example:

```json
{
    "mqtt": {
        "broker_url": "mqtt://localhost",
        "username": "user",
        "password": "pass",
        "retain": false
    },
    "devices": [
      {
        "hvac_host": "192.168.0.255",
        "mqtt_topic_prefix": "/home/hvac01"
      },
      {
        "hvac_host": "192.168.0.254",
        "mqtt_topic_prefix": "/home/hvac02"
      }
    ]
}
```

## Configuring HVAC WiFi

1. Make sure your HVAC is running in AP mode. You can reset the WiFi config by pressing MODE +WIFI (or MODE + TURBO) on the AC remote for 5s.
2. Connect with the AP wifi network (the SSID name should be a 8-character alfanumeric, e.g. "u34k5l166").
3. Run the following in your UNIX terminal:

```shell
echo -n "{\"psw\": \"YOUR_WIFI_PASSWORD\",\"ssid\": \"YOUR_WIFI_SSID\",\"t\": \"wlan\"}" | nc -cu 192.168.1.1 7000
````

Note: This command may vary depending on your OS (e.g. Linux, macOS, CygWin). If facing problems, please consult the appropriate netcat manual.

## Changelog
[2.0.0]

- Migrated the add-on manifest to the current Home Assistant App format.
- Added multi-architecture build metadata and install dependencies at image build time.
- Replaced PM2 with App-supervised bridge processes.
- Added retained MQTT Discovery configuration and availability reporting.

[1.2.5]

- Merged [lelemka0](https://github.com/lelemka0) changes
- NPM fixes by [vidosits](https://github.com/vidosits)

[1.2.4]

- Updated NPM dependency versions to more current (~2 years old!)
- Defined fsevents as optional for linux based platforms
- as of 4/26/2021 "found 0 vulnerabilities"
- UDP Datagram warning is fixed with later versions

[1.2.3]

- Fix run script for single device with same configuration
- Run single device as a systemd service
- Add option to MQTT for retain flag

[1.2.2]

- Fix incorrect state checks

[1.2.0]

- Add multiple device support
- Update config with supported architectures
- Fix state being published even if nothing changed

[1.1.2]

- Discovered codes added for Air and Quiet to avoid errors
- Added swingHor mode codes

[1.1.1]

- Add Turbo mode

[1.1.0]

- Add support for MQTT authentication
- BREAKING: Update MQTT mode state names to match Hass.io defaults
- Add support for new modes: Air, Power Save, Lights, Health, Quiet, Sleep, Blow
- Fix deprecated Buffer() use

[1.0.5]

- Add Hass.io API security role

[1.0.4]

- Bump NodeJS version to 8.11.2

[1.0.3]

- Fix power off command

[1.0.2]

- Bump NodeJS version to 8.9.3

[1.0.1]

- Update MQTT version
- Add UDP error handling
- Extend Readme

[1.0.0]
First release

## License

This project is licensed under the GNU GPLv3 - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

- [tomikaa87](https://github.com/tomikaa87) for reverse-engineering the Gree protocol
- [oroce](https://github.com/oroce) for inspiration
- [arthurkrupa](https://https://github.com/arthurkrupa) for the actual service
- [bkbilly](https://github.com/bkbilly) for service improvements to MQTT
- [aaronsb](https://github.com/aaronsb) for sweeping the Node floor
- [vidosits](https://github.com/vidosits) for NPM fixes
- [lelemka0](https://github.com/lelemka0) for various improvements, namely Home Assistant Discovery
