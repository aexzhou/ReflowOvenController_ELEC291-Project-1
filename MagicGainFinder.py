import numpy as np

res_vals = [100,220,1000,4700,10000,100000,10,47,150,270,330,390,470,680,1200,1500,2000,2200,2700,3300,5100,5600,15000,
            20000,22000,33000,47000,470000,1000000,10000000]

thermocouple_data = [
    0.000, 0.039, 0.079, 0.119, 0.158, 0.198, 0.238, 0.277, 0.317, 0.357,
    0.397, 0.437, 0.477, 0.517, 0.557, 0.597, 0.637, 0.677, 0.718, 0.758,
    0.798, 0.838, 0.879, 0.919, 0.960, 1.000, 1.041, 1.081, 1.122, 1.163,
    1.203, 1.244, 1.285, 1.326, 1.366, 1.407, 1.448, 1.489, 1.530, 1.571,
    1.612, 1.653, 1.694, 1.735, 1.776, 1.817, 1.858, 1.899, 1.941, 1.982,
    2.023, 2.064, 2.106, 2.147, 2.188, 2.230, 2.271, 2.312, 2.354, 2.395,
    2.436, 2.478, 2.519, 2.561, 2.602, 2.644, 2.685, 2.727, 2.768, 2.810,
    2.851, 2.893, 2.934, 2.976, 3.017, 3.059, 3.100, 3.142, 3.184, 3.225,
    3.267, 3.308, 3.350, 3.391, 3.433, 3.474, 3.516, 3.557, 3.599, 3.640,
    3.682, 3.723, 3.765, 3.806, 3.848, 3.889, 3.931, 3.972, 4.013, 4.055,
    4.096, 4.138, 4.179, 4.220, 4.262, 4.303, 4.344, 4.385, 4.427, 4.468,
    4.509, 4.550, 4.591, 4.633, 4.674, 4.715, 4.756, 4.797, 4.838, 4.879,
    4.920, 4.961, 5.002, 5.043, 5.084, 5.124, 5.165, 5.206, 5.247, 5.288,
    5.328, 5.369, 5.410, 5.450, 5.491, 5.532, 5.572, 5.613, 5.653, 5.694,
    5.735, 5.775, 5.815, 5.856, 5.896, 5.937, 5.977, 6.017, 6.058, 6.098,
    6.138, 6.179, 6.219, 6.259, 6.299, 6.339, 6.380, 6.420, 6.460, 6.500,
    6.540, 6.580, 6.620, 6.660, 6.701, 6.741, 6.781, 6.821, 6.861, 6.901,
    6.941, 6.981, 7.021, 7.060, 7.100, 7.140, 7.180, 7.220, 7.260, 7.300,
    7.340, 7.380, 7.420, 7.460, 7.500, 7.540, 7.579, 7.619, 7.659, 7.699,
    7.739, 7.779, 7.819, 7.859, 7.899, 7.939, 7.979, 8.019, 8.059, 8.099,
    8.138, 8.178, 8.218, 8.258, 8.298, 8.338, 8.378, 8.418, 8.458, 8.499,
    8.539, 8.579, 8.619, 8.659, 8.699, 8.739, 8.779, 8.819, 8.860, 8.900,
    8.940, 8.980, 9.020, 9.061, 9.101, 9.141, 9.181, 9.222, 9.262, 9.302,
    9.343, 9.383, 9.423, 9.464, 9.504, 9.545, 9.585, 9.626, 9.666, 9.707,
    9.747, 9.788, 9.828, 9.869, 9.909, 9.950, 9.991, 10.031, 10.072, 10.113,
    10.153, 10.194, 10.235, 10.276, 10.316, 10.357, 10.398, 10.439, 10.480, 10.520,
    10.561, 10.602, 10.643, 10.684, 10.725, 10.766, 10.807, 10.848, 10.889, 10.930,
    10.971, 11.012, 11.053, 11.094, 11.135, 11.176, 11.217, 11.259, 11.300, 11.341,
    11.382, 11.423, 11.465, 11.506, 11.547, 11.588, 11.630, 11.671, 11.712, 11.753,
    11.795, 11.836, 11.877, 11.919, 11.960, 12.001, 12.043, 12.084, 12.126, 12.167,
    12.209, 12.250, 12.291, 12.333, 12.374, 12.416, 12.457, 12.499, 12.540, 12.582, 12.624
]

while True:
    print("\n\033[1m----- MAGIC GAIN FINDER -----\033[0m")
    print("\033[31mType 'x' to Exit Program\033[0m")
    print("\033[90mSys-Temp is the most important reading,\nas it tells you the temp reading difference\nbetween thermocouple temp and system temp data...\033[0m")
    tempdiff_in = input("Enter the thermocouple temperature in °C: ")
    if tempdiff_in.lower() == 'x':
        break  

    try:
        tempdiff = int(tempdiff_in)
        combinations = []

        mV = thermocouple_data[tempdiff]
        
        for r1 in res_vals:
            for r2 in res_vals:
                if r1 == r2:
                    continue
                gain = r1 / r2
                Vop = mV * gain
                if Vop / 1000 > 3.5 or np.floor(gain) ==0:  
                    continue
                
                sys = np.floor((Vop* 1000 / 41)/ np.floor(gain))
                #sys = np.floor(np.floor(np.floor(Vop) * 1000 / 41) / np.floor(gain))

                diff_Vop_tempdiff = abs(Vop - tempdiff)  
                diff_sys_tempdiff = abs(sys - tempdiff)  
                combined_difference = diff_Vop_tempdiff + diff_sys_tempdiff  
                
                combinations.append((r1, r2, Vop, sys, combined_difference, diff_Vop_tempdiff, diff_sys_tempdiff, gain))

        sorted_combinations = sorted(combinations, key=lambda x: x[4])

        top_matches = sorted_combinations[:10]

        print("\n\033[1m----- PROCESSING DONE -----\033[0m")
        print("\033[35mTop 10 Best Matches:\033[0m")
        print(f"{'R1':>10} {'R2':>10} {'Vop (mV)':>15} {'Sys':>10} {'Combined Diff (mV)':>20} {'Vop-Temp (mV)':>15} {'Sys-Temp (mV)':>15} {'Gain':>10}")
        for match in top_matches:
            r1, r2, Vop, sys, combined_diff, diff_Vop_tempdiff, diff_sys_tempdiff, gain = match
            print(f"{r1:>10} {r2:>10} {Vop:>15.1f} {sys:>10} {combined_diff:>20.1f} {diff_Vop_tempdiff:>15.1f} {diff_sys_tempdiff:>15.1f} {gain:>10.1f}")
    except ValueError:
        print("Please enter a valid int value or enter 'x' to exit program.")


# def testtest(a1,a2):
#     gg = a1/a2
#     vv = mV*gg
#     xx = np.floor(vv)
#     mm = xx*1000
#     dd = np.floor(mm/41)
#     res = np.floor(dd/np.floor(gg))
#     print("\n")
#     print("----- TEST FUNCTION -----")
#     print(f"Sys:    {res}")
#     print(f"ADC:    {vv} mV")
#     print(f"OG:     {tempdiff}")
#testtest(bestcomb['r1'],bestcomb['r2'])

