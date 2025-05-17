import logging
import whisperx
import numpy as np
import tempfile
import wave
import os
import traceback

logger = logging.getLogger(__name__)

class SpeechToText:
    def __init__(self, model_name="base"):
        """Initialize the speech-to-text converter.
        
        Args:
            model_name (str): Whisper model name (tiny, base, small, medium, large)
        """
        logger.info(f"Loading Whisper model: {model_name}")
        self.model = whisperx.load_model(model_name)
        logger.info("Whisper model loaded successfully")
        
    async def transcribe(self, audio_data):
        """Transcribe audio data to text.
        
        Args:
            audio_data (numpy.ndarray): Audio data as numpy array
            
        Returns:
            str: Transcribed text
        """
        try:
            logger.info(f"Audio data shape: {audio_data.shape}, dtype: {audio_data.dtype}")
            
            # Save audio data to temporary WAV file
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
                temp_path = temp_file.name
                logger.info(f"Saving audio to temporary file: {temp_path}")
                
                with wave.open(temp_path, 'wb') as wf:
                    wf.setnchannels(1)
                    wf.setsampwidth(2)  # 16-bit audio
                    wf.setframerate(16000)
                    wf.writeframes(audio_data.tobytes())
                
                logger.info("Starting transcription...")
                # Transcribe using Whisper
                result = self.model.transcribe(temp_path)
                logger.info("Transcription completed")
                
                # Clean up temporary file
                try:
                    os.unlink(temp_path)
                except Exception as e:
                    logger.warning(f"Failed to delete temporary file: {str(e)}")
                
                return result["text"].strip()
                
        except Exception as e:
            logger.error(f"Error in transcription: {str(e)}")
            logger.error(traceback.format_exc())
            return "" 