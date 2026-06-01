# demo 시나리오

        .text

run_demo_scenario:                  # 정해진 순서대로 기능 확인
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_demo_hdr     # demo 시작 메시지
        jal   print_string

        la    $a0, msg_demo_step    # 1단계 안내
        jal   print_string
        li    $a0, 1
        jal   print_int
        la    $a0, msg_demo_s1
        jal   print_string

        li    $a0, 2                # LBA = 2
        li    $a1, 100              # data = 100
        jal   ftl_write_core

        jal   print_separator

        la    $a0, msg_demo_step    # 2단계 안내
        jal   print_string
        li    $a0, 2
        jal   print_int
        la    $a0, msg_demo_s2
        jal   print_string

        li    $a0, 1                # LBA = 1
        li    $a1, 50               # data = 50
        jal   ftl_write_core

        jal   print_separator

        la    $a0, msg_demo_step    # 3단계 안내
        jal   print_string
        li    $a0, 3
        jal   print_int
        la    $a0, msg_demo_s3
        jal   print_string

        li    $a0, 2                # LBA = 2
        jal   ftl_read_core

        jal   print_separator

        la    $a0, msg_demo_step    # 4단계 안내
        jal   print_string
        li    $a0, 4
        jal   print_int
        la    $a0, msg_demo_s4
        jal   print_string

        li    $a0, 2                # LBA = 2
        li    $a1, 200              # data = 200
        jal   ftl_write_core

        jal   print_separator

        la    $a0, msg_demo_step    # 5단계 안내
        jal   print_string
        li    $a0, 5
        jal   print_int
        la    $a0, msg_demo_s5
        jal   print_string

        li    $a0, 2                # LBA = 2
        jal   ftl_read_core

        jal   print_separator

        la    $a0, msg_demo_step    # 6단계 안내
        jal   print_string
        li    $a0, 6
        jal   print_int
        la    $a0, msg_demo_s6
        jal   print_string

        jal   print_mapping_table

        jal   print_separator

        la    $a0, msg_demo_step    # 7단계 안내
        jal   print_string
        li    $a0, 7
        jal   print_int
        la    $a0, msg_demo_s7
        jal   print_string

        jal   print_physical_page_table

        jal   print_separator

        la    $a0, msg_demo_step    # 8단계 안내
        jal   print_string
        li    $a0, 8
        jal   print_int
        la    $a0, msg_demo_s8
        jal   print_string

        jal   run_simple_gc

        jal   print_separator

        la    $a0, msg_demo_step    # 9단계 안내
        jal   print_string
        li    $a0, 9
        jal   print_int
        la    $a0, msg_demo_s9
        jal   print_string

        jal   print_physical_page_table

        jal   print_separator

        la    $a0, msg_demo_step    # 10단계 안내
        jal   print_string
        li    $a0, 10
        jal   print_int
        la    $a0, msg_demo_s10
        jal   print_string

        jal   print_trace_log

        la    $a0, msg_demo_end     # demo 끝 메시지
        jal   print_string

        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

        .data
msg_demo_s1:  .asciiz ": Write 100 to LBA 2\n"
msg_demo_s2:  .asciiz ": Write 50 to LBA 1\n"
msg_demo_s3:  .asciiz ": Read LBA 2\n"
msg_demo_s4:  .asciiz ": Write 200 to LBA 2 again\n"
msg_demo_s5:  .asciiz ": Read LBA 2 again (expect 200)\n"
msg_demo_s6:  .asciiz ": Print mapping table\n"
msg_demo_s7:  .asciiz ": Print physical page table\n"
msg_demo_s8:  .asciiz ": Run GC\n"
msg_demo_s9:  .asciiz ": Print physical page table after GC\n"
msg_demo_s10: .asciiz ": Print trace log\n"
