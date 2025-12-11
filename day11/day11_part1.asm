# usage: java -jar mars.jar nc sm day11_part1.asm pa input.txt


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

# memo array: -1 = not computed, >= 0 = cached path count
.align 2
memo: .space 8000 # memoisation array, 4 bytes (word) per node

.align 2
file_buffer: .space 16384 # 16kb region to read the input file into
line_buffer: .space 256 # buffer to hold each line 

# string constants:
you_str: .asciiz "you"
out_str: .asciiz "out"
newline: .asciiz "\n"



#! ========== Program ============
.text
.globl main

main:
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

    # find the "you" node index:
    la $a0, you_str
    jal find_node
    move $s0, $v0 # $s0 = index of "you" node

    # find the "out" node index:
    la $a0, out_str
    jal find_node
    move $s1, $v0 # $s1 = index of "out" node

    # check that both were found (exit if not found):
    bltz $s0, main_exit
    bltz $s1, main_exit

    # initialise the memo array to -1 (not computed):
    la $t0, memo
    li $t1, -1
    addi $t2, $0, 2000

    _memo_init_loop:
        beqz $t2, _memo_init_done
        sw $t1, 0($t0)
        addi $t0, $t0, 4
        addi $t2, $t2, -1
        j _memo_init_loop

    _memo_init_done:

    # call DFS:
    move $a0, $s0
    move $a1, $s1
    jal dfs

    # Print results:
    move $a0, $v0
    addi $v0, $0, 1
    syscall

    # print newline:
    la $a0, newline
    addi $v0, $0, 4
    syscall

    # exit program:
    main_exit:
        addi $v0, $0, 10
        syscall






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



# dfs counting paths (pure memoisation, assumes DAG)
# $a0 = current node (u)
# $a1 = target
# returns $v0 = number of paths from u to target
dfs:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)
    sw $s4, 0($sp)

    move $s0, $a0 # s0 = u
    move $s1, $a1 # s1 = target

    # base case: u == target -> 1 path
    beq $s0, $s1, dfs_return_one

    # check memo
    la $t0, memo
    sll $t1, $s0, 2
    add $t0, $t0, $t1
    lw $t2, 0($t0) # memo[u]
    li $t3, -1
    bne $t2, $t3, dfs_return_memo  # if memoised, return it

    # compute: sum paths from all neighbours
    move $s2, $0 # sum = 0

    # get node address
    li $t0, 136
    mul $t0, $s0, $t0
    la $t1, nodes
    add $s3, $t1, $t # s3 = &nodes[u]

    lw $s4, 132($s3) # s4 = outcount
    li $t4, 0 # i = 0

    dfs_loop:
        bge $t4, $s4, dfs_loop_done

        # get neighbour v = out[i]
        sll $t0, $t4, 2
        addi $t0, $t0, 4
        add $t0, $s3, $t0
        lw $a0, 0($t0) # v = nodes[u].out[i]

        # save loop counter (t4 gets clobbered by recursion)
        addi $sp, $sp, -4
        sw $t4, 0($sp)

        move $a1, $s1
        jal dfs

        # restore loop counter
        lw $t4, 0($sp)
        addi $sp, $sp, 4

        add $s2, $s2, $v0 # sum += dfs(v)

        addi $t4, $t4, 1
        j dfs_loop

    dfs_loop_done:
        # store in memo
        la $t0, memo
        sll $t1, $s0, 2
        add $t0, $t0, $t1
        sw $s2, 0($t0)

        move $v0, $s2
        j dfs_done

    dfs_return_memo:
        move $v0, $t2
        j dfs_done

    dfs_return_one:
        li $v0, 1

    dfs_done:
        lw $ra, 20($sp)
        lw $s0, 16($sp)
        lw $s1, 12($sp)
        lw $s2, 8($sp)
        lw $s3, 4($sp)
        lw $s4, 0($sp)
        addi $sp, $sp, 24
        jr $ra
