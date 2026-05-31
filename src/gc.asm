# 간단한 GC

        .text

run_simple_gc:                      # INVALID page를 FREE로 되돌림
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)           # 복귀 주소
        sw    $s0, 0($sp)           # freed count

        la    $a0, msg_gc_start     # GC 시작 메시지
        jal   print_string

        li    $s0, 0                # freed = 0
        li    $t0, 0                # i = 0

gc_loop:                            # 모든 PBA 확인
        li    $t1, 8                # PBA 개수
        bge   $t0, $t1, gc_done

        la    $t2, pba_state        # 상태 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &pba_state[i]
        lw    $t4, 0($t2)           # pba_state[i]

        li    $t5, 2                # INVALID 값
        bne   $t4, $t5, gc_next     # INVALID 아니면 건너뜀

        sw    $zero, 0($t2)         # pba_state[i] = FREE

        la    $a0, msg_gc_pba_ok    # 정리한 PBA 출력
        jal   print_string
        move  $a0, $t0
        jal   print_int
        la    $a0, msg_gc_to_free   # FREE로 바꿨다는 표시
        jal   print_string

        addiu $s0, $s0, 1           # freed++

gc_next:                            # 다음 PBA로 이동
        addiu $t0, $t0, 1           # i++
        j     gc_loop

gc_done:                            # GC 마무리
        lw    $t0, free_page_count
        add   $t0, $t0, $s0         # FREE page 수 증가
        sw    $t0, free_page_count

        lw    $t0, invalid_page_count
        sub   $t0, $t0, $s0         # INVALID page 수 감소
        sw    $t0, invalid_page_count

        lw    $t0, gc_count
        addiu $t0, $t0, 1           # GC 횟수 +1
        sw    $t0, gc_count

        la    $a0, msg_gc_freed     # 정리한 page 수 출력
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        la    $a0, msg_gc_done      # GC 끝 메시지
        jal   print_string

        move  $a0, $s0              # freed count를 Trace에 기록
        jal   log_gc_event

        lw    $ra, 4($sp)           # 복귀 주소 복구
        lw    $s0, 0($sp)           # freed count 복구
        addiu $sp, $sp, 8
        jr    $ra                   # 호출한 곳으로 복귀
