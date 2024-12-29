import time
import serial
import struct
import queue
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sys
import math
import threading


# Initialize serial connection
ser = serial.Serial( 
    port='COM7',  # Adjust as needed
    baudrate=115200,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS
)

# Queue for data integrity
data_queue = queue.Queue()

# Shutdown signal
shutdown_event = threading.Event()

# extract data from q
def data_gen():
    while not shutdown_event.is_set() or not data_queue.empty():
        try:
            t, val = data_queue.get(timeout=0.1)
            yield t, val
        except queue.Empty:
            continue


# def run(data):
#     t, y = data
#     if t > -1:
#         xdata.append(t)
#         ydata.append(y)
#         # if len(xdata) > 200:
#         #     xdata.pop(0)
#         #     ydata.pop(0)
#         if t > xsize:  # Scroll to the left.
#             ax.set_xlim(t - xsize, t)
#         line.set_data(xdata, ydata)

# # auto shutdown if plot if closed
# def on_close_figure(event):
#     shutdown_event.set()
#     plt.close(fig)

# serial data reading function
def read_serial_data():
    
    t = 0
    while not shutdown_event.is_set():
        if ser.in_waiting > 0:
            data = ser.read(31)
            if len(data) == 31:
                temp_mc, temp_lm, tempc, temp_lm_c, oven_state, button_state, seconds, SoakTime, SoakTemp, ReflowTime, ReflowTemp, dout1, dout2, aindids, adccon0, adc1, adc2 = struct.unpack('<IIBBBBBBBBBIIBBHH', data)
                # temp_mc = format(temp_mc, '.3f')

                #tempcom = hex(command
                              

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



# PLOTTING
# xsize = 100
# fig = plt.figure()
# fig.canvas.mpl_connect('close_event', on_close_figure)
# ax = fig.add_subplot(111)
# line, = ax.plot([], [], lw=2, color='red')
# ax.set_ylim(0, 250)
# ax.set_xlim(0, xsize)
# ax.grid()
# xdata, ydata = [], []
# ax.set_xlabel('Time (0.5s)',fontsize=12)
# ax.set_ylabel('Temperature',fontsize=12)
# ax.set_title('Live Temperature Reading', fontsize=16, fontweight='bold')

# def title_change(mode):
#     if mode == 1:
#         ax.set_title('Real-time Temperature Data (°C)', fontsize=16, fontweight='bold')
#     elif mode == 2: 
#         ax.set_title('Real-time Temperature Data (°F)', fontsize=16, fontweight='bold')
#     else:
#         ax.set_title('Real-time Temperature Data', fontsize=16, fontweight='bold')
#     fig.canvas.draw_idle() 

# ani = animation.FuncAnimation(fig, run, data_gen, blit=False, interval=100, repeat=False, cache_frame_data=False)
# plt.show(block=False)

# multithreading
serial_thread = threading.Thread(target=read_serial_data)
serial_thread.start()



# # allow script to run under the existence of plot
# try:
#     while plt.fignum_exists(fig.number):
#         plt.pause(0.1)
# except KeyboardInterrupt:
#     print("User Interrupt")

# # tell thread to stop if it sees shutdown signal
# shutdown_event.set()
# serial_thread.join()

