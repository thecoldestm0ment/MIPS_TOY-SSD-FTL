# Trace 기록과 출력

        .text

log_write_event:                    # WRITE 이벤트를 Trace에 기록
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)          # 복귀 주소
        sw    $a0,  8($sp)          # lba
        sw    $a1,  4($sp)          # pba
        sw    $a2,  0($sp)          # data

        jal   trace_check_full
        bnez  $v0, lwe_done         # Trace가 꽉 찼으면 종료

        lw    $t0, trace_count      # 현재 Trace index
        sll   $t1, $t0, 2           # offset = index * 4

        la    $t2, trace_type       # type 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_type[index]
        li    $t3, 1
        sw    $t3, 0($t2)           # type = WRITE

        la    $t2, trace_lba        # lba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_lba[index]
        lw    $t3, 8($sp)           # lba
        sw    $t3, 0($t2)

        la    $t2, trace_pba        # pba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_pba[index]
        lw    $t3, 4($sp)           # pba
        sw    $t3, 0($t2)

        la    $t2, trace_data       # data 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_data[index]
        lw    $t3, 0($sp)           # data
        sw    $t3, 0($t2)

        addiu $t0, $t0, 1           # trace_count++
        sw    $t0, trace_count

lwe_done:                           # WRITE 기록 끝
        lw    $ra, 12($sp)          # 복귀 주소 복구
        addiu $sp, $sp, 16
        jr    $ra                   # 호출한 곳으로 복귀

log_read_event:                     # READ 이벤트를 Trace에 기록
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)          # 복귀 주소
        sw    $a0,  8($sp)          # lba
        sw    $a1,  4($sp)          # pba
        sw    $a2,  0($sp)          # data

        jal   trace_check_full
        bnez  $v0, lre_done         # Trace가 꽉 찼으면 종료

        lw    $t0, trace_count      # 현재 Trace index
        sll   $t1, $t0, 2           # offset = index * 4

        la    $t2, trace_type       # type 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_type[index]
        li    $t3, 2
        sw    $t3, 0($t2)           # type = READ

        la    $t2, trace_lba        # lba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_lba[index]
        lw    $t3, 8($sp)           # lba
        sw    $t3, 0($t2)

        la    $t2, trace_pba        # pba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_pba[index]
        lw    $t3, 4($sp)           # pba
        sw    $t3, 0($t2)

        la    $t2, trace_data       # data 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_data[index]
        lw    $t3, 0($sp)           # data
        sw    $t3, 0($t2)

        addiu $t0, $t0, 1           # trace_count++
        sw    $t0, trace_count

lre_done:                           # READ 기록 끝
        lw    $ra, 12($sp)          # 복귀 주소 복구
        addiu $sp, $sp, 16
        jr    $ra                   # 호출한 곳으로 복귀

log_gc_event:                       # GC 이벤트를 Trace에 기록
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)           # 복귀 주소
        sw    $a0, 0($sp)           # freed count

        jal   trace_check_full
        bnez  $v0, lge_done         # Trace가 꽉 찼으면 종료

        lw    $t0, trace_count      # 현재 Trace index
        sll   $t1, $t0, 2           # offset = index * 4

        la    $t2, trace_type       # type 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_type[index]
        li    $t3, 3
        sw    $t3, 0($t2)           # type = GC

        la    $t2, trace_lba        # lba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_lba[index]
        li    $t3, -1
        sw    $t3, 0($t2)           # GC는 lba 없음

        la    $t2, trace_pba        # pba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_pba[index]
        sw    $t3, 0($t2)           # GC는 pba 없음

        la    $t2, trace_data       # data 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_data[index]
        lw    $t3, 0($sp)           # freed count
        sw    $t3, 0($t2)

        addiu $t0, $t0, 1           # trace_count++
        sw    $t0, trace_count

lge_done:                           # GC 기록 끝
        lw    $ra, 4($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 8
        jr    $ra                   # 호출한 곳으로 복귀

log_reset_event:                    # RESET 이벤트를 Trace에 기록
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        jal   trace_check_full
        bnez  $v0, lrese_done       # Trace가 꽉 찼으면 종료

        lw    $t0, trace_count      # 현재 Trace index
        sll   $t1, $t0, 2           # offset = index * 4

        la    $t2, trace_type       # type 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_type[index]
        li    $t3, 4
        sw    $t3, 0($t2)           # type = RESET

        la    $t2, trace_lba        # lba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_lba[index]
        li    $t3, -1
        sw    $t3, 0($t2)           # RESET은 lba 없음

        la    $t2, trace_pba        # pba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_pba[index]
        sw    $t3, 0($t2)           # RESET은 pba 없음

        la    $t2, trace_data       # data 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_data[index]
        sw    $zero, 0($t2)         # RESET은 data 없음

        addiu $t0, $t0, 1           # trace_count++
        sw    $t0, trace_count

lrese_done:                         # RESET 기록 끝
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

trace_check_full:                   # Trace가 꽉 찼는지 확인
        lw    $t0, trace_count      # 현재 기록 개수
        li    $t1, 20               # 최대 20개
        li    $v0, 0                # 기본값은 여유 있음
        blt   $t0, $t1, tcf_ok      # 20 미만이면 기록 가능
        li    $v0, 1                # 20 이상이면 가득 참
tcf_ok:                             # 검사 끝
        jr    $ra                   # 호출한 곳으로 복귀

print_trace_log:                    # Trace 내용을 순서대로 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_trace_hdr    # 헤더 출력
        jal   print_string

        lw    $t0, trace_count      # 기록 개수 확인
        beqz  $t0, ptl_empty        # 아무 것도 없으면 안내 출력

        li    $t0, 0                # i = 0

ptl_loop:                           # Trace i번째 출력
        lw    $t1, trace_count
        bge   $t0, $t1, ptl_done

        move  $a0, $t0              # index 출력
        jal   print_int
        la    $a0, msg_trace_pipe
        jal   print_string

        la    $t2, trace_type       # type 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &trace_type[i]
        lw    $t4, 0($t2)           # type 값

        li    $t5, 1
        beq   $t4, $t5, ptl_write
        li    $t5, 2
        beq   $t4, $t5, ptl_read
        li    $t5, 3
        beq   $t4, $t5, ptl_gc
        li    $t5, 4
        beq   $t4, $t5, ptl_reset
        j     ptl_type_done

ptl_write:                          # WRITE 타입 출력
        la    $a0, msg_t_write
        jal   print_string
        j     ptl_print_lba

ptl_read:                           # READ 타입 출력
        la    $a0, msg_t_read
        jal   print_string
        j     ptl_print_lba

ptl_gc:                             # GC 타입 출력
        la    $a0, msg_t_gc
        jal   print_string

        la    $t2, trace_data       # data 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &trace_data[i]
        lw    $a2, 0($t2)           # freed count

        la    $a0, msg_t_freed
        jal   print_string
        move  $a0, $a2
        jal   print_int
        jal   print_newline
        j     ptl_next

ptl_reset:                          # RESET 타입 출력
        la    $a0, msg_t_reset
        jal   print_string
        jal   print_newline
        j     ptl_next

ptl_print_lba:                      # LBA, PBA, DATA 출력
        la    $a0, msg_t_lba
        jal   print_string
        la    $t2, trace_lba        # lba 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &trace_lba[i]
        lw    $a0, 0($t2)           # lba 출력
        jal   print_int

        la    $a0, msg_t_pba
        jal   print_string
        la    $t2, trace_pba        # pba 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &trace_pba[i]
        lw    $a0, 0($t2)           # pba 출력
        jal   print_int

        la    $a0, msg_t_data
        jal   print_string
        la    $t2, trace_data       # data 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &trace_data[i]
        lw    $a0, 0($t2)           # data 출력
        jal   print_int
        jal   print_newline

ptl_type_done:
ptl_next:                           # 다음 Trace로 이동
        addiu $t0, $t0, 1           # i++
        j     ptl_loop

ptl_empty:                          # Trace가 비어 있음
        la    $a0, msg_trace_none
        jal   print_string

ptl_done:                           # Trace 출력 끝
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

reset_trace_log:                    # Trace 개수만 0으로 초기화
        sw    $zero, trace_count
        jr    $ra                   # 호출한 곳으로 복귀
