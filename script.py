import time
import serial
import struct
import queue
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import threading
from scipy.signal import savgol_filter

xdata, ydata = [], []

def init_serial_connection(): #serial init
    return serial.Serial(port='COM7', baudrate=115200, parity=serial.PARITY_NONE,
                         stopbits=serial.STOPBITS_ONE, bytesize=serial.EIGHTBITS)

def setup_plot(): #plotting settings
    fig, ax = plt.subplots()
    line, = ax.plot([], [], lw=2, color='red')
    ax.set_xlim(0, xsize)
    ax.set_ylim(0, 260)  # Initial y-axis limits, adjust as needed
    ax.grid()
    ax.set_xlabel('Time (s)', fontsize=12)
    ax.set_ylabel('Temperature', fontsize=12)
    ax.set_title('Live Temperature Reading', fontsize=16, fontweight='bold')
    return fig, ax, line

def configure_animation(fig, line, data_gen):
    ani = animation.FuncAnimation(fig, run, data_gen, blit=False, interval=160, repeat=False, cache_frame_data=False)
    return ani

def data_gen(data_queue, shutdown_event): # gets data outta que
    while not shutdown_event.is_set() or not data_queue.empty():
        try:
            t, val = data_queue.get(timeout=0.1)
            yield t, val
        except queue.Empty:
            continue

def run(data):
    """put new data into graph"""
    t, y = data
    if t > -1:
        current_time_seconds = t * 0.16
        xdata.append(current_time_seconds)
        ydata.append(y)
        
        adjust_axes(ax, t, y, min_y_span = 10) # lock in on new data
        apply_smoothing(line)

def adjust_axes(ax, t, y, min_y_span):
    """Adjust the axes based on the current data point."""
    current_time_seconds = t * 0.16
    midpoint = xsize / 2
    running_x_left = max(0, current_time_seconds - midpoint)
    running_x_right = running_x_left + xsize
    ax.set_xlim(running_x_left, running_x_right)
    
    visible_ydata = [y for x, y in zip(xdata, ydata) if running_x_left <= x <= running_x_right]
    if visible_ydata:
        min_y = min(visible_ydata)
        max_y = max(visible_ydata)
        if (max_y - min_y) < min_y_span:
            mid_y = (max_y + min_y) / 2
            min_y = mid_y - min_y_span / 2
            max_y = mid_y + min_y_span / 2
        ax.set_ylim(min_y - 1, max_y + 1)  # Optional: adjust the margin as needed

def apply_smoothing(line, method='moving_average'):
    """Apply smoothing filter to graph."""
    if len(ydata) < window_length:
        # if not enough data to smooth, plot original data
        line.set_data(xdata, ydata)
        return

    if method == 'savgol':
        # Savitzky-Golay filter
        smoothed_ydata = savgol_filter(ydata, window_length, poly_order)
    elif method == 'moving_average':
        smoothed_ydata = np.convolve(ydata, np.ones(window_length) / window_length, mode='valid')
       
        adjusted_xdata = xdata[len(xdata) - len(smoothed_ydata):]  # Adjust xdata for moving average since it reduces the array size
        line.set_data(adjusted_xdata, smoothed_ydata)
        return
    
    line.set_data(xdata, smoothed_ydata)
        
def read_serial_data(ser, data_queue, shutdown_event):
    
    t = 0
    while not shutdown_event.is_set():
        if ser.in_waiting > 0:
            data = ser.read(31)
            if len(data) == 31:
                temp_mc, temp_lm, tempc, temp_lm_c, oven_state, button_state, seconds, SoakTime, SoakTemp, ReflowTime, ReflowTemp, dout1, dout2, aindids, adccon0, adc1, adc2 = struct.unpack('<IIBBBBBBBBBIIBBHH', data)
                                            
                print(
                    # f"THJ_raw:{temp_mc:>13} |",\
                    # f"TCJ_raw:{(temp_lm):>13} |",\
                    f"tempc:{int(tempc):>3} |",\
                    f"temp_lm_c:{int(temp_lm_c):>3} |",\
                    f"OvenS:{int(oven_state):>3} |",\
                    f"ButS:{int(button_state):>3} |",\
                    f"sec:{int(seconds):>3} |",\
                    # f"Stime:{int(SoakTime):>3} |",\
                    # f"Stemp:{int(SoakTemp):>3} |",\
                    # f"Rtime:{int(ReflowTime):>3} |",\
                    # f"Rtemp:{int(ReflowTemp):>3} |",\
                    # f"d1(4): {int(dout1):>6} |",\
                    # f"d2(4): {int(dout2):>6} |",\
                    f"test1: {bin(aindids):>10} | ",\
                    f"test2: {bin(adccon0):>10} | ",\
                    f"adc1: {int(adc1):>4} |",\
                    f"adc2: {int(adc2):>4} |",\
    
                    ) 
                data_queue.put((t, float(tempc)))
                t += 1

            else:
                print("DATA FORMAT ERROR:", data)
        else:
            time.sleep(0.1)  


def main():
    global ser, fig, ax, line, xsize, window_length, poly_order
    
    ser = init_serial_connection()
    
    data_queue = queue.Queue()  # shutdown, dataqueue
    shutdown_event = threading.Event()
    
    xsize = 100  # plot settings
    fig, ax, line = setup_plot()
    window_length = 11  # must be odd, these two lines r for smoothing
    poly_order = 4  # Savitzky-Golay filter
        
    ani = configure_animation(fig, line, lambda: data_gen(data_queue, shutdown_event))
    plt.show(block=False)   # anime, this j works 
    
    serial_thread = threading.Thread(target=read_serial_data, args=(ser, data_queue, shutdown_event))
    serial_thread.start()   # put serial reading in a diff thread so no crashy
    
    try:
        while plt.fignum_exists(fig.number):  # keep script running while plotting hapens
            plt.pause(0.1)
    except KeyboardInterrupt:
        print("User Interrupt")
    finally:
        shutdown_event.set()
        serial_thread.join()
        print("PROGRAM EXIT")

if __name__ == "__main__":
    main()
