# =============================================================================
# status.asm  --  통계 출력, 페이지 상태 요약, Full SSD Status
# =============================================================================

        .text

# -----------------------------------------------------------------------------
# count_valid_pages
#   역할  : pba_state를 순회하여 VALID 페이지 수를 반환한다
#   입력  : 없음
#   출력  : $v0 = VALID 페이지 수
# -----------------------------------------------------------------------------
count_valid_pages:
        li    $t0, 0               # i = 0
        li    $t1, 8               # PBA_COUNT
        la    $t2, pba_state
        li    $v0, 0               # count = 0

cvp_loop:
        bge   $t0, $t1, cvp_done

        sll   $t3, $t0, 2
        add   $t4, $t2, $t3
        lw    $t5, 0($t4)

        li    $t6, 1               # VALID = 1
        bne   $t5, $t6, cvp_next
        addiu $v0, $v0, 1

cvp_next:
        addiu $t0, $t0, 1
        j     cvp_loop

cvp_done:
        jr    $ra

# -----------------------------------------------------------------------------
# print_page_state_summary
#   역할  : FREE / VALID / INVALID 페이지 수를 요약 출력한다
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
print_page_state_summary:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_ps_hdr
        jal   print_string

        la    $a0, msg_ps_free
        jal   print_string
        lw    $a0, free_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_ps_valid
        jal   print_string
        jal   count_valid_pages
        move  $a0, $v0
        jal   print_int
        jal   print_newline

        la    $a0, msg_ps_invalid
        jal   print_string
        lw    $a0, invalid_page_count
        jal   print_int
        jal   print_newline

        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

# -----------------------------------------------------------------------------
# print_statistics
#   역할  : 누적 통계 변수를 출력한다
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
print_statistics:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_stats_hdr
        jal   print_string

        la    $a0, msg_st_writes
        jal   print_string
        lw    $a0, total_write_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_reads
        jal   print_string
        lw    $a0, total_read_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_states
        jal   print_string
        lw    $a0, total_state_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_time
        jal   print_string
        lw    $a0, total_simulated_time
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_free
        jal   print_string
        lw    $a0, free_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_valid
        jal   print_string
        jal   count_valid_pages
        move  $a0, $v0
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_inv
        jal   print_string
        lw    $a0, invalid_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_gc
        jal   print_string
        lw    $a0, gc_count
        jal   print_int
        jal   print_newline

        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

# -----------------------------------------------------------------------------
# print_full_status
#   역할  : statistics, mapping table, physical page table,
#           block table, trace log 를 한 번에 출력한다
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
print_full_status:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_full_hdr
        jal   print_string

        jal   print_statistics
        jal   print_separator

        jal   print_page_state_summary
        jal   print_separator

        jal   print_mapping_table
        jal   print_separator

        jal   print_physical_page_table
        jal   print_separator

        jal   print_block_table
        jal   print_separator

        jal   print_trace_log

        la    $a0, msg_full_end
        jal   print_string

        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra
