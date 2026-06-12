# Trace logging and printing
# trace는 실행 중 일어난 일을 순서대로 저장해 나중에 한 번에 출력한다.
# 공통 저장 규칙:
#   trace_type = 이벤트 종류(WRITE/READ/GC/RESET/MIGRATE)
#   trace_lba  = 관련 LBA, 없으면 -1
#   trace_pba  = 관련 PBA 또는 migration 전 old PBA
#   trace_data = data 값, GC freed count, 또는 migration 후 new PBA

        .text

log_write_event:                    # WRITE 기록: 어떤 LBA가 어떤 PBA에 어떤 data로 쓰였는지 저장
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)
        sw    $a0,  8($sp)          # LBA
        sw    $a1,  4($sp)          # 새로 할당된 PBA
        sw    $a2,  0($sp)          # write data

        jal   trace_check_full
        bnez  $v0, lwe_done         # trace가 꽉 차면 기록하지 않고 종료

        lw    $t0, trace_count      # 현재 기록 위치(index)
        sll   $t1, $t0, 2           # word 배열 offset = index * 4

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, TTYPE_WRITE
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

lwe_done:
        lw    $ra, 12($sp)
        addiu $sp, $sp, 16
        jr    $ra

log_read_event:                     # READ 기록: 읽은 LBA/PBA와 반환된 data 저장
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)
        sw    $a0,  8($sp)          # LBA
        sw    $a1,  4($sp)          # mapping table이 가리킨 PBA
        sw    $a2,  0($sp)          # read data

        jal   trace_check_full
        bnez  $v0, lre_done

        lw    $t0, trace_count
        sll   $t1, $t0, 2

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, TTYPE_READ
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

log_gc_event:                       # GC 기록: block erase 후 새로 확보된 FREE page 수 저장
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)
        sw    $a0, 0($sp)           # freed count = victim block에 있던 INVALID page 수

        jal   trace_check_full
        bnez  $v0, lge_done

        lw    $t0, trace_count
        sll   $t1, $t0, 2

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, TTYPE_GC
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
        lw    $t3, 0($sp)
        sw    $t3, 0($t2)

        addiu $t0, $t0, 1
        sw    $t0, trace_count

lge_done:
        lw    $ra, 4($sp)
        addiu $sp, $sp, 8
        jr    $ra

log_migrate_event:                  # MIGRATE 기록: GC가 VALID page를 old PBA에서 new PBA로 옮긴 사실 저장
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)
        sw    $a0,  8($sp)          # 옮겨진 page가 담당하던 LBA
        sw    $a1,  4($sp)          # erase될 victim block 안의 old PBA
        sw    $a2,  0($sp)          # victim block 밖의 new PBA

        jal   trace_check_full
        bnez  $v0, lme_done

        lw    $t0, trace_count
        sll   $t1, $t0, 2

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, TTYPE_MIGRATE
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
        sw    $t3, 0($t2)           # MIGRATE에서는 trace_data를 new PBA 저장용으로 재사용

        addiu $t0, $t0, 1
        sw    $t0, trace_count

lme_done:
        lw    $ra, 12($sp)
        addiu $sp, $sp, 16
        jr    $ra

log_reset_event:                    # RESET 기록: SSD 상태 초기화가 일어났음을 저장
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        jal   trace_check_full
        bnez  $v0, lrese_done

        lw    $t0, trace_count
        sll   $t1, $t0, 2

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, TTYPE_RESET
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

trace_check_full:                   # trace_count가 TRACE_MAX 이상이면 $v0=1, 아니면 $v0=0
        lw    $t0, trace_count
        li    $t1, TRACE_MAX
        li    $v0, 0
        blt   $t0, $t1, tcf_ok
        li    $v0, 1

tcf_ok:
        jr    $ra

print_trace_log:                    # 저장된 trace event를 0번부터 순서대로 출력
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)
        sw    $s0, 0($sp)           # trace index

        la    $a0, msg_trace_hdr
        jal   print_string

        lw    $t0, trace_count
        beqz  $t0, ptl_empty

        li    $s0, 0

ptl_loop:                           # trace_count만큼 반복하면서 각 event type에 맞게 출력
        lw    $t0, trace_count
        bge   $s0, $t0, ptl_done

        move  $a0, $s0
        jal   print_int
        la    $a0, msg_trace_pipe
        jal   print_string

        la    $t1, trace_type
        sll   $t2, $s0, 2
        add   $t1, $t1, $t2
        lw    $t3, 0($t1)           # 현재 trace entry의 type

        li    $t4, TTYPE_WRITE
        beq   $t3, $t4, ptl_write
        li    $t4, TTYPE_READ
        beq   $t3, $t4, ptl_read
        li    $t4, TTYPE_GC
        beq   $t3, $t4, ptl_gc
        li    $t4, TTYPE_RESET
        beq   $t3, $t4, ptl_reset
        li    $t4, TTYPE_MIGRATE
        beq   $t3, $t4, ptl_migrate
        j     ptl_next

ptl_write:                          # WRITE | LBA x | PBA y | DATA z
        la    $a0, msg_t_write
        jal   print_string
        j     ptl_print_lba_pba_data

ptl_read:                           # READ  | LBA x | PBA y | DATA z
        la    $a0, msg_t_read
        jal   print_string
        j     ptl_print_lba_pba_data

ptl_gc:                             # GC    | Freed pages: n
        la    $a0, msg_t_gc
        jal   print_string

        la    $t1, trace_data
        sll   $t2, $s0, 2
        add   $t1, $t1, $t2
        lw    $t3, 0($t1)

        la    $a0, msg_t_freed
        jal   print_string
        move  $a0, $t3
        jal   print_int
        jal   print_newline
        j     ptl_next

ptl_reset:                          # RESET
        la    $a0, msg_t_reset
        jal   print_string
        jal   print_newline
        j     ptl_next

ptl_migrate:                        # MIGRATE | LBA x | PBA old -> PBA new
        la    $a0, msg_t_migrate
        jal   print_string

        la    $a0, msg_t_lba
        jal   print_string
        la    $t1, trace_lba
        sll   $t2, $s0, 2
        add   $t1, $t1, $t2
        lw    $a0, 0($t1)
        jal   print_int

        la    $a0, msg_t_pba
        jal   print_string
        la    $t1, trace_pba
        sll   $t2, $s0, 2
        add   $t1, $t1, $t2
        lw    $a0, 0($t1)
        jal   print_int

        la    $a0, msg_t_to_pba
        jal   print_string
        la    $t1, trace_data
        sll   $t2, $s0, 2
        add   $t1, $t1, $t2
        lw    $a0, 0($t1)
        jal   print_int
        jal   print_newline
        j     ptl_next

ptl_print_lba_pba_data:             # WRITE/READ가 공유하는 LBA, PBA, DATA 출력 코드
        la    $a0, msg_t_lba
        jal   print_string
        la    $t1, trace_lba
        sll   $t2, $s0, 2
        add   $t1, $t1, $t2
        lw    $a0, 0($t1)
        jal   print_int

        la    $a0, msg_t_pba
        jal   print_string
        la    $t1, trace_pba
        sll   $t2, $s0, 2
        add   $t1, $t1, $t2
        lw    $a0, 0($t1)
        jal   print_int

        la    $a0, msg_t_data
        jal   print_string
        la    $t1, trace_data
        sll   $t2, $s0, 2
        add   $t1, $t1, $t2
        lw    $a0, 0($t1)
        jal   print_int
        jal   print_newline

ptl_next:
        addiu $s0, $s0, 1
        j     ptl_loop

ptl_empty:
        la    $a0, msg_trace_none
        jal   print_string

ptl_done:
        lw    $ra, 4($sp)
        lw    $s0, 0($sp)
        addiu $sp, $sp, 8
        jr    $ra

reset_trace_log:                    # clear trace by resetting count
        sw    $zero, trace_count
        jr    $ra
