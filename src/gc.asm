# Block erase GC

        .text

run_simple_gc:                      # erase blocks that have INVALID pages and no VALID pages
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)
        sw    $s0, 8($sp)           # total freed pages
        sw    $s1, 4($sp)           # erased block count
        sw    $s2, 0($sp)           # current block

        la    $a0, msg_gc_block_start
        jal   print_string

        li    $s0, 0                # total_freed = 0
        li    $s1, 0                # erased_blocks = 0
        li    $s2, 0                # block = 0

gc_block_loop:
        li    $t0, BLOCK_COUNT
        bge   $s2, $t0, gc_done

        li    $t1, BLOCK_SIZE
        mul   $t2, $s2, $t1         # start_pba = block * BLOCK_SIZE
        add   $t3, $t2, $t1         # end_pba = start_pba + BLOCK_SIZE
        move  $t4, $t2              # pba = start_pba
        li    $t5, 0                # has_valid = 0
        li    $t6, 0                # invalid_count = 0

gc_scan_loop:
        bge   $t4, $t3, gc_scan_done

        la    $t7, pba_state
        sll   $t8, $t4, 2
        add   $t7, $t7, $t8
        lw    $t9, 0($t7)

        li    $t0, VALID
        beq   $t9, $t0, gc_mark_valid

        li    $t0, INVALID
        bne   $t9, $t0, gc_scan_next
        addiu $t6, $t6, 1           # invalid_count++
        j     gc_scan_next

gc_mark_valid:
        li    $t5, 1                # has_valid = 1

gc_scan_next:
        addiu $t4, $t4, 1
        j     gc_scan_loop

gc_scan_done:
        bnez  $t5, gc_next_block    # keep blocks that contain valid data
        beqz  $t6, gc_next_block    # nothing to reclaim

        la    $a0, msg_gc_erase_block
        jal   print_string
        move  $a0, $s2
        jal   print_int
        la    $a0, msg_gc_block_free
        jal   print_string

        li    $t1, BLOCK_SIZE
        mul   $t2, $s2, $t1         # start_pba = block * BLOCK_SIZE
        add   $t3, $t2, $t1         # end_pba
        move  $t4, $t2

gc_erase_loop:
        bge   $t4, $t3, gc_erase_done

        sll   $t8, $t4, 2

        la    $t7, pba_state
        add   $t7, $t7, $t8
        sw    $zero, 0($t7)         # pba_state[pba] = FREE

        la    $t7, pba_data
        add   $t7, $t7, $t8
        sw    $zero, 0($t7)         # pba_data[pba] = 0

        addiu $t4, $t4, 1
        j     gc_erase_loop

gc_erase_done:
        add   $s0, $s0, $t6         # total_freed += invalid_count
        addiu $s1, $s1, 1           # erased_blocks++

        lw    $t0, free_page_count
        add   $t0, $t0, $t6
        sw    $t0, free_page_count

        lw    $t0, invalid_page_count
        sub   $t0, $t0, $t6
        sw    $t0, invalid_page_count

gc_next_block:
        addiu $s2, $s2, 1
        j     gc_block_loop

gc_done:
        lw    $t0, gc_count
        addiu $t0, $t0, 1
        sw    $t0, gc_count

        lw    $t0, erase_count
        add   $t0, $t0, $s1
        sw    $t0, erase_count

        la    $a0, msg_gc_freed
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        la    $a0, msg_gc_done
        jal   print_string

        move  $a0, $s0
        jal   log_gc_event

        lw    $ra, 12($sp)
        lw    $s0, 8($sp)
        lw    $s1, 4($sp)
        lw    $s2, 0($sp)
        addiu $sp, $sp, 16
        jr    $ra
