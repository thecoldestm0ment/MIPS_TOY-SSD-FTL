# 메인 메뉴

        .text
        .globl main

main:                               # 프로그램 시작
        j     menu_loop             # 바로 메뉴로 이동

menu_loop:                          # 메뉴를 계속 반복
        la    $a0, msg_menu         # 메뉴 문자열 출력
        jal   print_string
        jal   read_int              # 메뉴 번호 입력
        move  $t0, $v0              # 입력값 보관

        beq   $t0, $zero, menu_exit
        beq   $t0, 1,     menu_write
        beq   $t0, 2,     menu_read
        beq   $t0, 3,     menu_map_table
        beq   $t0, 4,     menu_phys_table
        beq   $t0, 5,     menu_stats
        beq   $t0, 6,     menu_trace
        beq   $t0, 7,     menu_status
        beq   $t0, 8,     menu_demo
        beq   $t0, 9,     menu_reset
        beq   $t0, 10,    menu_gc

        la    $a0, msg_invalid_opt  # 잘못된 번호 안내
        jal   print_string
        j     menu_loop

menu_write:                         # 쓰기 메뉴
        jal   cmd_write
        j     menu_loop

menu_read:                          # 읽기 메뉴
        jal   cmd_read
        j     menu_loop

menu_map_table:                     # 매핑 테이블 메뉴
        jal   cmd_print_mapping
        j     menu_loop

menu_phys_table:                    # 물리 페이지 메뉴
        jal   cmd_print_physical
        j     menu_loop

menu_stats:                         # 통계 메뉴
        jal   cmd_print_stats
        j     menu_loop

menu_trace:                         # Trace 메뉴
        jal   cmd_print_trace
        j     menu_loop

menu_status:                        # 전체 상태 메뉴
        jal   cmd_full_status
        j     menu_loop

menu_demo:                          # demo 메뉴
        jal   cmd_demo
        j     menu_loop

menu_reset:                         # reset 메뉴
        jal   cmd_reset
        j     menu_loop

menu_gc:                            # GC 메뉴
        jal   cmd_gc
        j     menu_loop

menu_exit:                          # 프로그램 종료
        la    $a0, msg_bye
        jal   print_string
        li    $v0, 10
        syscall
