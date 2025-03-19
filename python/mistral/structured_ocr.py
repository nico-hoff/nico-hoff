# https://console.mistral.ai/api-keys/

import os
from pathlib import Path
from mistralai import Mistral
from dotenv import load_dotenv
from mistralai import DocumentURLChunk, ImageURLChunk, TextChunk
import json
import sys
from mistralai.models import OCRResponse
import httpx

# Maximum file size (100MB)
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB in bytes

# Load environment variables from .env file
load_dotenv()

# Retrieve the API key from the environment variable
api_key = os.getenv("MISTRAL_API_KEY")
if not api_key:
    print("Error: MISTRAL_API_KEY not found in environment variables")
    sys.exit(1)

# Initialize the Mistral client with the API key and custom timeout
client = Mistral(
    api_key=api_key,
    timeout_ms=300000,  # 5 minutes timeout (300000 milliseconds)
)

def check_file_size(file_path: Path) -> bool:
    size = file_path.stat().st_size
    if size > MAX_FILE_SIZE:
        print(f"Error: File size ({size/1024/1024:.2f}MB) exceeds maximum allowed size (100MB)")
        return False
    return True

def upload_file_with_retry(file_path: Path, max_retries: int = 3) -> any:
    for attempt in range(max_retries):
        try:
            return client.files.upload(
                file={
                    "file_name": file_path.stem,
                    "content": file_path.read_bytes(),
                },
                purpose="ocr",
            )
        except (httpx.RemoteProtocolError, httpx.ReadTimeout) as e:
            if attempt == max_retries - 1:
                print(f"Error: Failed to upload file after {max_retries} attempts: {str(e)}")
                raise
            print(f"Attempt {attempt + 1} failed, retrying...")
            continue

def process_pdf(file_path: Path) -> None:
    try:
        if not check_file_size(file_path):
            return

        print(f"Uploading file: {file_path.name}")
        uploaded_file = upload_file_with_retry(file_path)
        
        print("Getting signed URL...")
        signed_url = client.files.get_signed_url(file_id=uploaded_file.id, expiry=1)

        print("Processing OCR...")
        pdf_response = client.ocr.process(
            document=DocumentURLChunk(document_url=signed_url.url),
            model="mistral-ocr-latest",
            include_image_base64=True
        )

        # Convert response to markdown and save in the same folder as input
        pdf_markdown = get_combined_markdown(pdf_response)
        output_path = file_path.with_suffix('.md')
        output_path.write_text(pdf_markdown)
        print(f"Successfully saved markdown to: {output_path}")

    except Exception as e:
        print(f"Error processing PDF: {str(e)}")
        raise

def replace_images_in_markdown(markdown_str: str, images_dict: dict) -> str:
    for img_name, base64_str in images_dict.items():
        markdown_str = markdown_str.replace(f"![{img_name}]({img_name})", f"![{img_name}]({base64_str})")
    return markdown_str

def get_combined_markdown(ocr_response: OCRResponse) -> str:
    markdowns: list[str] = []
    for page in ocr_response.pages:
        image_data = {}
        for img in page.images:
            image_data[img.id] = img.image_base64
        markdowns.append(replace_images_in_markdown(page.markdown, image_data))

    return "\n\n".join(markdowns)

if __name__ == "__main__":
    pdf_file = Path(input("Enter the path of the PDF file: "))
    
    if not pdf_file.is_file():
        print(f"Error: File not found: {pdf_file}")
        sys.exit(1)
        
    process_pdf(pdf_file)
