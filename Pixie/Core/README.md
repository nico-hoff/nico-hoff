# Pixie Voice Assistant

A modular voice assistant built with Python that uses local models for speech recognition, natural language processing, and text-to-speech conversion.

## Features

- Keyword spotting using Vosk
- Speech-to-text using Whisper
- Natural language processing using Ollama and LangChain
- Text-to-speech using pyttsx3
- Asynchronous processing for better performance
- Modular architecture for easy maintenance and extension

## Prerequisites

- Python 3.8 or higher
- Raspberry Pi or similar device running Ubuntu
- Microphone and speakers
- Ollama installed and running locally

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd pixie-voice-assistant
```

2. Create a virtual environment and activate it:
```bash
python -m venv venv
source venv/bin/activate
```

3. Install the required packages:
```bash
pip install -r requirements.txt
```

4. Download the Vosk model:
```bash
# Download the small English model
wget https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip
unzip vosk-model-small-en-us-0.15.zip
mv vosk-model-small-en-us-0.15 models/vosk-model
```

5. Download the Whisper model:
```bash
# The model will be downloaded automatically on first run
```

## Usage

1. Start the voice assistant:
```bash
python main.py
```

2. Say "Pixie" to activate the assistant
3. Speak your command after the activation word
4. Wait for the assistant's response

## Project Structure

```
.
├── main.py              # Main entry point
├── requirements.txt     # Python dependencies
├── speech/
│   ├── keyword_spotting.py  # Keyword detection
│   ├── stt.py          # Speech-to-text
│   └── tts.py          # Text-to-speech
└── agent/
    └── agent_runner.py # LangChain agent integration
```

## Configuration

The following components can be configured:

- Keyword in `speech/keyword_spotting.py`
- Whisper model size in `speech/stt.py`
- TTS settings in `speech/tts.py`
- Ollama model in `agent/agent_runner.py`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.