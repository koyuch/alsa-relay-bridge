#!/usr/bin/python3
import smbus
import alsaaudio
import time

RELAY_ADDR = 0x21
MIN_VOL = 0x00
MAX_VOL = 0x3f
AUDIO_CARD = 'BossDAC'
AUDIO_CONTROL = 'Master'

class RelayVolume:
    def __init__(self):
        self.bus = smbus.SMBus(1)
        try:
            # Get card index for BossDAC
            cards = alsaaudio.cards()
            card_index = cards.index(AUDIO_CARD)

            # Use 'Master' mixer which was added to BossDAC
            self.mixer = alsaaudio.Mixer(control=AUDIO_CONTROL, cardindex=card_index)
            print(f"Successfully initialized mixer: Master on card {card_index}")
        except Exception as e:
            print(f"Mixer initialization error: {e}")
            raise Exception("Could not initialize audio mixer")

        self.vol = None
        self.mute = None

    def write_relay(self, value: int):
        try:
            # Bug fix from original code: write 0x3f first to avoid noise
            self.bus.write_byte(RELAY_ADDR, 0x3f)
            time.sleep(0.0006)  # 600 microseconds

            # Calculate value exactly as in C code
            relay_value = (~value & 0x3f) | 0x40
            print(f"Writing to relay converted: 0x{value:02x} ({value}) -> 0x{relay_value:02x} ({relay_value})")
            self.bus.write_byte(RELAY_ADDR, relay_value)

        except Exception as e:
            print(f"Error writing to relay: {e}")

    def set_volume(self, volume_percent: int):
        old_vol = self.vol
        # Convert ALSA volume (0-100) to RelayAttenuator steps (0x00-0x3f)
        self.vol = int((volume_percent * MAX_VOL) / 100)
        self.vol = min(MAX_VOL, max(MIN_VOL, self.vol))
        print(f"Volume change: {volume_percent}% -> {self.vol} (was: {old_vol})")
        if self.vol != old_vol:
            self.write_relay(self.vol)
        self.mute = False

    def set_mute(self, mute: bool):
        self.mute = bool(mute)
        self.write_relay(MIN_VOL if self.mute else self.vol)


    def run(self):
        last_volume = None
        last_mute = None

        while True:
            try:
                # Force a refresh of the ALSA mixer values
                self.mixer.handleevents()
                current_volume = self.mixer.getvolume()[0]
                try:
                    current_mute = bool(self.mixer.getmute()[0])
                except alsaaudio.ALSAAudioError:
                    current_mute = False

                if current_mute != last_mute:
                    self.set_mute(current_mute)
                    last_mute = current_mute
                if current_volume != last_volume and not current_mute:
                    self.set_volume(current_volume)
                    last_volume = current_volume

                time.sleep(0.1)
            except Exception as e:
                print(f"Error: {e}")
                time.sleep(1)

if __name__ == "__main__":
    RelayVolume().run()
