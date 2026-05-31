# SSD 초기화

        .text

reset_ssd:                          # SSD 상태를 처음으로 돌림
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_reset_start  # reset 시작 메시지
        jal   print_string

        jal   reset_nand_table
        jal   reset_mapping_table
        jal   reset_statistics
        jal   reset_trace_log
        jal   log_reset_event       # reset 이벤트도 Trace에 남김

        la    $a0, msg_reset_done   # reset 완료 메시지
        jal   print_string

        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

reset_statistics:                   # 통계 값을 처음 상태로 돌림
        sw    $zero, total_write_count
        sw    $zero, total_read_count
        sw    $zero, total_state_count
        sw    $zero, total_simulated_time
        sw    $zero, invalid_page_count
        sw    $zero, gc_count

        li    $t0, 8                # 시작할 때는 FREE page가 8개
        sw    $t0, free_page_count

        jr    $ra                   # 호출한 곳으로 복귀
