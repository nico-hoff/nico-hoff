# AirPlay über 3.5mm Klinke mit Shairport Sync auf dem Raspberry Pi 4

Dieses Setup ermöglicht es, **AirPlay-Audio von Apple-Geräten** (iPhone, Mac, etc.) über den **3.5mm Klinkenanschluss** eines Raspberry Pi 4 in hoher Qualität auszugeben — inklusive **Synchronisierung** und **Hardware-Lautstärkeregelung** über ALSA.

---

## 🧱 Voraussetzungen

- Raspberry Pi 4 mit Raspberry Pi OS (empfohlen: Lite oder Desktop)
- 3.5mm Klinkenausgang aktiv (kein HDMI oder USB-Audio)
- Internetverbindung für die Installation

---

## 🔧 Installation

```bash
sudo apt update
sudo apt install shairport-sync
```

Shairport Sync wird als Systemdienst installiert und läuft automatisch im Hintergrund.

---

## 🎛️ Audio-Ausgabe konfigurieren

### 1. ALSA-Ausgabegerät identifizieren

Führe aus:

```bash
aplay -L
```

Suche den passenden Eintrag für den analogen Klinkenausgang. In der Regel ist das:

```
plughw:CARD=Headphones,DEV=0
```

Der plughw-Typ ist empfohlen, da er automatische Konvertierung von Samplerate und Format ermöglicht.

### 2. Hardware-Mixer identifizieren

Führe aus:

```bash
amixer -c Headphones
```

Beispielausgabe:

```
Simple mixer control 'PCM',0
```

Der Mixer-Name ist in diesem Fall PCM.

---

## 📝 Konfigurationsdatei anpassen

Bearbeite die Datei:

```bash
sudo nano /etc/shairport-sync.conf
```

Suche den alsa-Block und ersetze ihn durch:

```
gernal = {
	name = "Pixie"
	# Other Code
}
# Other Code
alsa = {
    output_device = "plughw:CARD=Headphones,DEV=0";
    mixer_control_name = "PCM";
};
```

Speichern mit CTRL + O, schließen mit CTRL + X.

---

## 🔁 Dienst neu starten

```bash
sudo systemctl restart shairport-sync
```


---

✅ Funktionstest
	1.	Verbinde dich auf dem iPhone oder Mac per AirPlay mit dem Gerät (es heißt z. B. Shairport Sync on raspberrypi).
	2.	Spiele Musik ab.
	3.	Passe die Lautstärke auf dem Apple-Gerät an.
	4.	Prüfe mit:

```bash
amixer -c Headphones
```

… ob sich der Wert bei PCM verändert — das bestätigt die funktionierende Hardware-Lautstärkeregelung.

---

## 🔍 Weitere Optimierungen (optional - noch nicht getestet)
- Samplerate fixieren:

```
output_rate = 44100;
```

- Format erzwingen (z. B. 16-bit Little Endian):

```
output_format = "S16_LE";
```


Nur nutzen, wenn du sicher bist, dass dein Ausgabegerät das unterstützt.

---

## 🧼 Deinstallation

```bash
sudo apt remove shairport-sync
```

---

## 📚 Quellen
	•	Shairport Sync GitHub
	•	man shairport-sync
	•	aplay -L, amixer, alsamixer – zur Gerätekontrolle

⸻

## 🧠 Hinweise

	•	Shairport Sync bietet Sample-genaue Synchronisierung mit AirPlay-Clients.
	•	Die Audioqualität hängt auch stark vom verwendeten Netzteil, Kabeln und ggf. Verstärkern ab.