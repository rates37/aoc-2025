# usage: java -jar mars.jar nc sm day11_part2.asm pa input.txt


#! ======== Data segment =========
.data

# stuff here
# node struct:
# struct Node {
#     char name[4] // name of this node
#     int out[32]  // outgoing edges (assume max 32)
#     int outcount // number of outgoing edges
# }

# Assume a maximum of 2000 nodes:
.align 2
nodes: .space 272000 # this is 136 bytes (sizeof Node) * 2000
nodec: .word 0 # number of nodes, global variable

# memo array: 64 bit values, hi=0xFFFFFFFF means not computed yet
.align 2
memo: .space 16000 # memoisation array, 8 bytes (word) per node in (lo, hi) format

.align 2
file_buffer: .space 16384 # 16kb region to read the input file into
line_buffer: .space 256 # buffer to hold each line 

# string constants:
svr_str: .asciiz "svr"
out_str: .asciiz "out"
fft_str: .asciiz "fft"
dac_str: .asciiz "dac"
newline: .asciiz "\n"



#! ========== Program ============
.text
.globl main

main:
    # allocate 60 bytes for intermediate values
    addi $sp, $sp, -60# todo: can reduce this maybe?
    
    # save and check argc:
    move $s2, $a0
    blt $s2, 1, main_exit

    # get filename:
    lw $a0, 0($a1) # $a0 = (char*)filename

    # open file:
    move $a1, $0 # readonly flag
    move $a2, $0
    addi $v0, $0, 13 # syscall to open file
    syscall

    # check file open:
    bltz $v0, main_exit # if open fails, $v0 is negative
    move $s0, $v0 # save FILE* pointer in $s0

    # read entire file into buffer:
    move $a0, $s0
    la $a1, file_buffer
    addi $a2, $0, 16383 # maximum bytes to read
    addi $v0, $0, 14
    syscall

    # save the number of bytes read:
    move $s1, $v0

    # add a null terminator:
    la $t0, file_buffer
    add $t0, $t0, $s1
    sb $0, 0($t0)

    # close the file:
    move $a0, $s0
    addi $v0, $0, 16
    syscall



    # parse the file:
    la $a0, file_buffer
    jal parse_file

    # find node indices
    la $a0, svr_str
    jal find_node
    move $s0, $v0 # s0 = svr


    la $a0, out_str
    jal find_node
    move $s1, $v0 # s1 = out

    la $a0, dac_str
    jal find_node
    move $s2, $v0 # s2 = dac

    la $a0, fft_str
    jal find_node
    move $s3, $v0 # s3 = fft

    # check all found
    bltz $s0, main_exit
    bltz $s1, main_exit
    bltz $s2, main_exit
    bltz $s3, main_exit

    # Case 1: dac before fft
    # paths(svr,dac) * paths(dac,fft) * paths(fft,out)

    # paths(svr, dac)
    jal reset_memo
    move $a0, $s0
    move $a1, $s2
    jal dfs
    sw $v0, 0($sp) # p1_lo
    sw $v1, 4($sp) # p1_hi

    # paths(dac, fft)
    jal reset_memo
    move $a0, $s2
    move $a1, $s3
    jal dfs
    sw $v0, 8($sp) # p2_lo
    sw $v1, 12($sp) # p2_hi

    # paths(fft, out)
    jal reset_memo
    move $a0, $s3
    move $a1, $s1
    jal dfs
    sw $v0, 16($sp) # p3_lo
    sw $v1, 20($sp) # p3_hi

    # case1 = p1 * p2 * p3 (64-bit)
    lw $a0, 0($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    lw $a3, 12($sp)
    jal mul64
    move $s4, $v0 # temp_lo
    move $s5, $v1 # temp_hi

    move $a0, $s4
    move $a1, $s5
    lw $a2, 16($sp)
    lw $a3, 20($sp)
    jal mul64
    sw $v0, 24($sp) # case1_lo
    sw $v1, 28($sp) # case1_hi



    # Case 2: fft before dac
    # paths(svr,fft) * paths(fft,dac) * paths(dac,out)

    # paths(svr, fft)
    jal reset_memo
    move $a0, $s0
    move $a1, $s3
    jal dfs
    sw $v0, 32($sp) # p4_lo
    sw $v1, 36($sp) # p4_hi

    # paths(fft, dac)
    jal reset_memo
    move $a0, $s3
    move $a1, $s2
    jal dfs
    sw $v0, 40($sp) # p5_lo
    sw $v1, 44($sp) # p5_hi

    # paths(dac, out)
    jal reset_memo
    move $a0, $s2
    move $a1, $s1
    jal dfs
    sw $v0, 48($sp) # p6_lo
    sw $v1, 52($sp) # p6_hi

    # case2 = p4 * p5 * p6
    lw $a0, 32($sp)
    lw $a1, 36($sp)
    lw $a2, 40($sp)
    lw $a3, 44($sp)
    jal mul64
    move $s4, $v0
    move $s5, $v1

    move $a0, $s4
    move $a1, $s5
    lw $a2, 48($sp)
    lw $a3, 52($sp)
    jal mul64
    move $s6, $v0 # case2_lo
    move $s7, $v1 # case2_hi

    # result = case1 + case2 (64-bit add)
    lw $t0, 24($sp) # case1_lo
    lw $t1, 28($sp) # case1_hi
    addu $a0, $t0, $s6 # result_lo
    sltu $t2, $a0, $t0 # carry
    addu $a1, $t1, $s7
    addu $a1, $a1, $t2 # result_hi

    # Print 64-bit result
    jal print64

    # print newline
    la $a0, newline
    li $v0, 4
    syscall


    addi $sp, $sp, 60
    li $v0, 10
    syscall

    # exit program:
    main_exit:
        addi $v0, $0, 10
    syscall















# reset memo array - set hi word to -1 = 0xFFFFFFFF (key for uncomputed)
reset_memo:
    la $t0, memo
    li $t2, 2000
    _reset_loop:
        beqz $t2, _reset_done
        sw $0, 0($t0) # lo = 0
        li $t1, -1
        sw $t1, 4($t0) # hi = -1
        addi $t0, $t0, 8
        addi $t2, $t2, -1
        j _reset_loop
    _reset_done:
        jr $ra

# mul64: 64-bit multiply (a0,a1) * (a2,a3) -> (v0,v1)
# Uses: (a_lo + a_hi*2^32) * (b_lo + b_hi*2^32)
#     = a_lo*b_lo + (a_lo*b_hi + a_hi*b_lo)*2^32 (ignore overflow beyond 64 bits, if that happens the opps deserve the win)
mul64:
    # a_lo * b_lo -> full 64-bit result
    multu $a0, $a2
    mflo $v0 # result_lo
    mfhi $v1 # result_hi (from low*low)

    # a_lo * b_hi -> add to high word
    multu $a0, $a3
    mflo $t0
    addu $v1, $v1, $t0

    # a_hi * b_lo -> add to high word
    multu $a1, $a2
    mflo $t0
    addu $v1, $v1, $t0

    jr $ra

# print64: print unsigned 64-bit integer passed in as ($a0=lo, $a1=hi)
# use repeated division by 10
print64:
    addi $sp, $sp, -48
    sw $ra, 44($sp)
    sw $s0, 40($sp)
    sw $s1, 36($sp)
    sw $s2, 32($sp)
    sw $s3, 28($sp)
    # buffer at 0-24($sp)

    move $s0, $a0 # lo
    move $s1, $a1 # hi
    li $s2, 0 # digit count
    addi $s3, $sp, 0 # buffer pointer

    # Special case for zero
    or $t0, $s0, $s1
    bnez $t0, _p64_loop
    li $a0, '0'
    li $v0, 11
    syscall
    j _p64_done

    _p64_loop:
        # Check if number is zero
        or $t0, $s0, $s1
        beqz $t0, _p64_print

        # Divide 64-bit by 10, get remainder
        # Use repeated subtraction/shift method for 64-bit division
        li $a0, 10
        move $a1, $s0 # dividend lo
        move $a2, $s1 # dividend hi
        jal div64by32

        move $s0, $v0 # quotient lo
        move $s1, $v1 # quotient hi
        # $a3 = remainder (0-9)

        addi $t0, $a3, '0'
        sb $t0, 0($s3)
        addi $s3, $s3, 1
        addi $s2, $s2, 1
        j _p64_loop

    _p64_print:
    _p64_ploop:
        beqz $s2, _p64_done
        addi $s3, $s3, -1
        lb $a0, 0($s3)
        li $v0, 11 # print char
        syscall
        addi $s2, $s2, -1
        j _p64_ploop

    _p64_done:
        lw $ra, 44($sp)
        lw $s0, 40($sp)
        lw $s1, 36($sp)
        lw $s2, 32($sp)
        lw $s3, 28($sp)
        addi $sp, $sp, 48
        jr $ra






# div64by32: divide 64-bit (a1=lo, a2=hi) by 32-bit (a0)
# Returns quotient in (v0=lo, v1=hi), remainder in $a3
div64by32:
    # High part first
    divu $a2, $a0
    mflo $v1 # quotient_hi
    mfhi $t0 # remainder from high

    # Combine remainder with low part
    # remainder * 2^32 + a1, then divide by a0
    # Use: r*2^32 + lo = (r * 2^32 / divisor) + lo/divisor (with carry)

    # temp = (remainder << 16) | (a1 >> 16)
    sll $t1, $t0, 16
    srl $t2, $a1, 16
    or $t1, $t1, $t2
    divu $t1, $a0
    mflo $t3 # partial quotient (upper 16 bits of quo_lo)
    mfhi $t4 # new remainder

    # temp = (remainder << 16) | (a1 & 0xFFFF)
    sll $t1, $t4, 16
    andi $t2, $a1, 0xFFFF
    or $t1, $t1, $t2
    divu $t1, $a0
    mflo $t5 # partial quotient (lower 16 bits of quo_lo)
    mfhi $a3 # final remainder

    # Combine partial quotients
    sll $v0, $t3, 16
    or $v0, $v0, $t5

    jr $ra























parse_file:
    # store $s registers and $ra:
    addi $sp, $sp, -32
    sw $ra, 28($sp)
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    sw $s2, 16($sp)
    sw $s3, 12($sp)
    sw $s4, 8($sp)
    sw $s5, 4($sp)
    sw $s6, 0($sp)

    move $s0, $a0


    parse_line_loop:
        # check if reached end:
        lb $t0, 0($s0)
        beqz $t0, parse_done

        # skip empty lines or lines less than 4 characters:
        move $t1, $s0
        li $t2, 0 # line length

    count_line_len:
        lb $t3, 0($t1)
        beqz $t3, check_line_len
        addi $t4, $0, 10 # '\n' = 10
        beq $t3, $t4, check_line_len
        addi $t1, $t1, 1
        addi $t2, $t2, 1
        j count_line_len
    
    check_line_len:
        blt $t2, 4, skip_to_next_line

        # get source node name:
        move $a0, $s0
        jal find_or_add
        move $s1, $v0 # s1 = source node index

        # find the ':' in line:
        move $t0, $s0

    find_colon:
        lb $t1, 0($t0)
        beqz $t1, skip_to_next_line
        addi $t2, $0, 10
        beq $t1, $t2, skip_to_next_line
        addi $t2, $0, 58 # ':' = 58
        beq $t1, $t2, found_colon
        addi $t0, $t0, 1
        j find_colon
    
    found_colon:
        addi $t0, $t0, 1 # skip the ':'
        move $s2, $t0 # s2 contains position AFTER ':'
    
    parse_neighbours:
        # skip the whitespace:
        skip_ws:
            lb $t1, 0($s2)
            beqz $t1, skip_to_next_line
            li $t2, 10
            beq $t1, $t2, skip_to_next_line
            addi $t2, $0, 32 # ' '(whitespace) is 32
            beq $t1, $t2, skip_ws_cont
            addi $t2, $0, 9 # '\t' = 9
            beq $t1, $t2, skip_ws_cont
            j check_neighbour_valid
        skip_ws_cont:
            addi $s2, $s2, 1
            j skip_ws

        check_neighbour_valid:
            # check we have at least 3 chars:
            lb $t1, 0($s2)
            beqz $t1, skip_to_next_line
            lb $t1, 1($s2)
            beqz $t1, skip_to_next_line
            lb $t1, 2($s2)
            beqz $t1, skip_to_next_line

            # get neighbour node:
            move $a0, $s2
            jal find_or_add
            move $s3, $v0  # s3 = neighbour node index

            # add edge:
            addi $t0, $0, 136
            mul $t0, $s1, $t0
            la $t1, nodes
            add $t1, $t1, $t0 # t1 = address of nodes[s1]

            # get out_count
            lw $t2, 132($t1)

            # store neighbour index
            sll $t3, $t2, 2
            addi $t3, $t3, 4
            add $t3, $t1, $t3
            sw $s3, 0($t3)

            # increment out_count
            addi $t2, $t2, 1
            sw $t2, 132($t1)

            # move to next potential neighbour
            addi $s2, $s2, 3
            j parse_neighbours
    skip_to_next_line:
        find_eol:
            lb $t0, 0($s0)
            beqz $t0, parse_done
            addi $t1, $0, 10
            beq $t0, $t1, at_eol
            addi $s0, $s0, 1
            j find_eol
        at_eol:
            addi $s0, $s0, 1 # skip newline
            j parse_line_loop
    parse_done:
        lw $ra, 28($sp)
        lw $s0, 24($sp)
        lw $s1, 20($sp)
        lw $s2, 16($sp)
        lw $s3, 12($sp)
        lw $s4, 8($sp)
        lw $s5, 4($sp)
        lw $s6, 0($sp)
        addi $sp, $sp, 32
        jr $ra

# finds a node by name or adds it
# $a0 = pointer to name (3 character string)
# return $v0 = index of node
find_or_add:
    # preserve $s registers:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)

    move $s0, $a0

    # load 3 characters:
    lb $s1, 0($s0)
    lb $s2, 1($s0)
    lb $s3, 2($s0)

    # search existing nodes:
    lw $t0, nodec
    move $t1, $0
    la $t2, nodes

    find_loop:
        bge $t1, $t0, not_found

        # load node[i] name:
        lb $t3, 0($t2)
        lb $t4, 1($t2)
        lb $t5, 2($t2)

        # compare strings:
        bne $t3, $s1, find_next
        bne $t4, $s2, find_next
        bne $t5, $s3, find_next

        # found -> return i:
        move $v0, $t1
        j find_or_add_done

    find_next:
        addi $t1, $t1, 1
        addi $t2, $t2, 136
        j find_loop

    not_found:
        # add new node:
        # address= nodes + nodecount * sizeof(node)
        lw $t0, nodec
        addi $t1, $0, 136
        mul $t1, $t0, $t1
        la $t2, nodes
        add $t2, $t2, $t1

        # copy name:
        sb $s1, 0($t2)
        sb $s2, 1($t2)
        sb $s3, 2($t2)
        sb $0, 3($t2)

        # initialise outcount to 0:
        sw $0, 132($t2)

        # increment and return nodec 
        move $v0, $t0
        addi $t0, $t0, 1
        sw $t0, nodec
    
    find_or_add_done:
        lw $ra, 16($sp)
        lw $s0, 12($sp)
        lw $s1, 8($sp)
        lw $s2, 4($sp)
        lw $s3, 0($sp)
        addi $sp, $sp, 20
        jr $ra


# find node by exact name string
# $a0 = pointer to asciiz string of name (3 chars + '\0')
# returns $v0 = node index, or -1 if not found
find_node:
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)

    move $s0, $a0

    # load 3 chars to compare:
    lb $s1, 0($s0)
    lb $t6, 1($s0)
    lb $t7, 2($s0) # 67 funny haha

    # search existing nodes:
    lw $t0, nodec
    li $t1, 0
    la $t2, nodes

    find_node_loop:
        bge $t1, $t0, find_node_not_found

        # load node name:
        lb $t3, 0($t2)
        lb $t4, 1($t2)
        lb $t5, 2($t2)

        # compare:
        bne $t3, $s1, find_node_next
        bne $t4, $t6, find_node_next
        bne $t5, $t7, find_node_next

        # found -> return i:
        move $v0, $t1
        j find_node_done
    
    find_node_next:
        addi $t1, $t1, 1
        addi $t2, $t2, 136
        j find_node_loop

    find_node_not_found:
        addi $v0, $0, -1

    find_node_done:
        lw $ra, 8($sp)
        lw $s0, 4($sp)
        lw $s1, 0($sp)
        addi $sp, $sp, 12
        jr $ra



# dfs counting paths (64-bit, pure memoization, assumes DAG)
# $a0 = current node (u)
# $a1 = target
# returns ($v0, $v1) = 64-bit number of paths from u to target
dfs:
    addi $sp, $sp, -36
    sw $ra, 32($sp)
    sw $s0, 28($sp)
    sw $s1, 24($sp)
    sw $s2, 20($sp) # sum_lo
    sw $s3, 16($sp) # sum_hi
    sw $s4, 12($sp) # node address
    sw $s5, 8($sp) # outcount
    sw $s6, 4($sp) # loop counter

    move $s0, $a0 # s0 = u
    move $s1, $a1 # s1 = target

    # base case: u == target -> 1 path
    beq $s0, $s1, dfs_return_one

    # check memo
    la $t0, memo
    sll $t1, $s0, 3
    add $t0, $t0, $t1
    lw $t2, 0($t0)
    lw $t3, 4($t0)
    li $t4, -1
    bne $t3, $t4, dfs_return_memo  # if hi != -1, memoized

    # compute: sum paths from all neighbours
    move $s2, $0 # sum = 0
    move $s3, $0

    # get node address
    li $t0, 136
    mul $t0, $s0, $t0
    la $t1, nodes
    add $s4, $t1, $t0 # s4 = &nodes[u]

    lw $s5, 132($s4) # s5 = outcount
    li $s6, 0 # i = 0

    dfs_loop:
        bge $s6, $s5, dfs_loop_done

        # get neighbour v = out[i]
        sll $t0, $s6, 2
        addi $t0, $t0, 4
        add $t0, $s4, $t0
        lw $a0, 0($t0)

        move $a1, $s1
        jal dfs

        # 64-bit add: sum += result
        addu $t0, $s2, $v0 # new sum_lo
        sltu $t1, $t0, $s2 # carry if overflow
        addu $t2, $s3, $v1 # sum_hi + result_hi
        addu $s3, $t2, $t1 # add carry
        move $s2, $t0

        addi $s6, $s6, 1
        j dfs_loop

    dfs_loop_done:
        # store in memo
        la $t0, memo
        sll $t1, $s0, 3
        add $t0, $t0, $t1
        sw $s2, 0($t0) # lo
        sw $s3, 4($t0) # hi

        move $v0, $s2
        move $v1, $s3
        j dfs_done

    dfs_return_memo:
        move $v0, $t2
        move $v1, $t3
        j dfs_done

    dfs_return_one:
        li $v0, 1
        li $v1, 0

    dfs_done:
        lw $ra, 32($sp)
        lw $s0, 28($sp)
        lw $s1, 24($sp)
        lw $s2, 20($sp)
        lw $s3, 16($sp)
        lw $s4, 12($sp)
        lw $s5, 8($sp)
        lw $s6, 4($sp)
        addi $sp, $sp, 36
        jr $ra
