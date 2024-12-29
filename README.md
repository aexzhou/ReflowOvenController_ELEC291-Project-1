# ELEC 291 Project 1 - Reflow Oven Controller using 8051 Assembly
Brandon Cheong, Joe Graham, Baneesh Khosa, Alexanne Lavoie, Hrudai Rajesh, Alex Zhou 

## Table of Contents
- [ELEC 291 Project 1 - Reflow Oven Controller using 8051 Assembly](#elec-291-project-1---reflow-oven-controller-using-8051-assembly)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Investigation](#investigation)
    - [Idea Generation](#idea-generation)
    - [Investigation Design](#investigation-design)
    - [Data Collection and Synthesis](#data-collection-and-synthesis)
    - [Analysis of Results](#analysis-of-results)
  - [Design](#design)
    - [Use of Process](#use-of-process)
    - [Need and Constraint Identification](#need-and-constraint-identification)
    - [Problem Specification](#problem-specification)
    - [Solution Generation](#solution-generation)
    - [Solution Evaluation](#solution-evaluation)
    - [Detailed Design](#detailed-design)
    - [Solution Assessment](#solution-assessment)
  - [Live-Long Learning](#live-long-learning)
  - [Conclusions](#conclusions)
  - [References](#references)
  - [Bibliography](#bibliography)

---

## Introduction
The objective of this design project is to create a Reflow Oven Controller. This system should have user-variable settings for soak temperature, soak time, reflow temperature, and reflow time. It should measure temperatures between 25 and 240 degrees Celsius using a K-type thermocouple wire and control an off-the-shelf oven using an SSR. Finally, it should both display and audibly report the temperature, running time, and state of the reflow process using an LCD and speaker.

![][image1]  
*Figure 1: Software Block Diagram*  

![][image2]  
*Figure 2: Hardware Block Diagram*  

---

## Investigation

### Idea Generation
Upon understanding the specification, our team revised the codes we had used for previous labs. From lab 3, our team had a basis on how to design a temperature sensor using assembly. From lab 2, our team considered how to utilize a timer to count in seconds, as well as play sound through a speaker. Moreover, our team determined that a finite state machine would need to be used to match the specification. It was also determined that this would be needed in order to play sound; however, we also explored the possibility of having the second state machine embedded in the timer, so as to have the state machines running concurrently.

### Investigation Design
Our team split the two components of sound and temperature among ourselves to work in a pair and a group of 3. These pairs would work to gain an understanding of that component, then develop their understanding by trying different implementations. They would check how these work in isolation, then create a simple main code to test how they could possibly be combined with other components into the final project code. Once the pair was confident with an idea, they would use a copy of the finite state machine template our team had created to test and debug. Once working with the sample finite state machine, it was all put together in a final draft of our project code.

The pair working on sound initially used test code to ensure that the circuit they designed to use the speaker worked. Following this, the pair wrote code to play snippets of the test sound file. They then recorded their own sound file and tested that with the same code to ensure the audio quality was acceptable. They then wrote code to decide in which order the sound fragments would be played based on the temperature reading. Following this, they designed and tested a code to play the sound periodically, while the values were changing.

The group working on the temperature sensor first tested the thermocouple using a voltmeter to ensure the components were working. They then designed a circuit and code to convert the voltage readings from the thermocouple and the LM355. This circuit involved the use of an op-amp and a couple of resistors, so the pair was tested vigorously to ensure they were using the right components. Once operational, the group then implemented this design with a copy of the FSM to ensure that it changed states based on temperature readings. This confirmed whether or not the FSM was functional, and would then be combined with code to provide power to the reflow oven.

### Data Collection and Synthesis
The group working on temperature would use code designed in Python to graph the recorded temperatures. The heat was applied to the thermocouple using a soldering iron and a lighter, and the results were graphed. The graph would give an indicator as to how responsive the thermocouple was to changing temperature. The temperature values would also indicate whether the implementation matched the specification, as the reflow oven had to read temperatures up to 240 degrees Celsius. The thermocouple was then placed in the oven and combined with the code to provide power. The graph would then show when the oven was heating up, and when it was at a constant temperature or cooling down.

The pair working on sound first had to ensure the audio was cut properly to ensure every possible combination of numbers could be used. They designed code that would increment the number address by 1 to check each of the addresses where the audio snippets were stored. They then designed code that would change a number every 5 seconds, and checked if the speaker would output the corresponding number. The pair made sure to test 1-digit, 2-digit numbers above 20, and 3-digit numbers to ensure the speaker could play all possible temperature values. This was to be done by playing snippets one after another if the value was above 20.

### Analysis of Results
While testing the temperature, the group found that it could indeed record temperature values of 240 degrees Celsius. They managed to plot this using Python to confirm it. They also found that the FSM implemented worked with the thermocouple and the temperature readings. They then found that they could accurately control the oven temperature using their state machine and were able to change the parameters and obtain the expected response. This suggested that the power and temperature reading aspect met the specification.

The pair working on the sound found they could play any possible number up until 299. They also found they could play the sound every 5 seconds, and that they could play sounds for different numbers every 5 seconds. This suggested that in isolation, their FSM worked well. However, they were unable to implement it with the main FSM for the project code. They found that jumping between FSMs would disrupt the temperature recording and display until the sound had finished playing, which potentially could lead to the oven being hotter than recorded. This would risk not matching the part of the specification where the error must be no more than ± 3 degrees Celsius.

---

## Design

### Use of Process
Our team used the engineering design process that we learned in APSC 100 and 101 last year. First, we studied and clarified the problem by reading the design requirements and writing down a list of features that we needed to implement in the final design. We then generated potential solutions by brainstorming ways to implement the design. We also discussed which parts of the design should be hardware- and software-based. After some discussion, we identified the design we wanted to go forward with and separated it into different parts that each of us could work on. Finally, we developed and tested our solution, iterating the design along the way.

### Need and Constraint Identification
Our group first identified needs by looking at the design requirements. All of the requirements are consumer needs and features that need to be implemented. However, there were also consumer needs that were not listed that we had to brainstorm ourselves. Other customer and user needs included button accessibility, clean and aesthetic hardware placement and wiring, and overall sturdiness so that the hardware doesn’t come apart when moved. We also identified needs for ourselves while working in a group: well-formatted and readable code, and an easy-to-understand circuit design.

We discussed constraints in a similar fashion. Constraints included the hardware we were working with, the quality of the components such as the speaker, and time limitations.

### Problem Specification
We kept the original requirements as specified in the assignment document, as they highlighted the consumer needs. These requirements included that the temperature be measured using a K-type thermocouple, that the oven would be controlled via an SSR, and that the user would be able to select soak temperature, soak time, reflow temperature, and reflow time using pushbuttons. It also required that the controller would display the current state and temperature on the LCD, and that it would speak the state and temperature using a speaker.

We also added more requirements after analyzing the consumer, user, and enterprise needs. These requirements included accessible buttons, clean and aesthetic hardware placement and wiring, and overall sturdiness so that the hardware doesn’t come apart when moved. We needed to have legible code so that we can understand it when working together, and so that others can read it.

For the code, we needed to create an FSM that would control the reflow process. It would be started by user input, and the rest of the states would be automatically triggered by either the time or the temperature. We would also need a second FSM that would control the sound output. We would also need to display the temperature via graph using Python. We would have to have a concise audio file to fit on the limited data size of the 25Q32 component, all while having well-recorded audio so that it can be heard on the low-quality speaker.

### Solution Generation
The group had several ideas for a user interface. One problem was how to have the user change the soak temperature, soak time, reflow temperature, and reflow time. One solution was to have four buttons, one to index each of the four parameters up by one. Another solution was to have eight buttons—one to index each of the four parameters up by one, and another four to index the parameters down by one. Lastly, one solution was to have four buttons to index up by one, then a shift button that, when pressed, would cause the four buttons to index down by one.

In regards to hardware, we mostly followed the given circuit for the speaker and external memory, so that part was pretty straightforward. The op amp aspect was again mostly provided, so we just had to wire it. The only part we didn’t get was the resistor values. We decided to use an R1 of 100 Ω and an R2 of 100 Ω. We calculated these values using our voltage reference as our maximum temperature (we arbitrarily selected 250 ℃). We then used the values provided by the National Institute of Standards and Technology \[1\] to see the voltage the thermocouple produced at 250 ℃ and solved for the gain we needed. This gain ended up being about 331. Our R1/R2 (33 k/100 Ω) gives us about 331, which matches the required gain. We then copied our lab 3 to use the external ADC to send data to the 8051 processor. 

For the software portion of the design, the group decided to use an FSM to control the reflow process. The group had several solutions for the FSM. One solution was: once a state is finished, it would call the next state and stay in that state. Another solution was: once a state is finished, it would then set a variable to a certain number, indicating that the state has been completed, and loop back to the first state to run through each of the previous states before going to the next state. Our group also had different ideas for the sound FSM. One version was to have the sound playing commands in the first FSM. The other idea was to have the first FSM call the second FSM, which would operate similarly to the first FSM except that it would call upon the sound-playing command, then call back to the main FSM.

### Solution Evaluation
We used our single design idea for the Op-Amp. For the user interface, the group decided to have four buttons accompanied by a shift button to index the parameters. Eight buttons would have been excessive and complicated, while four buttons would have been tedious to index in only one direction.

For the software design, the group decided to use the FSM that would skip to the top of the FSM with a variable that indicates what state we are in because it would allow us to read the temperature every loop. For the sound FSM, we picked the same design but were unable to pick a successful solution to incorporate it into the main FSM.

### Detailed Design
For the software part of the design, our main program is hinged on the FSM. The FSM starts at the function `FSM1` on line 634. In this function, the current state of the FSM, which is the variable `FSM1_state`, is moved into `a`, then the program continues to `FSM1_state0`.  

`FSM1_state0` is the wait state before any user input is given. In `FSM1_state0`, the comparison between 0 and `a` assures that if `a`, and therefore `FSM1_state`, is equal to 0, then the program is in the correct state and will continue with the rest of the code in the state. Otherwise, it will jump to the next state. After the comparison, the program sends a signal of 0 to the SSR, meaning that the oven will get no power. Then the program checks if the start button (`START_PB`) is pressed, and if it isn’t, it jumps to `FSM1_state0_done`.

`FSM1_state0_done` jumps to `loop`, where if the corresponding button is pressed, the value of the variable `temp_soak` would change. Then the variable would be displayed at the cursor location on the LCD. Then there is a call to `Save_Configuration` to keep the display and variable the same. Then the program continues to `loop_a`, which does the same for the `time_soak` variable, then `loop_b` for the `temp_refl` variable, then `loop_c` for the `time_refl` variable. When `loop_c` is done, the program jumps back to `FSM1`, which is explained in the previous paragraph.

If in `FSM1_state0`, `START_PB` is pressed, then the program continues to change the variable `FSM1_state` to 1, and jumps to `FSM1_state1`. In this state, whether or not the program is in the correct state is checked identically to `FSM1_state0`. Then the program displays a message signifying that it has entered the ramp to soak stage, the seconds that it has been in that state, and the current temperature inside of the oven. It also sets the signal to the SSR to 1000, meaning that the oven will be at full power. Then the program checks if the `safetycheck_flag` is 1. If it isn’t, it continues on to `check_safety`. Here, it checks if the program has been in state 1 for over 50 seconds. If it is, it could mean that the thermocouple isn’t in the oven, or it isn’t reading correctly, which can be dangerous for the PCB or could even be a fire hazard. Hence, if it has been in state 1 for over 50 seconds, the program jumps to `FSM1_ERROR`.

In the `FSM1_ERROR` state, an error message is displayed on the screen and the signal to the SSR is set to zero, so that the oven is turned off.

If it is not in state 1 for over 50 seconds, then the program jumps to `Safety_Passed`. There it checks if the oven has reached the temperature set by the user. If it hasn’t, it jumps to `FSM1_state1_done`, which then jumps to `loop_temp`. There it reads the temperature from the thermocouple. Then it jumps to `FSM1` where the program continues on to check if `FSM1_state` is equal to 0 in `FSM1_state0`. Since `FSM1_state` is equal to 1, the comparison fails and the program comes back to `FSM1_state1`.

If it has reached the temperature set by the user in the `temp_soak` variable, the program changes the variable `FSM1_state` to 2, and jumps to `FSM1_state2`. In this state, whether or not the program is in the correct state is checked identically to `FSM1_state0` and `FSM1_state1`. Then the program displays a message signifying that it has entered the soak stage, the seconds that it has been in that state, and the current temperature inside of the oven. It also sets the signal to the SSR to 200, which keeps the oven at a constant temperature. It then subtracts the number of seconds it has been in this state from the `time_soak` variable set by the user, and checks if it is equal to zero. If it is equal to zero, then it means that it has been in the soak state for the correct amount of time. If not, it jumps to `FSM1_state2_done`.

In `FSM1_state2_done`, the program jumps to `loop_temp`, where it reads the temperature from the thermocouple. Then it jumps to `FSM1` where the program continues on to check if `FSM1_state` is equal to 0 in `FSM1_state0`, or 1 in `FSM1_state1`. Since `FSM1_state` is equal to 2, both comparisons fail and the program comes back to `FSM1_state2`.

If the program has been in the soak state for the correct amount of time, the program continues in `FSM1_state2` to change `FSM1_state` to 3. It then jumps back to `loop_temp` and fails the comparison in each previous state so that it comes to `FSM1_state3`.

In `FSM1_state3`, whether or not the program is in the correct state is checked identically to previous states. Then the program displays a message signifying that it has entered the ramp to peak state, the seconds that it has been in that state, and the current temperature inside of the oven. It also sets the signal to the SSR to 1000, which keeps the oven at a constant temperature. It then subtracts the temperature from the `temp_refl` variable set by the user, and checks if it is equal to zero. If it is equal to zero, then it means that it has reached the temperature set by the user. If it is not zero, it jumps to `FSM1_state3_done`, which does the exact same thing as `FSM1_state2_done`. Otherwise, it changes `FSM1_state` to 4 and moves on to `FSM1_state4` as it did in previous states.

`FSM1_state4` works very similarly to `FSM1_state2`. The program displays a message signifying that it has entered the reflow stage, the seconds that it has been in that state, and the current temperature inside of the oven. It also sets the signal to the SSR to 200, which keeps the oven at a constant temperature. It then subtracts the number of seconds it has been in this state from the `time_soak` variable set by the user, and checks if it is equal to zero. If it is equal to zero, then it means that it has been in the soak state for the correct amount of time. If not, it jumps to `FSM1_state4_done`, which does the exact same thing as `FSM1_state2_done`. Otherwise, it changes `FSM1_state` to 5 and moves on to `FSM1_state5` as it did in previous states.

In `FSM1_state5`, the program displays a message signifying that it has entered the cooling stage, the seconds that it has been in that state, and the current temperature inside of the oven. The program sets the signal to the SSR to 0, which turns the oven off to let it cool.

The Sound FSM receives the number to play on the speaker in `R1`. In state 1, this value is checked to see if it's greater than 200 or 100. If it is, the address in `R2` is changed to play 100 or 200. Then arithmetic is done so that 100 or 200 is subtracted from the value in `R1`, and then the FSM goes into state 2 with a new `R1` value. In state 2, the FSM checks if the sound is still playing. If so, then it stays in this state until the speaker is off again. In state 3, the value is checked to see if it's above 20. Again, a similar process occurs where `R2` plays the address of the tens value, so 90, 80, 70, etc. Then similar arithmetic is done, and a new value for `R1` is used in state 4. State 4, like state 2, checks if the speaker is off, then moves to state 5. In state 5, the value in `R1` is checked if it's any number between 1 and 19. If it is any of these values, then `R2` is changed to the address of that number. Then in state 6, the FSM checks again if the sound is still playing. Once done, the address in `R2` is changed to play the sound “degrees Celsius,” and the state is changed back to 1.

![][image3]  
*Figure 3: Op-Amp Diagram*

For hardware, we started off by using a thermocouple to measure the oven temperature and the LM335 analog temperature sensor to measure ambient temperature. Both of these work by producing a certain voltage when they’re at a certain temperature. The voltage of the thermocouple had to be amplified, because it outputs a voltage of 41 μV/℃ and our reference voltage was 4.096 V. To do this, we used an op amp circuit designed in such a way to produce a gain of 331. This made it so that at 250 ℃ the ADC (Analog to Digital Converter) read a voltage of 4.096 V from the thermocouple. These values then went into an ADC, which was connected using an SPI to our 8051. The ADC would then send a number from 0–1023 to the 8051. Within the code, we then converted the numbers from the LM355 and the thermocouple into temperature and added them together to get our actual temperature.

### Solution Assessment
To test that our system fully worked, we spent time testing each part of the controller. First, we tested the buttons to make sure that they would index up and down (using the shift button) from 0 to 255. We also tested that the display would show the correct state, time, and temperature for all states. We tested that the oven would turn to maximum, off, or a steady temperature depending on the state. We found that it would do this correctly and instantly. We also tested that the error state worked. It would turn the oven off after 50 seconds of being in the Ramp to Soak state, as expected. Unfortunately, we were unable to integrate the Sound FSM. It worked completely on its own but due to time constraints we weren’t able to get it to work with the main FSM. We also had an error occur that would sometimes not recognize the serial port and would therefore not display to Python. This seemed to be an issue with the computer and not our hardware, but was still concerning and unfixed. To verify that our controller was reading and operating at the correct temperature, we used a piece of paper to see what color it would be after putting it in the oven. We found that it was the correct color. Unfortunately, due to time constraints, we did not perform any analysis using a third-party thermometer or another measurement tool to see that we were within the correct temperature.

---

## Live-Long Learning
Throughout the project, we applied multiple technical skills. Coding and hardware skills were especially used throughout. As such, ELEC 201, CPEN 211, and what we’ve done so far in ELEC 291 stand out as the most important courses used during this project. ELEC 201 was used especially in the design of the circuit, and CPEN 211 was used to design the finite state machine. The temperature sensor that we made in lab 3 served as a great starting point for this lab, and that knowledge was used throughout the creation of the new temperature sensor.

The sound portion showed a knowledge gap, as prior to this experience we’d never dealt with external memory before to store data. Although lots of the memory aspect was on the course page, it proved difficult to integrate it into our finite state machine. Individually, all our components worked fine, but we had lots of difficulty bringing them all together to make one machine.

Throughout this project, we learned new things about circuit design, hardware design, and software design that will help complete projects in our futures as electrical engineers.

---

## Conclusions
In conclusion, after spending 60 hours in the lab, we are pleased to have completed the Reflow Oven Controller project. The reflow oven is a versatile and user-friendly system with advanced functionalities that offer users greater control over their reflow process.

Our design is intended to integrate a speaker that announces the current temperature every 5 seconds and an LCD display that provides real-time updates on the various stages of the reflow process. We achieved this through the creation of two finite-state machines—one for the stages of the oven and another for the speaker sounds.

We faced many challenges during the development process, including difficulties with implementing the sound with the main stages FSM and some issues with the thermocouple wire readings.

The oven has the ability to measure temperatures between 25 and 240 degrees Celsius using a K-type thermocouple wire and control an off-the-shelf oven using an SSR. We believe that our system represents an innovative solution to the challenges faced in the electronics industry. The Reflow Oven Controller is a significant achievement that demonstrates our commitment to designing systems that meet the needs of modern technology.

---

## References
\[1\] National Institute of Standards and Technology, “DITS-90 Table for type K thermocouple”, 1993.

---

## Bibliography
- Calvino-Fraga, Jesus, *Project 1 – Microcontrollers*, 2023  
- Calvino-Fraga, Jesus, *Project 1 – EFM8 Board, FSM, NVMEM, Tips*, 2023  

---

[image1]: Figures/image1.png
[image2]: Figures/image2.png
[image3]: Figures/image3.png