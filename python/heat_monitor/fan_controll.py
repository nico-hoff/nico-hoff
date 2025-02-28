import RPi.GPIO as GPIO
import time

FAN_PIN = 4 

GPIO.setmode(GPIO.BCM)
GPIO.setup(FAN_PIN, GPIO.OUT)

print("FAN LOW")
GPIO.output(FAN_PIN, GPIO.LOW)

print("Sleep")
time.sleep(5)

print("HIGH again")
GPIO.output(FAN_PIN, GPIO.HIGH)

GPIO.cleanup()
