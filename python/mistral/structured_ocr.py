# https://console.mistral.ai/api-keys/

import os
from pathlib import Path
from mistralai import Mistral
from dotenv import load_dotenv
from mistralai import DocumentURLChunk, ImageURLChunk, TextChunk
import json

# Load environment variables from .env file
load_dotenv()

# Retrieve the API key from the environment variable
api_key = os.getenv("MISTRAL_API_KEY")

# Initialize the Mistral client with the API key
client = Mistral(api_key=api_key)

print("Zigbee PDF Path: zigbee/142141_hm_rpi_pcb.pdf")
pdf_file = Path(input("Enter the path of the PDF file: "))
assert pdf_file.is_file()



uploaded_file = client.files.upload(
    file={
        "file_name": pdf_file.stem,
        "content": pdf_file.read_bytes(),
    },
    purpose="ocr",
)

signed_url = client.files.get_signed_url(file_id=uploaded_file.id, expiry=1)

# print(signed_url.url)

pdf_response = client.ocr.process(document=DocumentURLChunk(document_url=signed_url.url), model="mistral-ocr-latest", include_image_base64=True)

response_dict = json.loads(pdf_response.json())
json_string = json.dumps(response_dict, indent=4)
# print(json_string)


# *The OCR model can output interleaved text and images (set `include_image_base64=True` to return the base64 image ), we can view the result with the following:*

from mistralai.models import OCRResponse
from IPython.display import Markdown, display

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

display(Markdown(get_combined_markdown(pdf_response)))

pdf_markdown = get_combined_markdown(pdf_response)
pdf_output_path = pdf_file.with_suffix('.md')
pdf_output_path.write_text(pdf_markdown)
