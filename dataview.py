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
    port='COM5',  # Adjust as needed
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
            data = ser.read(9)
            if len(data) == 9:
                value, fsm_state, command = struct.unpack('<iBi', data)
                outval = format(value/1000, '.3f')

                #tempcom = hex(command)
                fsm_state_bin = bin(fsm_state)

                print(f"Temp: {outval:>8} | FSM State: {fsm_state:>4} = {fsm_state_bin:<10} | data_out[31:0]: {bin(command)}")
                data_queue.put((t, float(outval)))
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

# tell thread to stop if it sees shutdown signal
# shutdown_event.set()
# serial_thread.join()

