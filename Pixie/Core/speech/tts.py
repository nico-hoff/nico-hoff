import logging
import pyttsx3
import asyncio

logger = logging.getLogger(__name__)

class TextToSpeech:
    def __init__(self):
        """Initialize the text-to-speech engine."""
        self.engine = pyttsx3.init()
        self.engine.setProperty('rate', 150)    # Speaking rate
        self.engine.setProperty('volume', 0.9)  # Volume (0.0 to 1.0)
        
    async def speak(self, text):
        """Convert text to speech and play it.
        
        Args:
            text (str): Text to convert to speech
        """
        try:
            # Run TTS in a separate thread to avoid blocking
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, self._speak_sync, text)
        except Exception as e:
            logger.error(f"Error in text-to-speech: {str(e)}")
            
    def _speak_sync(self, text):
        """Synchronous method to speak text."""
        self.engine.say(text)
        self.engine.runAndWait() 