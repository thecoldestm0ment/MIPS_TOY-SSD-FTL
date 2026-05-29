# =============================================================================
# trace.asm  --  Trace Log 기록 및 출력
#
# 이벤트 발생 순서대로 최대 20개까지 기록한다.
# 각 이벤트는 type / lba / pba / data 4가지 필드를 가진다.
#
# 이벤트 타입:
#   1 = WRITE, 2 = READ, 3 = GC, 4 = RESET
# =============================================================================

        .text

# -----------------------------------------------------------------------------
# log_write_event
#   역할  : WRITE 이벤트를 trace log에 기록한다
#   입력  : $a0 = LBA, $a1 = PBA, $a2 = data 값
#   출력  : 없음
#   주의  : jal 호출 → $ra 스택 저장
# -----------------------------------------------------------------------------
log_write_event:
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)
        sw    $a0,  8($sp)         # lba
        sw    $a1,  4($sp)         # pba
        sw    $a2,  0($sp)         # data

        jal   trace_check_full
        bnez  $v0, lwe_done        # 가득 찼으면 기록 생략

        # trace_count를 인덱스로 사용
        lw    $t0, trace_count

        # trace_type[idx] = TTYPE_WRITE (1)
        sll   $t1, $t0, 2
        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, 1
        sw    $t3, 0($t2)

        # trace_lba[idx] = lba
        la    $t2, trace_lba
        add   $t2, $t2, $t1
        lw    $t3, 8($sp)
        sw    $t3, 0($t2)

        # trace_pba[idx] = pba
        la    $t2, trace_pba
        add   $t2, $t2, $t1
        lw    $t3, 4($sp)
        sw    $t3, 0($t2)

        # trace_data[idx] = data
        la    $t2, trace_data
        add   $t2, $t2, $t1
        lw    $t3, 0($sp)
        sw    $t3, 0($t2)

        # trace_count++
        addiu $t0, $t0, 1
        sw    $t0, trace_count

lwe_done:
        lw    $ra, 12($sp)
        addiu $sp, $sp, 16
        jr    $ra

# -----------------------------------------------------------------------------
# log_read_event
#   역할  : READ 이벤트를 trace log에 기록한다
#   입력  : $a0 = LBA, $a1 = PBA, $a2 = data 값
#   출력  : 없음
# -----------------------------------------------------------------------------
log_read_event:
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)
        sw    $a0,  8($sp)
        sw    $a1,  4($sp)
        sw    $a2,  0($sp)

        jal   trace_check_full
        bnez  $v0, lre_done

        lw    $t0, trace_count
        sll   $t1, $t0, 2

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, 2              # TTYPE_READ
        sw    $t3, 0($t2)

        la    $t2, trace_lba
        add   $t2, $t2, $t1
        lw    $t3, 8($sp)
        sw    $t3, 0($t2)

        la    $t2, trace_pba
        add   $t2, $t2, $t1
        lw    $t3, 4($sp)
        sw    $t3, 0($t2)

        la    $t2, trace_data
        add   $t2, $t2, $t1
        lw    $t3, 0($sp)
        sw    $t3, 0($t2)

        addiu $t0, $t0, 1
        sw    $t0, trace_count

lre_done:
        lw    $ra, 12($sp)
        addiu $sp, $sp, 16
        jr    $ra

# -----------------------------------------------------------------------------
# log_gc_event
#   역할  : GC 이벤트를 trace log에 기록한다
#   입력  : $a0 = freed page 수
#   출력  : 없음
#   주의  : GC는 특정 LBA/PBA와 연결되지 않으므로 lba=-1, pba=-1로 기록
# -----------------------------------------------------------------------------
log_gc_event:
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)
        sw    $a0, 0($sp)          # freed count → data 필드에 저장

        jal   trace_check_full
        bnez  $v0, lge_done

        lw    $t0, trace_count
        sll   $t1, $t0, 2

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, 3              # TTYPE_GC
        sw    $t3, 0($t2)

        la    $t2, trace_lba
        add   $t2, $t2, $t1
        li    $t3, -1
        sw    $t3, 0($t2)

        la    $t2, trace_pba
        add   $t2, $t2, $t1
        sw    $t3, 0($t2)         # -1

        la    $t2, trace_data
        add   $t2, $t2, $t1
        lw    $t3, 0($sp)         # freed count
        sw    $t3, 0($t2)

        addiu $t0, $t0, 1
        sw    $t0, trace_count

lge_done:
        lw    $ra, 4($sp)
        addiu $sp, $sp, 8
        jr    $ra

# -----------------------------------------------------------------------------
# log_reset_event
#   역할  : RESET 이벤트를 trace log에 기록한다 (reset 직후 호출)
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
log_reset_event:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        jal   trace_check_full
        bnez  $v0, lrese_done

        lw    $t0, trace_count
        sll   $t1, $t0, 2

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, 4              # TTYPE_RESET
        sw    $t3, 0($t2)

        la    $t2, trace_lba
        add   $t2, $t2, $t1
        li    $t3, -1
        sw    $t3, 0($t2)

        la    $t2, trace_pba
        add   $t2, $t2, $t1
        sw    $t3, 0($t2)

        la    $t2, trace_data
        add   $t2, $t2, $t1
        sw    $zero, 0($t2)

        addiu $t0, $t0, 1
        sw    $t0, trace_count

lrese_done:
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

# -----------------------------------------------------------------------------
# trace_check_full  (내부 헬퍼)
#   역할  : trace log가 가득 찼는지 확인한다
#   입력  : 없음
#   출력  : $v0 = 1 (가득 참), 0 (여유 있음)
# -----------------------------------------------------------------------------
trace_check_full:
        lw    $t0, trace_count
        li    $t1, 20              # TRACE_MAX = 20
        li    $v0, 0
        blt   $t0, $t1, tcf_ok
        li    $v0, 1
tcf_ok:
        jr    $ra

# -----------------------------------------------------------------------------
# print_trace_log
#   역할  : 기록된 trace 이벤트를 순서대로 출력한다
#   입력  : 없음
#   출력  : 없음
#   형식  : "N | TYPE | LBA X | PBA X | DATA X"
# -----------------------------------------------------------------------------
print_trace_log:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_trace_hdr
        jal   print_string

        lw    $t0, trace_count
        beqz  $t0, ptl_empty       # 기록이 없으면 안내 메시지

        li    $t0, 0               # i = 0

ptl_loop:
        lw    $t1, trace_count
        bge   $t0, $t1, ptl_done

        # 인덱스 N 출력
        move  $a0, $t0
        jal   print_int
        la    $a0, msg_trace_pipe
        jal   print_string

        # type 읽기
        la    $t2, trace_type
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $t4, 0($t2)          # $t4 = type

        # type 이름 출력
        li    $t5, 1
        beq   $t4, $t5, ptl_write
        li    $t5, 2
        beq   $t4, $t5, ptl_read
        li    $t5, 3
        beq   $t4, $t5, ptl_gc
        li    $t5, 4
        beq   $t4, $t5, ptl_reset
        j     ptl_type_done

ptl_write:
        la    $a0, msg_t_write
        jal   print_string
        j     ptl_print_lba

ptl_read:
        la    $a0, msg_t_read
        jal   print_string
        j     ptl_print_lba

ptl_gc:
        la    $a0, msg_t_gc
        jal   print_string

        # GC는 LBA/PBA 없이 freed count만 출력
        la    $t2, trace_data
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)

        la    $a1, msg_t_freed
        move  $a2, $a0

        la    $a0, msg_t_freed
        jal   print_string
        move  $a0, $a2
        jal   print_int
        jal   print_newline
        j     ptl_next

ptl_reset:
        la    $a0, msg_t_reset
        jal   print_string
        jal   print_newline
        j     ptl_next

ptl_print_lba:
        # " | LBA X"
        la    $a0, msg_t_lba
        jal   print_string
        la    $t2, trace_lba
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)
        jal   print_int

        # " | PBA X"
        la    $a0, msg_t_pba
        jal   print_string
        la    $t2, trace_pba
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)
        jal   print_int

        # " | DATA X"
        la    $a0, msg_t_data
        jal   print_string
        la    $t2, trace_data
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)
        jal   print_int
        jal   print_newline

ptl_type_done:
ptl_next:
        addiu $t0, $t0, 1
        j     ptl_loop

ptl_empty:
        la    $a0, msg_trace_none
        jal   print_string

ptl_done:
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

# -----------------------------------------------------------------------------
# reset_trace_log
#   역할  : trace_count를 0으로 되돌린다 (배열 내용은 덮여씌워질 예정)
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
reset_trace_log:
        sw    $zero, trace_count
        jr    $ra
