#!/usr/bin/env python3
# main.py — Pixie Agent (STT → LLM → TTS / Tool-Loop)

import requests
import json
import sys
import subprocess
from typing import Dict

OLLAMA_API = "http://localhost:11434/api/chat"
SYSTEM_PROMPT = """
You are Pixie, a local offline AI voice agent. 
You understand user requests in natural language and decide whether to call a tool or respond directly.
Always output a single JSON object with exactly one of the following:
1) {"action":"respond","response":"<your answer>"}
2) {"action":"use_tool","tool_name":"<tool>","parameters":{...}}
If ambiguous, ask for clarification using {"action":"respond",...}.
"""

# === Tool-Stubs ===

def play_spotify(params: Dict[str, str]) -> str:
    # Hier würdest du Spotify-API-Aufrufe integrieren
    song = params.get("song_name")
    artist = params.get("artist", "")
    return f"Playing '{song}' by '{artist}' on Spotify (stubbed)."

def toggle_light(params: Dict[str, str]) -> str:
    # Hier würdest du Zigbee2MQTT o.Ä. ansprechen
    device = params.get("device_name")
    state = params.get("state")
    return f"Set light '{device}' to state '{state}' (stubbed)."

def query_weather(params: Dict[str, str]) -> str:
    # Hier würdest du eine lokale Wetter-API oder Dienst ansprechen
    loc = params.get("location")
    return f"Current weather at '{loc}': 20°C, leicht bewölkt (stubbed)."

TOOLS = {
    "play_spotify": play_spotify,
    "toggle_light": toggle_light,
    "query_weather": query_weather,
}

# === LLM-Call ===

def ask_llm(messages: list) -> str:
    payload = {
        "model": "llama3",
        "messages": messages,
        "stream": False,
        "temperature": 0.2,
        "top_p": 0.8,
        "max_tokens": 512
    }
    resp = requests.post(OLLAMA_API, json=payload)
    resp.raise_for_status()
    data = resp.json()
    # LLM liefert hier: data["message"]["content"]
    return data["message"]["content"]

# === Agent-Loop ===

def agent_loop():
    # Initial System-Prompt
    messages = [{"role": "system", "content": SYSTEM_PROMPT.strip()}]

    while True:
        try:
            user_input = input("\nYou: ").strip()
            if not user_input:
                continue
            messages.append({"role": "user", "content": user_input})

            llm_output = ask_llm(messages)
            # Erwartet JSON-String
            try:
                action_obj = json.loads(llm_output)
            except json.JSONDecodeError:
                print("Pixie: (Fehler) Ungültiges JSON vom LLM:", llm_output)
                messages.append({
                    "role": "assistant",
                    "content": "Fehler: Konnte JSON nicht parsen."
                })
                continue

            action = action_obj.get("action")
            if action == "respond":
                response = action_obj.get("response", "")
                print("Pixie:", response)
                # Hier könnte TTS-Aufruf stehen, z.B.:
                # subprocess.run(["piper", "--text", response, "--model", "de_DE-thorsten-low.onnx", "--output_file", "out.wav"])
                # subprocess.run(["aplay", "out.wav"])
                messages.append({"role": "assistant", "content": response})

            elif action == "use_tool":
                tool_name = action_obj.get("tool_name")
                params = action_obj.get("parameters", {})
                tool_fn = TOOLS.get(tool_name)
                if not tool_fn:
                    err = f"Unbekanntes Tool: {tool_name}"
                    print("Pixie:", err)
                    messages.append({"role": "assistant", "content": err})
                else:
                    result = tool_fn(params)
                    print(f"Pixie (Tool '{tool_name}') →", result)
                    # Nach Tool-Ausführung: Rückkopplung ans LLM
                    messages.append({
                        "role": "tool",
                        "name": tool_name,
                        "content": result
                    })
                    # Jetzt finalen LLM-Response erzeugen lassen
                    followup = ask_llm(messages + [{
                        "role": "user",
                        "content": "Bitte nutze das Ergebnis und formuliere eine Antwort für den Nutzer."
                    }])
                    try:
                        fw = json.loads(followup)
                        if fw.get("action") == "respond":
                            resp = fw.get("response","")
                            print("Pixie:", resp)
                            messages.append({"role":"assistant","content":resp})
                        else:
                            print("Pixie: Erwartete respond, erhalten:", fw)
                            messages.append({"role":"assistant","content":str(fw)})
                    except json.JSONDecodeError:
                        print("Pixie: (Fehler) Follow-up JSON ungültig:", followup)
                        messages.append({"role":"assistant","content":"Fehler: Ungültiges Follow-up."})

            else:
                err = f"Unbekannte Aktion: {action}"
                print("Pixie:", err)
                messages.append({"role": "assistant", "content": err})

        except (KeyboardInterrupt, EOFError):
            print("\nPixie: Auf Wiedersehen!")
            sys.exit(0)
        except Exception as e:
            print("Pixie: Unerwarteter Fehler:", e)
            # Selbstheilung: Kontext zurücksetzen
            messages = [{"role": "system", "content": SYSTEM_PROMPT.strip()}]

if __name__ == "__main__":
    agent_loop()