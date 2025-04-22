.data

SpaceInput: .space 1002 #space 1000 character + end + newline
null_msg: .asciiz "NULL"
semicolon: .asciiz ";"
.align 2
strint: .space 4000  # Array to store results (4 bytes * 1000 max entries)


.text
.globl main
#------------------------------------------------------------
# main: read string, strip newline, call process_string, then
#       print strint[0..count-1] per spec.
#------------------------------------------------------------
main: #Start
    # Hard code N
    li $t0, 26  # N = 26 + (X % 11) = 26
    #Solve for N
    li $t1, 10
    sub $s7, $t0, $t1 # M = N - 10
    
    #Collect input from user
    li $v0, 8 #code for reading a string
    la $a0, SpaceInput # address of space
    li $a1, 1002 #Max num of chars to reading
    syscall

    la   $t7, SpaceInput    # pointer to input string
 
remove_newline:
    lb   $t0, 0($t7)
    beqz $t0, no_remove    # reached end of string
    li   $t8, 0x0A          # newline character
    beq  $t0, $t8, replace_null
    addi $t7, $t7, 1
    j    remove_newline

replace_null:
    sb $zero, 0($t7) #replace newline with null terminator
    # Initalize loop and sums

no_remove:
    la   $a0, SpaceInput
    la   $a1, strint
    jal  process_string

    move $t0, $v0        # count
    li   $t1, 0          # index
    la   $t2, strint     # array base

get_substrings:
    beq $t1, $t0, exit 
    lw   $t3, 0($t2)
    li   $t4, 0x7FFFFFFF
    beq  $t3, $t4, print_null

    #print integer
    li   $v0, 1
    move $a0, $t3
    syscall
    j    print_semicolon

print_null:
    # Print null
    li $v0, 4
    la $a0, null_msg
    syscall

print_semicolon:
    addi $t1, $t1, 1
    beq  $t1, $t0, no_semicolon
    li   $v0, 4
    la   $a0, semicolon
    syscall

no_semicolon:
    #Reset
    addi $t2, $t2, 4
    j get_substrings

exit:
    #Exit program
    li $v0, 10 # code for exit
    syscall
#------------------------------------------------------------
# process_string(strptr in $a0, arrptr in $a1):
    # $s0: current index (0 to 9)
    # $s1: sum for first half (G)
    # $s2: sum for second half (H)
    # $s3: count of valid digits encountered
#------------------------------------------------------------
process_string:
    addi $sp, $sp, -16
    sw   $ra,    0($sp)
    sw   $s0,    4($sp)
    sw   $s1,    8($sp)
    sw   $s2,   12($sp)
    move $s0, $a1        # arrptr
    move $s1, $a0        # strptr
    li   $s2, 0          # count = 0

ps_loop:
    lb   $t0, 0($s1)
    beqz $t0, ps_done
    # push substring address
    addi $sp, $sp, -4
    sw   $s1, 0($sp)

    jal  get_substring_value
    # pop return value into $t1
    lw   $t1, 0($sp)
    addi $sp, $sp, 4
    # store into array
    sw   $t1, 0($s0)
    addi $s0, $s0, 4
    addi $s2, $s2, 1
    addi $s1, $s1, 10
    j    ps_loop

ps_done:
    move $v0, $s2 #return count
    # restore $ra and $s0–$s2
    lw   $ra,    0($sp)
    lw   $s0,    4($sp)
    lw   $s1,    8($sp)
    lw   $s2,   12($sp)
    addi $sp, $sp, 16
    jr   $ra

#------------------------------------------------------------
# get_substring_value:
#   pops one word off stack → $a0,
#   processes exactly 10 chars, sums G,H base‑N digits,
#   pushes G–H or 0x7FFFFFFF back on stack.
#   preserve $s1–$s3.
#------------------------------------------------------------
get_substring_value:
    # pop substring address into $a0
    lw   $a0, 0($sp)
    addi $sp, $sp, 4
    # save $s1–$s3
    addi $sp, $sp, -12
    sw   $s1, 8($sp)
    sw   $s2, 4($sp)
    sw   $s3, 0($sp)

    # init
    li $t5, 0 # char index
    li $s1, 0 # Sum of G
    li $s2, 0 # Sum of H
    li $s3, 0 # Digit count

    # Go through 10 chars in input
get_character:
    bge $t5, 10, solve #If index >=10, get results
    lb $t6, 0($a0) #Read/Load character
    beqz $t6, space_pad
    j    check_digit

space_pad:
    # Pad space
    li   $t6, 32     # so space becomes null
  
check_digit:
    #Check if char(index) is a digit from 0 to 9
    li $t7, 48 # ASCII code for 0
    li $t8, 57 # ASCII code for 9
    blt $t6, $t7, check_if_lowercase # Check if char is lowercase if less than 0
    bgt $t6, $t8, check_if_lowercase # Check if char is lowercase if greter than 9
    # If char is a digit
    sub $t9, $t6, $t7 # Convert ASCII digit to actual num
    #nop so $t9 is updated
    j valid_digit # Go to function if its a true num
    #nop

check_if_lowercase:
    #Check if char is in range from'a' to 'p'
    li $t7, 97 # ASCII code for 'a'
    blt $t6, $t7, check_if_uppercase # Check if char is less that a in ascii code
    add $t8, $t7, $s7 # 'a' + 20 gives the first invalid letter
    bge $t6, $t8, move_index # Check if char is greater than p

    #So if its lowercase ....remember it equals 10+(char- 'a')
    sub $t9, $t6, $t7 # Calculate char - 'a'
    addi $t9, $t9, 10 # Add 10
    #nop  so $t9 is updated
    j valid_digit
    #nop

check_if_uppercase:
    #Check if char is in range from'A' to 'P'
    li $t7, 65 # ASCII code for 'A'
    blt $t6, $t7, move_index # Check if char is less that A in ascii code, if so its invalid
    add $t8, $t7, $s7   # 'A' + M gives the first invalid letter
    bge $t6, $t8, move_index # Check if char is greater than P in ascii code, if so its invalid
    
    #So if its valid ....remember it equals 10 + (char- 'A')
    sub $t9, $t6, $t7 # Calculate char - 'A'
    addi $t9, $t9, 10 # Add 10


valid_digit:
    # Works only when a valid digit is found
    # Increase the valid digit counter.
    addi $s3, $s3, 1 #So +1

    # Check the index to know if it is G or H
    li $t7, 5
    blt $t5, $t7, add_first # if less than five

    # Add digit value to second half sum (H)
    add     $s2, $s2, $t9
    j       move_index

add_first:
    #Add to G
    add $s1, $s1, $t9

move_index:
    addi $t5, $t5, 1 # Add one to move to next char
    addi $a0, $a0, 1
    j get_character # jump back to loop

solve:
    # If no valid char were found, print N/A
    # Else solve G-H and print
    #If
    beqz $s3, save_null
    #Else
    sub $t0, $s1, $s2
    jr return_value # Return

save_null:
    li $v0, 0x7FFFFFFF # code to print string since N/A is saved as a string
    
return_value:
    # restore $s1–$s3
    lw   $s1, 8($sp)
    lw   $s2, 4($sp)
    lw   $s3, 0($sp)
    addi $sp, $sp, 12
    #push return
    addi $sp, $sp, -4
    sw   $t0, 0($sp)
    jr   $ra