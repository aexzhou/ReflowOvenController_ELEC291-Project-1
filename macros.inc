;---------------------------------;
; Send a BCD number to PuTTY      ;
;---------------------------------;
Send_BCD mac
push ar0
mov r0, %0
lcall ?Send_BCD
pop ar0
endmac
?Send_BCD:
push acc
; Write most significant digit
mov a, r0
swap a
anl a, #0fh
orl a, #30h
lcall putchar
; write least significant digit
mov a, r0
anl a, #0fh
orl a, #30h
lcall putchar
pop acc
ret
