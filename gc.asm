# =============================================================================
# gc.asm  --  Simplified Garbage Collection
#
# 실제 SSD GC는 다음 과정이 필요하다:
#   1) GC 대상 블록 선정 (victim block selection)
#   2) VALID 페이지를 다른 블록으로 이동 (valid page migration)
#   3) 블록 전체 erase
#   4) 빈 블록을 FREE로 등록
#
# 이 프로젝트에서는 MIPS 구현 난이도를 고려하여,
# INVALID 페이지를 FREE로 되돌리고 관련 블록의 erase count를 증가시키는
# simplified GC로 표현한다. 핵심 개념(INVALID 회수)은 동일하다.
# =============================================================================

        .text

# -----------------------------------------------------------------------------
# run_simple_gc
#   역할  : pba_state 전체를 순회해 INVALID 페이지를 FREE로 되돌린다.
#           해당 페이지가 속한 block의 erase count를 증가시킨다.
#           결과를 출력하고 trace log에 GC 이벤트를 기록한다.
#   입력  : 없음
#   출력  : 없음
#   주의  : $s0 = freed count
# -----------------------------------------------------------------------------
run_simple_gc:
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)
        sw    $s0, 0($sp)

        la    $a0, msg_gc_start
        jal   print_string

        li    $s0, 0               # freed = 0
        li    $t0, 0               # i = 0

gc_loop:
        li    $t1, 8               # PBA_COUNT = 8
        bge   $t0, $t1, gc_done

        # pba_state[i] 확인
        la    $t2, pba_state
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $t4, 0($t2)

        li    $t5, 2               # INVALID = 2
        bne   $t4, $t5, gc_next

        # INVALID 발견: FREE(0)로 변경
        sw    $zero, 0($t2)

        # 어떤 페이지가 해제되었는지 출력
        la    $a0, msg_gc_pba_ok
        jal   print_string
        move  $a0, $t0
        jal   print_int
        la    $a0, msg_gc_freed1
        jal   print_string

        # block_id = pba / 4
        move  $a0, $t0
        jal   get_block_id_by_pba
        move  $t6, $v0             # $t6 = block_id

        move  $a0, $t6
        jal   print_int
        la    $a0, msg_gc_freed2
        jal   print_string

        # 해당 블록 erase count 증가
        move  $a0, $t6
        jal   increase_block_erase_count

        addiu $s0, $s0, 1          # freed++

gc_next:
        addiu $t0, $t0, 1
        j     gc_loop

gc_done:
        # free_page_count += freed, invalid_page_count -= freed
        lw    $t0, free_page_count
        add   $t0, $t0, $s0
        sw    $t0, free_page_count

        lw    $t0, invalid_page_count
        sub   $t0, $t0, $s0
        sw    $t0, invalid_page_count

        lw    $t0, gc_count
        addiu $t0, $t0, 1
        sw    $t0, gc_count

        # "Freed pages: X" 출력
        la    $a0, msg_gc_freed
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        la    $a0, msg_gc_done
        jal   print_string

        # trace 기록: log_gc_event(freed_count)
        move  $a0, $s0
        jal   log_gc_event

        lw    $ra, 4($sp)
        lw    $s0, 0($sp)
        addiu $sp, $sp, 8
        jr    $ra
