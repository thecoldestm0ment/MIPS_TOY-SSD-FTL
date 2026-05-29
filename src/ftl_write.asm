# =============================================================================
# ftl_write.asm  --  Write 처리
#
# out-of-place update:
#   SSD에서는 같은 LBA에 다시 쓸 때 기존 물리 페이지를 덮어쓰지 않는다.
#   대신 새 FREE 페이지를 할당하고, 기존 페이지는 INVALID로 표시한다.
#   이렇게 해야 NAND의 쓰기 내구성을 보호하고, GC가 회수할 대상을 추적할 수 있다.
#
# 함수 구조:
#   submit_write_request  : 사용자에게서 LBA / data 입력받아 ftl_write_core 호출
#   ftl_write_core        : $a0=LBA, $a1=data 를 받아 실제 write 수행
# =============================================================================

        .text

# -----------------------------------------------------------------------------
# submit_write_request
#   역할  : 사용자로부터 LBA와 data를 입력받아 ftl_write_core를 호출한다
#   입력  : 없음 (직접 read_int)
#   출력  : 없음
# -----------------------------------------------------------------------------
submit_write_request:
        addiu $sp, $sp, -12
        sw    $ra, 8($sp)
        sw    $s0, 4($sp)
        sw    $s1, 0($sp)

        la    $a0, msg_write_lba
        jal   print_string
        jal   read_int
        move  $s0, $v0             # $s0 = lba

        # LBA 범위 검사
        move  $a0, $s0
        jal   check_lba_range
        beqz  $v0, swr_bad_lba

        la    $a0, msg_write_data
        jal   print_string
        jal   read_int
        move  $s1, $v0             # $s1 = data

        # ftl_write_core($s0, $s1)
        move  $a0, $s0
        move  $a1, $s1
        jal   ftl_write_core

        j     swr_done

swr_bad_lba:
        la    $a0, msg_lba_range
        jal   print_string

swr_done:
        lw    $ra, 8($sp)
        lw    $s0, 4($sp)
        lw    $s1, 0($sp)
        addiu $sp, $sp, 12
        jr    $ra

# -----------------------------------------------------------------------------
# ftl_write_core
#   역할  : LBA와 data를 받아 FTL write를 수행한다
#           1) 기존 매핑 확인
#           2) 기존 PBA가 있으면 INVALID 처리
#           3) FREE PBA 탐색
#           4) 새 PBA를 VALID 처리, data 저장, mapping 갱신
#           5) 통계 갱신, trace 기록
#   입력  : $a0 = LBA, $a1 = data
#   출력  : 없음
#   주의  : $s0=lba, $s1=data, $s2=old_pba, $s3=new_pba 로 사용
# -----------------------------------------------------------------------------
ftl_write_core:
        addiu $sp, $sp, -20
        sw    $ra, 16($sp)
        sw    $s0, 12($sp)
        sw    $s1,  8($sp)
        sw    $s2,  4($sp)
        sw    $s3,  0($sp)

        move  $s0, $a0             # lba
        move  $s1, $a1             # data

        # 진행 메시지 출력
        la    $a0, msg_sel_lba
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        # 기존 매핑 조회
        move  $a0, $s0
        jal   get_lba_mapping
        move  $s2, $v0             # $s2 = old_pba

        li    $t0, -1
        beq   $s2, $t0, fwc_no_old   # old_pba == -1 이면 첫 write

        # 기존 PBA를 INVALID 처리
        la    $a0, msg_old_pba
        jal   print_string
        move  $a0, $s2
        jal   print_int
        jal   print_newline

        la    $a0, msg_pba_inv_a
        jal   print_string
        move  $a0, $s2
        jal   print_int
        la    $a0, msg_pba_inv_b
        jal   print_string

        move  $a0, $s2
        li    $a1, 2               # INVALID
        jal   set_pba_state

        # free_page_count--, invalid_page_count++
        lw    $t0, free_page_count
        addiu $t0, $t0, -1
        sw    $t0, free_page_count

        lw    $t0, invalid_page_count
        addiu $t0, $t0, 1
        sw    $t0, invalid_page_count

        j     fwc_find_free

fwc_no_old:
        la    $a0, msg_no_old_map
        jal   print_string

fwc_find_free:
        # FREE PBA 탐색
        jal   find_free_pba
        move  $s3, $v0             # $s3 = new_pba

        li    $t0, -1
        beq   $s3, $t0, fwc_no_free

        # 새 PBA에 VALID 처리, data 저장, mapping 갱신
        move  $a0, $s3
        li    $a1, 1               # VALID
        jal   set_pba_state

        move  $a0, $s3
        move  $a1, $s1
        jal   set_pba_data

        move  $a0, $s0
        move  $a1, $s3
        jal   set_lba_mapping

        # 통계: write_count++, free_page_count--
        lw    $t0, total_write_count
        addiu $t0, $t0, 1
        sw    $t0, total_write_count

        lw    $t0, free_page_count
        addiu $t0, $t0, -1
        sw    $t0, free_page_count

        # 결과 출력: "New PBA allocated: X"
        la    $a0, msg_new_pba
        jal   print_string
        move  $a0, $s3
        jal   print_int
        jal   print_newline

        # "LBA X -> PBA Y, data = Z"
        la    $a0, msg_lba_prefix
        jal   print_string
        move  $a0, $s0
        jal   print_int
        la    $a0, msg_arrow_pba
        jal   print_string
        move  $a0, $s3
        jal   print_int
        la    $a0, msg_data_eq
        jal   print_string
        move  $a0, $s1
        jal   print_int
        jal   print_newline

        # trace 기록: log_write_event(lba, new_pba, data)
        move  $a0, $s0
        move  $a1, $s3
        move  $a2, $s1
        jal   log_write_event

        # run_state: 1ms sleep
        la    $a0, msg_write_ok
        li    $a1, 1
        jal   run_state

        j     fwc_done

fwc_no_free:
        la    $a0, msg_no_free
        jal   print_string

fwc_done:
        lw    $ra, 16($sp)
        lw    $s0, 12($sp)
        lw    $s1,  8($sp)
        lw    $s2,  4($sp)
        lw    $s3,  0($sp)
        addiu $sp, $sp, 20
        jr    $ra
