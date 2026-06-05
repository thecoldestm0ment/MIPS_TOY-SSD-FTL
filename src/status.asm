# 통계와 상태 출력

        .text

count_valid_pages:                  # VALID page 개수를 셈
        li    $t0, 0                # i = 0
        li    $t1, 8                # PBA 개수
        la    $t2, pba_state        # 상태 배열 시작 주소
        li    $v0, 0                # count = 0

cvp_loop:                           # pba_state[i] 확인
        bge   $t0, $t1, cvp_done

        sll   $t3, $t0, 2           # offset = i * 4
        add   $t4, $t2, $t3         # &pba_state[i]
        lw    $t5, 0($t4)           # pba_state[i]

        li    $t6, 1                # VALID 값
        bne   $t5, $t6, cvp_next
        addiu $v0, $v0, 1           # VALID면 count++

cvp_next:                           # 다음 page로 이동
        addiu $t0, $t0, 1           # i++
        j     cvp_loop

cvp_done:                           # 계산 끝
        jr    $ra                   # 호출한 곳으로 복귀

print_page_state_summary:           # FREE, VALID, INVALID 요약 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_ps_hdr       # 헤더 출력
        jal   print_string

        la    $a0, msg_ps_free      # FREE 개수 출력
        jal   print_string
        lw    $a0, free_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_ps_valid     # VALID 개수 출력
        jal   print_string
        jal   count_valid_pages
        move  $a0, $v0
        jal   print_int
        jal   print_newline

        la    $a0, msg_ps_invalid   # INVALID 개수 출력
        jal   print_string
        lw    $a0, invalid_page_count
        jal   print_int
        jal   print_newline

        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

print_statistics:                   # 누적 통계 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_stats_hdr    # 헤더 출력
        jal   print_string

        la    $a0, msg_st_writes    # WRITE 수 출력
        jal   print_string
        lw    $a0, total_write_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_reads     # READ 수 출력
        jal   print_string
        lw    $a0, total_read_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_states    # 상태 실행 수 출력
        jal   print_string
        lw    $a0, total_state_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_time      # 누적 시간 출력
        jal   print_string
        lw    $a0, total_simulated_time
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_free      # FREE page 수 출력
        jal   print_string
        lw    $a0, free_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_valid     # VALID page 수 출력
        jal   print_string
        jal   count_valid_pages
        move  $a0, $v0
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_inv       # INVALID page 수 출력
        jal   print_string
        lw    $a0, invalid_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_gc        # GC 횟수 출력
        jal   print_string
        lw    $a0, gc_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_erase
        jal   print_string
        lw    $a0, erase_count
        jal   print_int
        jal   print_newline

        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

print_full_status:                  # 전체 상태를 한 번에 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_full_hdr     # 전체 상태 헤더
        jal   print_string

        jal   print_statistics
        jal   print_separator

        jal   print_page_state_summary
        jal   print_separator

        jal   print_mapping_table
        jal   print_separator

        jal   print_physical_page_table
        jal   print_separator

        jal   print_trace_log

        la    $a0, msg_full_end     # 전체 상태 끝 표시
        jal   print_string

        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

