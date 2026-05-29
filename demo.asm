# =============================================================================
# demo.asm  --  Demo Scenario
#
# 사용자가 직접 입력하지 않아도 FTL 동작 흐름을 한 번에 확인할 수 있다.
# ftl_write_core / ftl_read_core를 직접 호출하여 정해진 시나리오를 실행한다.
#
# 시나리오 순서:
#   Step 1: Write LBA 2, data 100
#   Step 2: Write LBA 1, data 50
#   Step 3: Read LBA 2
#   Step 4: Overwrite LBA 2, data 200  (out-of-place update 확인)
#   Step 5: Read LBA 2
#   Step 6: Print Mapping Table
#   Step 7: Print Physical Page Table
#   Step 8: Run Simple GC
#   Step 9: Print Physical Page Table (GC 후)
#   Step 10: Print Trace Log
# =============================================================================

        .text

# -----------------------------------------------------------------------------
# run_demo_scenario
#   역할  : 위 시나리오를 순서대로 실행한다
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
run_demo_scenario:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_demo_hdr
        jal   print_string

        # Step 1: Write LBA 2, data 100
        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 1
        jal   print_int
        la    $a0, msg_demo_s1
        jal   print_string

        li    $a0, 2               # LBA = 2
        li    $a1, 100             # data = 100
        jal   ftl_write_core

        jal   print_separator

        # Step 2: Write LBA 1, data 50
        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 2
        jal   print_int
        la    $a0, msg_demo_s2
        jal   print_string

        li    $a0, 1               # LBA = 1
        li    $a1, 50              # data = 50
        jal   ftl_write_core

        jal   print_separator

        # Step 3: Read LBA 2
        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 3
        jal   print_int
        la    $a0, msg_demo_s3
        jal   print_string

        li    $a0, 2
        jal   ftl_read_core

        jal   print_separator

        # Step 4: Overwrite LBA 2, data 200
        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 4
        jal   print_int
        la    $a0, msg_demo_s4
        jal   print_string

        li    $a0, 2               # LBA = 2
        li    $a1, 200             # data = 200
        jal   ftl_write_core

        jal   print_separator

        # Step 5: Read LBA 2 (새 값 200이 읽혀야 한다)
        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 5
        jal   print_int
        la    $a0, msg_demo_s5
        jal   print_string

        li    $a0, 2
        jal   ftl_read_core

        jal   print_separator

        # Step 6: Print Mapping Table
        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 6
        jal   print_int
        la    $a0, msg_demo_s6
        jal   print_string

        jal   print_mapping_table

        jal   print_separator

        # Step 7: Print Physical Page Table
        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 7
        jal   print_int
        la    $a0, msg_demo_s7
        jal   print_string

        jal   print_physical_page_table

        jal   print_separator

        # Step 8: Run Simple GC
        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 8
        jal   print_int
        la    $a0, msg_demo_s8
        jal   print_string

        jal   run_simple_gc

        jal   print_separator

        # Step 9: Print Physical Page Table (GC 후)
        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 9
        jal   print_int
        la    $a0, msg_demo_s9
        jal   print_string

        jal   print_physical_page_table

        jal   print_separator

        # Step 10: Print Trace Log
        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 10
        jal   print_int
        la    $a0, msg_demo_s10
        jal   print_string

        jal   print_trace_log

        la    $a0, msg_demo_end
        jal   print_string

        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

        .data
msg_demo_s1:  .asciiz ": Write LBA 2, data 100\n"
msg_demo_s2:  .asciiz ": Write LBA 1, data 50\n"
msg_demo_s3:  .asciiz ": Read LBA 2\n"
msg_demo_s4:  .asciiz ": Overwrite LBA 2, data 200\n"
msg_demo_s5:  .asciiz ": Read LBA 2 (expect 200)\n"
msg_demo_s6:  .asciiz ": Print Mapping Table\n"
msg_demo_s7:  .asciiz ": Print Physical Page Table\n"
msg_demo_s8:  .asciiz ": Run Simple GC\n"
msg_demo_s9:  .asciiz ": Print Physical Page Table (after GC)\n"
msg_demo_s10: .asciiz ": Print Trace Log\n"
