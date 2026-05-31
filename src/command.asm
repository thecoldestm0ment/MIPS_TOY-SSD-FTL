# 메뉴용 래퍼 함수

        .text
        .globl cmd_write, cmd_read
        .globl cmd_print_mapping, cmd_print_physical
        .globl cmd_print_stats
        .globl cmd_print_trace, cmd_full_status
        .globl cmd_demo, cmd_reset, cmd_gc

cmd_write:                          # 쓰기 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   submit_write_request
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_read:                           # 읽기 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   submit_read_request
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_print_mapping:                  # 매핑 테이블 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   print_mapping_table
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_print_physical:                 # 물리 페이지 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   print_physical_page_table
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_print_stats:                    # 통계 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   print_statistics
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_print_trace:                    # Trace 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   print_trace_log
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_full_status:                    # 전체 상태 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   print_full_status
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_demo:                           # demo 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   run_demo_scenario
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_reset:                          # reset 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   reset_ssd
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_gc:                             # GC 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   run_simple_gc
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀
