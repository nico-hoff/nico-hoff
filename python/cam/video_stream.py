import cv2

def capture_video():
    # Open the default camera (usually device 0)
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        raise Exception("Could not open the USB camera.")

    # Optionally set the resolution
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("Failed to grab frame.")
                break

            # Display the frame in a window named "Video Stream"
            cv2.imshow("Video Stream", frame)

            # Exit if 'q' is pressed
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    finally:
        # Release the camera and destroy all windows
        cap.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    capture_video()
