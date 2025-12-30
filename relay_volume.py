#!/usr/bin/python3
import smbus
import alsaaudio
import time
import argparse

RELAY_ADDR = 0x21
MIN_VOL = 0x00
MAX_VOL = 0x3f
AUDIO_CARD = 'BossDAC'
DEFAULT_INPUT_CONTROL = 'Master'
DEFAULT_OUTPUT_CONTROL = 'Digital'


class RelayVolume:
    def __init__(self, input_control=None, output_control=None):
        self.bus = smbus.SMBus(1)
        self.input_control = input_control or DEFAULT_INPUT_CONTROL
        self.output_control = output_control or DEFAULT_OUTPUT_CONTROL
        
        try:
            # Get card index for BossDAC
            cards = alsaaudio.cards()
            card_index = cards.index(AUDIO_CARD)

            # Input mixer: Master softvol control (user-adjustable)
            self.input_mixer = alsaaudio.Mixer(
                control=self.input_control,
                cardindex=card_index
            )
            print(f"Input control: {self.input_control} "
                  f"on card {card_index}")
            
            # Output mixer: Digital control (kept at 100%)
            self.output_mixer = alsaaudio.Mixer(
                control=self.output_control,
                cardindex=card_index
            )
            self.output_mixer.setvolume(100)
            print(f"Output control: {self.output_control} set to 100%")
            
        except Exception as e:
            print(f"Mixer initialization error: {e}")
            print(f"Available cards: {alsaaudio.cards()}")
            try:
                # List available controls for debugging
                print(f"Available controls on {AUDIO_CARD}:")
                for ctrl in alsaaudio.mixers(cardindex=card_index):
                    print(f"  - {ctrl}")
            except Exception:
                pass
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
        print("Starting volume monitoring loop...")

        while True:
            try:
                # Monitor input control (Master) for user volume changes
                self.input_mixer.handleevents()
                current_volume = self.input_mixer.getvolume()[0]
                
                # Ensure output control (Digital) stays at 100%
                output_volume = self.output_mixer.getvolume()[0]
                if output_volume != 100:
                    print(f"Output volume changed to {output_volume}%, "
                          f"resetting to 100%")
                    self.output_mixer.setvolume(100)
                
                try:
                    current_mute = bool(self.input_mixer.getmute()[0])
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
    parser = argparse.ArgumentParser(
        description='ALSA Relay Volume Bridge - monitors Master control '
                    'and sends changes to relay attenuator'
    )
    parser.add_argument(
        '--input-control', '-i',
        default=DEFAULT_INPUT_CONTROL,
        help=f'Input control for relay '
             f'(default: {DEFAULT_INPUT_CONTROL})'
    )
    parser.add_argument(
        '--output-control', '-o',
        default=DEFAULT_OUTPUT_CONTROL,
        help=f'Output control kept at 100%% '
             f'(default: {DEFAULT_OUTPUT_CONTROL})'
    )
    args = parser.parse_args()
    
    print("=" * 60)
    print("ALSA Relay Volume Bridge")
    print(f"Input (variable): {args.input_control}")
    print(f"Output (100%%): {args.output_control}")
    print("=" * 60)
    RelayVolume(
        input_control=args.input_control,
        output_control=args.output_control
    ).run()
