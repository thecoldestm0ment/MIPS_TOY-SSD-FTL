# =============================================================================
# ftl_read.asm  --  Read 처리
#
# 함수 구조:
#   submit_read_request  : 사용자에게서 LBA 입력받아 ftl_read_core 호출
#   ftl_read_core        : $a0=LBA 를 받아 실제 read 수행
# =============================================================================

        .text

# -----------------------------------------------------------------------------
# submit_read_request
#   역할  : 사용자로부터 LBA를 입력받아 ftl_read_core를 호출한다
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
submit_read_request:
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)
        sw    $s0, 0($sp)

        la    $a0, msg_read_lba
        jal   print_string
        jal   read_int
        move  $s0, $v0

        move  $a0, $s0
        jal   check_lba_range
        beqz  $v0, srr_bad

        move  $a0, $s0
        jal   ftl_read_core
        j     srr_done

srr_bad:
        la    $a0, msg_lba_range
        jal   print_string

srr_done:
        lw    $ra, 4($sp)
        lw    $s0, 0($sp)
        addiu $sp, $sp, 8
        jr    $ra

# -----------------------------------------------------------------------------
# ftl_read_core
#   역할  : LBA를 받아 매핑 테이블에서 PBA를 찾고 데이터를 읽어 출력한다
#           1) lba_map[lba] 조회
#           2) -1 이면 "No data" 출력
#           3) pba_data[pba] 읽어 출력
#           4) read count 증가, trace 기록
#   입력  : $a0 = LBA (범위 검사는 호출 전에 완료된 것으로 가정)
#   출력  : 없음
# -----------------------------------------------------------------------------
ftl_read_core:
        addiu $sp, $sp, -12
        sw    $ra,  8($sp)
        sw    $s0,  4($sp)
        sw    $s1,  0($sp)

        move  $s0, $a0             # $s0 = lba

        la    $a0, msg_read_lba_p
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        # 매핑 조회
        move  $a0, $s0
        jal   get_lba_mapping
        move  $s1, $v0             # $s1 = pba

        li    $t0, -1
        beq   $s1, $t0, frc_no_data

        # "Mapped PBA: X"
        la    $a0, msg_mapped_pba
        jal   print_string
        move  $a0, $s1
        jal   print_int
        jal   print_newline

        # pba_data[pba] 읽기
        move  $a0, $s1
        jal   get_pba_data

        la    $a0, msg_data_val
        jal   print_string
        move  $s0, $v0             # 잠시 data 보관 ($s0 재사용)
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        # 통계 & trace
        lw    $t0, total_read_count
        addiu $t0, $t0, 1
        sw    $t0, total_read_count

        # log_read_event(original_lba, pba, data)
        lw    $t1, 4($sp)          # 원래 $s0 (lba)
        move  $a0, $t1
        move  $a1, $s1
        move  $a2, $s0             # data
        jal   log_read_event

        j     frc_done

frc_no_data:
        la    $a0, msg_no_data
        jal   print_string

frc_done:
        lw    $ra,  8($sp)
        lw    $s0,  4($sp)
        lw    $s1,  0($sp)
        addiu $sp, $sp, 12
        jr    $ra
