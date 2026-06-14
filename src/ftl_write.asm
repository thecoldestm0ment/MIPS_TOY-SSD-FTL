# 쓰기 처리

        .text

submit_write_request:               # 입력받은 LBA/data로 write core 호출
        addiu $sp, $sp, -12
        sw    $ra, 8($sp)
        sw    $s0, 4($sp)
        sw    $s1, 0($sp)

        la    $a0, msg_write_lba
        jal   print_string
        jal   read_int
        move  $s0, $v0

        move  $a0, $s0
        jal   check_lba_range
        beqz  $v0, swr_bad_lba

        la    $a0, msg_write_data
        jal   print_string
        jal   read_int
        move  $s1, $v0

        move  $a0, $s0
        move  $a1, $s1
        jal   ftl_write_core
        j     swr_done

swr_bad_lba:                        # LBA 범위가 잘못된 경우
        la    $a0, msg_lba_range
        jal   print_string

swr_done:                           # 입력 처리 종료
        lw    $ra, 8($sp)
        lw    $s0, 4($sp)
        lw    $s1, 0($sp)
        addiu $sp, $sp, 12
        jr    $ra

ftl_write_core:                     # out-of-place write로 새 PBA에 data 저장
        addiu $sp, $sp, -20
        sw    $ra, 16($sp)
        sw    $s0, 12($sp)          # lba
        sw    $s1,  8($sp)          # data
        sw    $s2,  4($sp)          # old_pba
        sw    $s3,  0($sp)          # new_pba

        move  $s0, $a0
        move  $s1, $a1

        la    $a0, msg_sel_lba
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        move  $a0, $s0              # 기존 mapping 확인
        jal   get_lba_mapping
        move  $s2, $v0

        jal   find_free_pba         # 상태 변경 전에 새 FREE PBA를 먼저 찾음
        move  $s3, $v0

        li    $t0, -1
        beq   $s3, $t0, fwc_no_free # 실패 시 기존 mapping/PBA는 건드리지 않음

        li    $t0, -1
        beq   $s2, $t0, fwc_no_old

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

        move  $a0, $s2              # overwrite이면 old PBA를 INVALID 처리
        li    $a1, INVALID
        jal   set_pba_state
        j     fwc_program_new

fwc_no_old:                         # 처음 쓰는 LBA라면 invalid 처리할 old PBA가 없음
        la    $a0, msg_no_old_map
        jal   print_string

fwc_program_new:                    # 새 PBA에 data를 쓰고 mapping 갱신
        move  $a0, $s3
        li    $a1, VALID
        jal   set_pba_state

        move  $a0, $s3
        move  $a1, $s1
        jal   set_pba_data

        move  $a0, $s0
        move  $a1, $s3
        jal   set_lba_mapping

        jal   recount_page_counts   # 수동 증감 대신 실제 pba_state 기준으로 count 재계산

        lw    $t0, total_write_count
        addiu $t0, $t0, 1
        sw    $t0, total_write_count

        la    $a0, msg_new_pba
        jal   print_string
        move  $a0, $s3
        jal   print_int
        jal   print_newline

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

        move  $a0, $s0
        move  $a1, $s3
        move  $a2, $s1
        jal   log_write_event

        la    $a0, msg_write_ok
        jal   print_string
        j     fwc_done

fwc_no_free:                        # FREE PBA가 없으면 write 실패, trace/count 변경 없음
        la    $a0, msg_no_free
        jal   print_string

fwc_done:                           # 저장한 register 복구 후 종료
        lw    $ra, 16($sp)
        lw    $s0, 12($sp)
        lw    $s1,  8($sp)
        lw    $s2,  4($sp)
        lw    $s3,  0($sp)
        addiu $sp, $sp, 20
        jr    $ra
