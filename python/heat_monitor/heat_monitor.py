import time
import psutil
import matplotlib.pyplot as plt
import matplotlib.animation as animation

def get_cpu_temp():
    try:
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
            return int(f.read().strip()) / 1000.0
    except Exception:
        return psutil.sensors_temperatures().get("coretemp", [{}])[0].get("current", 0)

times = []
temps = []
start_time = time.time()

fig, ax = plt.subplots()
ax.set_title("Raspberry Pi Temperature Monitor")
ax.set_xlabel("Time (seconds)")
ax.set_ylabel("Temperature (°C)")
ax.set_ylim(30, 90)
line, = ax.plot([], [], "-r", lw=2)

def update(frame):
    current_time = round(time.time() - start_time, 1)
    current_temp = get_cpu_temp()

    times.append(current_time)
    temps.append(current_temp)

    # Keep only the last 50 values
    times[:] = times[-50:]
    temps[:] = temps[-50:]

    line.set_data(times, temps)
    ax.set_xlim(max(0, times[0]), times[-1])
    return line,

ani = animation.FuncAnimation(
    fig,
    update,
    interval=1000,
    save_count=50,
    cache_frame_data=False
)

# Attach the animation to the figure so it isn't garbage collected.
fig.anim = ani

plt.show()