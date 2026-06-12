# Demo scenario
# 이 demo는 GC migration을 눈으로 확인하기 위한 고정 시나리오다.
# 핵심 상태:
#   1) LBA 2를 두 번 쓰면 첫 PBA는 INVALID, 새 PBA는 VALID가 된다.
#   2) 같은 block 안의 LBA 1 VALID page를 GC가 다른 block으로 migration한다.
#   3) GC 후 LBA 1 read와 trace log로 data가 보존됐는지 확인한다.

        .text

run_demo_scenario:                  # overwrite -> migration GC -> read/trace 확인 순서로 실행
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # demo가 끝난 뒤 menu로 돌아가기 위한 복귀 주소

        la    $a0, msg_demo_hdr
        jal   print_string

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 1
        jal   print_int
        la    $a0, msg_demo_s1
        jal   print_string

        li    $a0, 2                # LBA 2를 처음 쓰면 보통 첫 FREE PBA(PBA 0)에 저장
        li    $a1, 100              # data = 100
        jal   ftl_write_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 2
        jal   print_int
        la    $a0, msg_demo_s2
        jal   print_string

        li    $a0, 1                # LBA 1은 다음 FREE PBA(PBA 1)에 저장되어 block 0에 남음
        li    $a1, 50               # data = 50
        jal   ftl_write_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 3
        jal   print_int
        la    $a0, msg_demo_s3
        jal   print_string

        li    $a0, 2                # overwrite 전 read가 정상인지 먼저 확인
        jal   ftl_read_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 4
        jal   print_int
        la    $a0, msg_demo_s4
        jal   print_string

        li    $a0, 2                # LBA 2 overwrite: old PBA 0은 INVALID, 새 PBA는 VALID
        li    $a1, 200              # data = 200
        jal   ftl_write_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 5
        jal   print_int
        la    $a0, msg_demo_s5
        jal   print_string

        li    $a0, 2                # mapping이 새 PBA를 가리켜서 200이 읽혀야 함
        jal   ftl_read_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 6
        jal   print_int
        la    $a0, msg_demo_s6
        jal   print_string

        jal   print_mapping_table   # GC 전 LBA 1/LBA 2가 어떤 PBA를 가리키는지 확인
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 7
        jal   print_int
        la    $a0, msg_demo_s7
        jal   print_string

        jal   print_physical_page_table
                                      # 여기서 block 0은 PBA 0 INVALID + PBA 1 VALID 상태가 됨
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 8
        jal   print_int
        la    $a0, msg_demo_s8
        jal   print_string

        jal   run_gc                 # block 0 victim 선택 후 PBA 1의 VALID page를 밖으로 이동
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 9
        jal   print_int
        la    $a0, msg_demo_s9
        jal   print_string

        li    $a0, 1                # migration 후에도 LBA 1은 data 50을 읽어야 함
        jal   ftl_read_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 10
        jal   print_int
        la    $a0, msg_demo_s10
        jal   print_string

        jal   print_mapping_table   # LBA 1 mapping이 old PBA 1에서 new PBA로 바뀐 것 확인
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 11
        jal   print_int
        la    $a0, msg_demo_s11
        jal   print_string

        jal   print_physical_page_table
                                      # victim block은 erase되어 PBA 0/PBA 1이 FREE가 되어야 함
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 12
        jal   print_int
        la    $a0, msg_demo_s12
        jal   print_string

        jal   print_trace_log       # MIGRATE event와 GC event가 순서대로 남는지 확인

        la    $a0, msg_demo_end
        jal   print_string

        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra

        .data
msg_demo_s1:  .asciiz ": Write 100 to LBA 2\n"
msg_demo_s2:  .asciiz ": Write 50 to LBA 1\n"
msg_demo_s3:  .asciiz ": Read LBA 2\n"
msg_demo_s4:  .asciiz ": Write 200 to LBA 2 again\n"
msg_demo_s5:  .asciiz ": Read LBA 2 again (expect 200)\n"
msg_demo_s6:  .asciiz ": Print mapping table before GC\n"
msg_demo_s7:  .asciiz ": Print physical page table before GC\n"
msg_demo_s8:  .asciiz ": Run GC (expect valid page migration)\n"
msg_demo_s9:  .asciiz ": Read LBA 1 after GC (expect 50)\n"
msg_demo_s10: .asciiz ": Print mapping table after GC\n"
msg_demo_s11: .asciiz ": Print physical page table after GC\n"
msg_demo_s12: .asciiz ": Print trace log\n"
