import asyncio
import logging
import sounddevice as sd
import numpy as np
from vosk import Model, KaldiRecognizer
import wave
import json

logger = logging.getLogger(__name__)

class KeywordSpotter:
    def __init__(self, keyword="pixie", sample_rate=16000):
        """Initialize the keyword spotter.
        
        Args:
            keyword (str): The keyword to detect
            sample_rate (int): Audio sample rate
        """
        self.keyword = keyword.lower()
        self.sample_rate = sample_rate
        self.model = Model(lang="en-us")  # You'll need to download the model
        self.recognizer = KaldiRecognizer(self.model, sample_rate)
        self.recognizer.SetWords(True)
        
    async def detect_keyword(self):
        """Continuously listen for the keyword."""
        try:
            # Record audio in chunks
            with sd.InputStream(samplerate=self.sample_rate, channels=1, dtype='int16') as stream:
                while True:
                    audio_chunk, _ = stream.read(1024)
                    if self.recognizer.AcceptWaveform(audio_chunk.tobytes()):
                        result = json.loads(self.recognizer.Result())
                        if result.get("text", "").lower() == self.keyword:
                            return True
                    await asyncio.sleep(0.1)
        except Exception as e:
            logger.error(f"Error in keyword detection: {str(e)}")
            return False

    async def record_after_keyword(self, duration=5):
        """Record audio after keyword detection.
        
        Args:
            duration (int): Recording duration in seconds
        """
        try:
            frames = []
            with sd.InputStream(samplerate=self.sample_rate, channels=1, dtype='int16') as stream:
                for _ in range(0, int(self.sample_rate * duration / 1024)):
                    audio_chunk, _ = stream.read(1024)
                    frames.append(audio_chunk)
            
            return np.concatenate(frames, axis=0)
        except Exception as e:
            logger.error(f"Error recording audio: {str(e)}")
            return None 