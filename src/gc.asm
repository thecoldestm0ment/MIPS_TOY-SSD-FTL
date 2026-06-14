# Block 단위 GC + VALID page migration

        .text

run_gc:                              # victim block을 고르고 VALID page를 옮긴 뒤 block erase
        addiu $sp, $sp, -48
        sw    $ra, 44($sp)
        sw    $s0, 40($sp)          # victim block
        sw    $s1, 36($sp)          # victim invalid count
        sw    $s2, 32($sp)          # block loop
        sw    $s3, 28($sp)          # victim valid count
        sw    $s4, 24($sp)          # outside free count
        sw    $s5, 20($sp)          # victim start pba
        sw    $s6, 16($sp)          # victim end pba
        sw    $s7, 12($sp)          # current pba
                                    # 8($sp)=data, 4($sp)=lba, 0($sp)=dest pba

        la    $a0, msg_gc_block_start
        jal   print_string

        li    $s0, -1               # victim = -1
        li    $s1, 0                # max invalid count = 0
        li    $s2, 0                # block = 0

gc_select_block_loop:               # 모든 block을 돌면서 INVALID가 가장 많은 block 찾기
        li    $t0, BLOCK_COUNT
        bge   $s2, $t0, gc_select_done

        li    $t0, BLOCK_SIZE
        mul   $t1, $s2, $t0         # start_pba
        add   $t2, $t1, $t0         # end_pba
        move  $t3, $t1              # pba
        li    $t4, 0                # invalid_count

gc_count_invalid_loop:              # 현재 block 안의 INVALID page 수 계산
        bge   $t3, $t2, gc_count_invalid_done
        la    $t5, pba_state
        sll   $t6, $t3, 2
        add   $t5, $t5, $t6
        lw    $t7, 0($t5)
        li    $t8, INVALID
        bne   $t7, $t8, gc_count_invalid_next
        addiu $t4, $t4, 1

gc_count_invalid_next:
        addiu $t3, $t3, 1
        j     gc_count_invalid_loop

gc_count_invalid_done:              # 현재 block 계산이 끝나면 victim 후보와 비교
        ble   $t4, $s1, gc_select_next_block
        move  $s1, $t4              # new max invalid count
        move  $s0, $s2              # victim = block

gc_select_next_block:               # 다음 block 검사
        addiu $s2, $s2, 1
        j     gc_select_block_loop

gc_select_done:                     # victim 선택 완료
        beqz  $s1, gc_no_victim

        la    $a0, msg_gc_victim
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        li    $t0, BLOCK_SIZE
        mul   $s5, $s0, $t0         # victim start pba
        add   $s6, $s5, $t0         # victim end pba

        li    $s3, 0                # victim valid count
        li    $s4, 0                # outside free count
        li    $s7, 0                # pba = 0

gc_preflight_loop:                  # migration 전에 VALID 수와 밖의 FREE 수를 미리 확인
        li    $t0, PBA_COUNT
        bge   $s7, $t0, gc_preflight_done

        la    $t1, pba_state
        sll   $t2, $s7, 2
        add   $t1, $t1, $t2
        lw    $t3, 0($t1)

        blt   $s7, $s5, gc_preflight_outside
        blt   $s7, $s6, gc_preflight_inside
        j     gc_preflight_outside

gc_preflight_inside:                # victim block 내부면 VALID page 수를 센다
        li    $t4, VALID
        bne   $t3, $t4, gc_preflight_next
        addiu $s3, $s3, 1
        j     gc_preflight_next

gc_preflight_outside:               # victim block 밖이면 migration 목적지 후보 FREE 수를 센다
        li    $t4, FREE
        bne   $t3, $t4, gc_preflight_next
        addiu $s4, $s4, 1

gc_preflight_next:
        addiu $s7, $s7, 1
        j     gc_preflight_loop

gc_preflight_done:                  # 밖의 FREE가 부족하면 상태 변경 없이 실패 처리
        blt   $s4, $s3, gc_no_space

        move  $s7, $s5              # pba = victim start

gc_migrate_loop:                    # victim 안 VALID page를 victim 밖 FREE PBA로 복사
        bge   $s7, $s6, gc_migrate_done

        la    $t0, pba_state
        sll   $t1, $s7, 2
        add   $t0, $t0, $t1
        lw    $t2, 0($t0)
        li    $t3, VALID
        bne   $t2, $t3, gc_migrate_next

        move  $a0, $s7
        jal   get_pba_data
        sw    $v0, 8($sp)           # 이동할 data 임시 저장

        move  $a0, $s7
        jal   find_lba_by_pba
        sw    $v0, 4($sp)           # 이 PBA를 가리키던 LBA 저장

        li    $t0, -1
        beq   $v0, $t0, gc_no_space

        move  $a0, $s0
        jal   find_free_pba_excluding_block
        sw    $v0, 0($sp)           # 새 목적지 PBA 저장

        li    $t0, -1
        beq   $v0, $t0, gc_no_space

        la    $a0, msg_gc_move
        jal   print_string
        move  $a0, $s7
        jal   print_int
        la    $a0, msg_gc_to_pba
        jal   print_string
        lw    $a0, 0($sp)
        jal   print_int
        jal   print_newline

        lw    $a0, 0($sp)
        li    $a1, VALID
        jal   set_pba_state

        lw    $a0, 0($sp)
        lw    $a1, 8($sp)
        jal   set_pba_data

        lw    $a0, 4($sp)
        lw    $a1, 0($sp)
        jal   set_lba_mapping

        lw    $a0, 4($sp)           # migration된 page가 담당하던 LBA
        move  $a1, $s7              # erase될 victim block 안의 old PBA
        lw    $a2, 0($sp)           # data가 복사된 victim block 밖의 new PBA
        jal   log_migrate_event

gc_migrate_next:                    # victim block 안의 다음 PBA 검사
        addiu $s7, $s7, 1
        j     gc_migrate_loop

gc_migrate_done:                    # VALID migration이 끝나면 victim block 전체 erase
        la    $a0, msg_gc_erase_block
        jal   print_string
        move  $a0, $s0
        jal   print_int
        la    $a0, msg_gc_block_free
        jal   print_string

        move  $a0, $s0
        jal   erase_block

        jal   recount_page_counts

        lw    $t0, gc_count
        addiu $t0, $t0, 1
        sw    $t0, gc_count

        lw    $t0, erase_count
        addiu $t0, $t0, 1
        sw    $t0, erase_count

        la    $a0, msg_gc_freed
        jal   print_string
        move  $a0, $s1
        jal   print_int
        jal   print_newline

        la    $a0, msg_gc_done
        jal   print_string

        move  $a0, $s1
        jal   log_gc_event
        j     gc_done

gc_no_victim:                       # INVALID page가 없으면 GC를 수행하지 않음
        la    $a0, msg_gc_no_victim
        jal   print_string
        j     gc_done

gc_no_space:                        # migration 목적지 FREE page가 부족한 경우
        la    $a0, msg_gc_no_space
        jal   print_string

gc_done:                            # 저장한 register 복구 후 종료
        lw    $ra, 44($sp)
        lw    $s0, 40($sp)
        lw    $s1, 36($sp)
        lw    $s2, 32($sp)
        lw    $s3, 28($sp)
        lw    $s4, 24($sp)
        lw    $s5, 20($sp)
        lw    $s6, 16($sp)
        lw    $s7, 12($sp)
        addiu $sp, $sp, 48
        jr    $ra
