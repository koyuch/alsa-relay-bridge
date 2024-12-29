# Allo relay-attenuator alsa service
- mostly tested & supposed to use with raspberry pi os (11 & beyond)
- HW requirements: Allo BossDAC + Allo Relay Attenuator
- requirements: python3 (at least 3.9), Allo BossDAC set up with ALSA 
## Set-up
- append content of asound.conf to /etc/asound.conf or to ~/.asoundrc
```shell
sudo tee -a /etc/asound.conf < asound.conf
```

- create (copy) alsa-relay-volume.service to /etc/systemd/system/alsa-relay-volume.service
```shell
sudo cp alsa-relay-volume.service /etc/systemd/system/alsa-relay-volume.service
```

- copy the python script to binaries destination:
```shell
sudo cp relay_volume.py /usr/local/bin/relay-volume-daemon.py
sudo chmod +x /usr/local/bin/relay-volume-daemon.py
```

- check if dependencies are installed:
```shell
sudo apt install python3-smbus python3-alsaaudio
```

- enable service
```shell
sudo systemctl enable --now alsa-relay-volume.service
```

- check if service is running:
```shell
systemctl status alsa-relay-volume.service
```