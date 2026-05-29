# =============================================================================
# reset.asm  --  SSD 전체 초기화
#
# reset_ssd 는 다음을 순서대로 초기화한다:
#   1. nand table (pba_state, pba_data)
#   2. mapping table (lba_map)
#   3. block table (block_erase_count)
#   4. statistics
#   5. trace log
#   6. trace에 RESET 이벤트 기록
# =============================================================================

        .text

# -----------------------------------------------------------------------------
# reset_ssd
#   역할  : SSD 전체 상태를 초기 상태로 되돌린다
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
reset_ssd:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_reset_start
        jal   print_string

        jal   reset_nand_table
        jal   reset_mapping_table
        jal   reset_block_table
        jal   reset_statistics
        jal   reset_trace_log

        # reset 이후 trace에 RESET 이벤트 남기기
        jal   log_reset_event

        la    $a0, msg_reset_done
        jal   print_string

        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

# -----------------------------------------------------------------------------
# reset_statistics
#   역할  : 모든 통계 변수를 0으로 초기화하고 free_page_count를 8로 설정
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
reset_statistics:
        sw    $zero, total_write_count
        sw    $zero, total_read_count
        sw    $zero, total_state_count
        sw    $zero, total_simulated_time
        sw    $zero, invalid_page_count
        sw    $zero, gc_count

        li    $t0, 8               # PBA_COUNT = 8
        sw    $t0, free_page_count

        jr    $ra
