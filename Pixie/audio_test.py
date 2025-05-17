import sounddevice as sd

# Parameter
samplerate = 44100   # Üblicher Wert (Fallback auf Default wenn unbekannt)
channels = 1         # Mono (für Sprachinput)

# Einfacher Durchleitungskanal
def audio_loopback():
    with sd.Stream(samplerate=samplerate,
                   channels=channels,
                   dtype='int16',
                   latency='low',
                   blocksize=1024,
                   callback=lambda indata, outdata, frames, time, status: outdata[:] = indata)
        print("Loopback gestartet. Drücke Strg+C zum Beenden.")
        sd.sleep(10000000)  # 10.000 Sekunden (beliebig lang)

if __name__ == "__main__":
    audio_loopback()

