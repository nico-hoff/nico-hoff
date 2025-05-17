import asyncio
import sounddevice as sd
import numpy as np
from speech.stt import SpeechToText
import logging
import traceback

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def record_audio(duration=5, sample_rate=16000):
    """Record audio for a specified duration.
    
    Args:
        duration (int): Recording duration in seconds
        sample_rate (int): Audio sample rate
        
    Returns:
        numpy.ndarray: Recorded audio data
    """
    logger.info(f"Recording for {duration} seconds...")
    frames = []
    
    try:
        with sd.InputStream(samplerate=sample_rate, channels=1, dtype='int16') as stream:
            for _ in range(0, int(sample_rate * duration / 1024)):
                audio_chunk, _ = stream.read(1024)
                frames.append(audio_chunk)
        
        audio_data = np.concatenate(frames, axis=0)
        logger.info(f"Recorded audio shape: {audio_data.shape}, dtype: {audio_data.dtype}")
        return audio_data
    except Exception as e:
        logger.error(f"Error recording audio: {str(e)}")
        logger.error(traceback.format_exc())
        raise

async def test_stt():
    """Test the speech-to-text functionality."""
    try:
        # Initialize STT
        logger.info("Initializing SpeechToText...")
        stt = SpeechToText()
        
        # Record audio
        logger.info("Please speak now...")
        audio_data = await record_audio()
        
        # Transcribe audio
        logger.info("Transcribing audio...")
        text = await stt.transcribe(audio_data)
        
        if not text:
            logger.error("No text was transcribed. This could indicate an error in the transcription process.")
            return
        
        # Print result
        print("\nTranscribed text:")
        print("-" * 50)
        print(text)
        print("-" * 50)
        
    except Exception as e:
        logger.error(f"Error in test: {str(e)}")
        logger.error(traceback.format_exc())

if __name__ == "__main__":
    asyncio.run(test_stt()) 