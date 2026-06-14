# 읽기 처리

        .text

submit_read_request:                # 입력받은 LBA로 읽기 함수 호출
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)           # 복귀 주소
        sw    $s0, 0($sp)           # 입력받은 LBA

        la    $a0, msg_read_lba     # LBA 입력 안내
        jal   print_string
        jal   read_int
        move  $s0, $v0              # 입력된 LBA

        move  $a0, $s0              # 범위 검사할 LBA
        jal   check_lba_range
        beqz  $v0, srr_bad          # 범위 밖이면 에러 출력

        move  $a0, $s0              # 읽을 LBA 전달
        jal   ftl_read_core
        j     srr_done

srr_bad:                            # 잘못된 LBA 입력
        la    $a0, msg_lba_range
        jal   print_string

srr_done:                           # 입력 처리 끝
        lw    $ra, 4($sp)           # 복귀 주소 복구
        lw    $s0, 0($sp)           # 저장한 LBA 복구
        addiu $sp, $sp, 8
        jr    $ra                   # 호출한 곳으로 복귀

ftl_read_core:                      # LBA에 연결된 data를 읽어서 출력
        addiu $sp, $sp, -12
        sw    $ra,  8($sp)          # 복귀 주소
        sw    $s0,  4($sp)          # LBA
        sw    $s1,  0($sp)          # PBA

        move  $s0, $a0              # 현재 LBA

        la    $a0, msg_read_lba_p   # 읽는 LBA 표시
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        move  $a0, $s0              # mapping 먼저 확인
        jal   get_lba_mapping
        move  $s1, $v0              # PBA

        li    $t0, -1
        beq   $s1, $t0, frc_no_data # mapping 없으면 종료

        la    $a0, msg_mapped_pba   # 연결된 PBA 출력
        jal   print_string
        move  $a0, $s1
        jal   print_int
        jal   print_newline

        move  $a0, $s1              # PBA에 저장된 data 읽기
        jal   get_pba_data
        move  $s0, $v0              # syscall 출력 전에 data를 먼저 보관

        la    $a0, msg_data_val     # data 출력
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        lw    $t0, total_read_count
        addiu $t0, $t0, 1           # READ 횟수 +1
        sw    $t0, total_read_count

        lw    $t1, 4($sp)           # 원래 LBA 복구
        move  $a0, $t1              # lba
        move  $a1, $s1              # pba
        move  $a2, $s0              # data
        jal   log_read_event

        j     frc_done

frc_no_data:                        # 아직 data가 없는 LBA
        la    $a0, msg_no_data
        jal   print_string

frc_done:                           # 읽기 처리 끝
        lw    $ra,  8($sp)          # 복귀 주소 복구
        lw    $s0,  4($sp)          # LBA 복구
        lw    $s1,  0($sp)          # PBA 복구
        addiu $sp, $sp, 12
        jr    $ra                   # 호출한 곳으로 복귀
