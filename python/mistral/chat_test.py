from mistralai import Mistral
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Retrieve the API key from the environment variable
api_key = os.getenv("MISTRAL_API_KEY")

# Initialize the Mistral client with the API key
client = Mistral(api_key=api_key)

model = "mistral-large-latest"

input = input("\nWhat's up?\n")
print("\n")

chat_response = client.chat.complete(
    model= model,
    messages = [
        {
            "role": "user",
            "content": input,
        },
    ]
)
print(chat_response.choices[0].message.content)