# 쓰기 처리

        .text

submit_write_request:               # 입력받은 값으로 쓰기 함수 호출
        addiu $sp, $sp, -12
        sw    $ra, 8($sp)           # 복귀 주소
        sw    $s0, 4($sp)           # LBA
        sw    $s1, 0($sp)           # data

        la    $a0, msg_write_lba    # LBA 입력 안내
        jal   print_string
        jal   read_int
        move  $s0, $v0              # 입력된 LBA

        move  $a0, $s0              # 범위 검사할 LBA
        jal   check_lba_range
        beqz  $v0, swr_bad_lba      # 범위 밖이면 에러 출력

        la    $a0, msg_write_data   # data 입력 안내
        jal   print_string
        jal   read_int
        move  $s1, $v0              # 입력된 data

        move  $a0, $s0              # LBA
        move  $a1, $s1              # data
        jal   ftl_write_core
        j     swr_done

swr_bad_lba:                        # 잘못된 LBA 입력
        la    $a0, msg_lba_range
        jal   print_string

swr_done:                           # 입력 처리 끝
        lw    $ra, 8($sp)           # 복귀 주소 복구
        lw    $s0, 4($sp)           # LBA 복구
        lw    $s1, 0($sp)           # data 복구
        addiu $sp, $sp, 12
        jr    $ra                   # 호출한 곳으로 복귀

ftl_write_core:                     # LBA에 data를 쓰고 mapping 갱신
        addiu $sp, $sp, -20
        sw    $ra, 16($sp)          # 복귀 주소
        sw    $s0, 12($sp)          # lba
        sw    $s1,  8($sp)          # data
        sw    $s2,  4($sp)          # old_pba
        sw    $s3,  0($sp)          # new_pba

        move  $s0, $a0              # 현재 LBA
        move  $s1, $a1              # 현재 data

        la    $a0, msg_sel_lba      # 선택한 LBA 출력
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        move  $a0, $s0              # 기존 mapping 확인
        jal   get_lba_mapping
        move  $s2, $v0              # old_pba

        li    $t0, -1
        beq   $s2, $t0, fwc_no_old  # 처음 쓰는 LBA면 바로 새 PBA 찾기

        la    $a0, msg_old_pba      # 이전 PBA 출력
        jal   print_string
        move  $a0, $s2
        jal   print_int
        jal   print_newline

        la    $a0, msg_pba_inv_a    # INVALID 처리 안내
        jal   print_string
        move  $a0, $s2
        jal   print_int
        la    $a0, msg_pba_inv_b
        jal   print_string

        move  $a0, $s2
        li    $a1, 2
        jal   set_pba_state         # old_pba를 INVALID로 바꿈
        lw    $t0, invalid_page_count
        addiu $t0, $t0, 1           # INVALID page 수 증가
        sw    $t0, invalid_page_count

        j     fwc_find_free

fwc_no_old:                         # 처음 쓰는 LBA
        la    $a0, msg_no_old_map
        jal   print_string

fwc_find_free:                      # 새 PBA 찾기
        jal   find_free_pba
        move  $s3, $v0              # new_pba

        li    $t0, -1
        beq   $s3, $t0, fwc_no_free # 빈 PBA가 없으면 종료

        move  $a0, $s3
        li    $a1, 1
        jal   set_pba_state         # new_pba를 VALID로 설정

        move  $a0, $s3
        move  $a1, $s1
        jal   set_pba_data          # new_pba에 data 저장

        move  $a0, $s0
        move  $a1, $s3
        jal   set_lba_mapping       # LBA -> PBA mapping 갱신

        lw    $t0, total_write_count
        addiu $t0, $t0, 1           # WRITE 횟수 +1
        sw    $t0, total_write_count

        lw    $t0, free_page_count
        addiu $t0, $t0, -1          # FREE page 수 감소
        sw    $t0, free_page_count

        la    $a0, msg_new_pba      # 새 PBA 출력
        jal   print_string
        move  $a0, $s3
        jal   print_int
        jal   print_newline

        la    $a0, msg_lba_prefix   # LBA 출력
        jal   print_string
        move  $a0, $s0
        jal   print_int
        la    $a0, msg_arrow_pba    # PBA 출력
        jal   print_string
        move  $a0, $s3
        jal   print_int
        la    $a0, msg_data_eq      # data 출력
        jal   print_string
        move  $a0, $s1
        jal   print_int
        jal   print_newline

        move  $a0, $s0              # lba
        move  $a1, $s3              # pba
        move  $a2, $s1              # data
        jal   log_write_event

        la    $a0, msg_write_ok
        li    $a1, 1
        jal   run_state             # 상태 메시지와 시간 처리
        j     fwc_done

fwc_no_free:                        # 빈 PBA가 없는 경우
        li    $t0, -1
        beq   $s2, $t0, fwc_no_free_msg

        move  $a0, $s2
        li    $a1, 1
        jal   set_pba_state         # restore old_pba to VALID

        lw    $t0, invalid_page_count
        addiu $t0, $t0, -1
        sw    $t0, invalid_page_count

fwc_no_free_msg:
        la    $a0, msg_no_free
        jal   print_string

fwc_done:                           # 쓰기 처리 끝
        lw    $ra, 16($sp)          # 복귀 주소 복구
        lw    $s0, 12($sp)          # lba 복구
        lw    $s1,  8($sp)          # data 복구
        lw    $s2,  4($sp)          # old_pba 복구
        lw    $s3,  0($sp)          # new_pba 복구
        addiu $sp, $sp, 20
        jr    $ra                   # 호출한 곳으로 복귀

