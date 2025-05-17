import asyncio
import logging
from speech.keyword_spotting import KeywordSpotter
from speech.stt import SpeechToText
from speech.tts import TextToSpeech
from agent.agent_runner import AgentRunner

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class VoiceAssistant:
    def __init__(self):
        self.keyword_spotter = KeywordSpotter()
        self.stt = SpeechToText()
        self.tts = TextToSpeech()
        self.agent = AgentRunner()
        self.is_listening = False

    async def process_command(self, audio_data):
        """Process the recorded audio command."""
        try:
            # Convert speech to text
            text = await self.stt.transcribe(audio_data)
            logger.info(f"Transcribed text: {text}")

            # Get agent response
            response = await self.agent.get_response(text)
            logger.info(f"Agent response: {response}")

            # Convert response to speech
            await self.tts.speak(response)
        except Exception as e:
            logger.error(f"Error processing command: {str(e)}")

    async def run(self):
        """Main event loop for the voice assistant."""
        logger.info("Starting voice assistant...")
        
        while True:
            try:
                # Wait for keyword
                if await self.keyword_spotter.detect_keyword():
                    logger.info("Keyword detected!")
                    
                    # Record audio after keyword
                    audio_data = await self.keyword_spotter.record_after_keyword()
                    
                    # Process the command
                    await self.process_command(audio_data)
                    
            except Exception as e:
                logger.error(f"Error in main loop: {str(e)}")
                await asyncio.sleep(1)

async def main():
    assistant = VoiceAssistant()
    await assistant.run()

if __name__ == "__main__":
    asyncio.run(main()) 