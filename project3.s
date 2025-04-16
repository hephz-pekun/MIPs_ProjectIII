.data

SpaceInput: .space 1002 #space 1000 character + end + newline
null_msg: .asciiz "NULL"
semicolon: .asciiz ";"

.text
.globl main

main: #Start
    # Hard code N
    li $t0, 26  # N = 26 + (X % 11) = 26
    #Solve for N
    li $t1, 10
    sub $t2, $t0, $t1 # M = N - 10
    
    move $s7, $t2           # Save M in $s7 for later use

    # Set up range a - (M-1) = a - p
    #Set up letter range of lowercases
    li $t3, 0x61 #ASCII for 'a'
    add $t4, $t3, $t2 # add to calculate the range in ascii code
    addi $t4, $t4, -1 # Subtract one so it does not go over

    #Set up letter range for upercases
    li $t5, 0x41 #ASCII for 'A'
    add $t6, $t5, $t2 #add to calculate the range in ascii code
    addi $t6, $t6, -1 # Subtract one so it does not go over

    #Collect input from user
    li $v0, 8 #code for reading a string
    la $a0, SpaceInput # address of space
    li $a1, 1002 #Max num of chars to reading
    syscall

    # $s0: current index (0 to 9)
    # $s1: sum for first half (G)
    # $s2: sum for second half (H)
    # $s3: count of valid digits encountered

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
    li $t2, 0 # Counter for character
   
    li $s0, 0 # Output

get_substrings:
    beq $t2, 1000, exit 
    # Check first char of the group
    la $t7, SpaceInput #load base address of input buffer
    add $t7, $t7, $t2 # Go to start address of group
    lb $t8, 0($t7) # load first char 
    beqz $t8, exit # exit if null

    #Else
    la $a0, SpaceInput
    add $a0, $a0, $t2 # get group
    #Call get_substring_value
    jal get_substring_value
    move $t9, $v0 #save ans

    # Check for NULL
    li $t4, 0x7FFFFFFF
    beq $t9, $t4, print_null

    #Print semicolon if not output
    beqz $s0, no_semicolon
    li $v0, 4
    la $a0, semicolon
    syscall

no_semicolon:
    li $s0, 1 #Note output
    #Print
    li $v0, 1
    move $a0, $t9 #save ans
    syscall

    #Go to next substring
    addi $t2, $t2, 10
    j get_substrings

print_null:
    # Print semicolon
    beqz $s0, no_null_semicolon
    li $v0,4
    la $a0, semicolon
    syscall

no_null_semicolon:
    li $s0, 1
    li $v0, 4
    la $a0, null_msg
    syscall

    #Reset
    addi $t2, $t2, 10
    j get_substrings

exit:
    #Exit program
    li $v0, 10 # code for exit
    syscall

get_substring_value:
    li $t5, 0 # Counter
    li $s1, 0 # Sum of G
    li $s2, 0 # Sum of H
    li $s3, 0 # Digit count
    move $t0, $s7         # retrieve M value from $s7

    # Go through 10 chars in input
get_character:
    bge $t5, 10, solve #If index >=10, get results
    lb $t6, 0($a0) #Read/Load character
    beqz $t6, space_pad

check_digit:
    #Check if char(index) is a digit from 0 to 9
    li $t7, 0x30 # ASCII code for 0
    li $t8, 0x39 # ASCII code for 9
    blt $t6, $t7, check_if_lowercase # Check if char is lowercase if less than 0
    bgt $t6, $t8, check_if_lowercase # Check if char is lowercase if greter than 9
    # If char is a digit
    sub $t9, $t6, $t7 # Convert ASCII digit to actual num
    #nop so $t9 is updated
    j valid_digit # Go to function if its a true num
    #nop

check_if_lowercase:
    #Check if char is in range from'a' to 'p'
    li $t7, 0x61 # ASCII code for 'a'
    blt $t6, $t7, check_if_uppercase # Check if char is less that a in ascii code
    add $t8, $t7, $t0 # 'a' + 20 gives the first invalid letter
    bge $t6, $t8, check_if_uppercase # Check if char is greater than p

    #So if its lowercase ....remember it equals 10+(char- 'a')
    sub $t9, $t6, $t7 # Calculate char - 'a'
    addi $t9, $t9, 10 # Add 10
    #nop  so $t9 is updated
    j valid_digit
    #nop

check_if_uppercase:
    #Check if char is in range from'A' to 'P'
    li $t7, 0x41 # ASCII code for 'A'
    blt $t6, $t7, invalid # Check if char is less that A in ascii code, if so its invalid
    add $t8, $t7, $t0   # 'A' + M gives the first invalid letter
    bge $t6, $t8, invalid # Check if char is greater than P in ascii code, if so its invalid
    
    #So if its valid ....remember it equals 10 + (char- 'A')
    sub $t9, $t6, $t7 # Calculate char - 'A'
    addi $t9, $t9, 10 # Add 10
    #nop    # so $t9 is updated
    j    valid_digit
    #nop

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
    j       move_index


invalid:
    #Continue/skip char if its not valid 
    j move_index


space_pad:
    # Pad space
    li   $t6, 0x20     # so space becomes null
    j    check_digit

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
    sub $v0, $s1, $s2
    jr $ra # Return

save_null:
    li $v0, 0x7FFFFFFF # code to print string since N/A is saved as a string
    jr $ra
