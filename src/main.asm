# =============================================================================
# main.asm  --  프로그램 시작점, 초기화, 메뉴 루프
#
# 파일 구성:
#   main.asm       - 진입점, 메뉴 루프
#   data.asm       - 전역 데이터, 상수, 배열, 통계 변수
#   util.asm       - 공통 유틸리티 함수
#   ftl_mapping.asm- LBA-PBA 매핑 테이블 함수
#   nand_model.asm - PBA 상태/데이터 관리 함수
#   ftl_write.asm  - Write Request 처리
#   ftl_read.asm   - Read Request 처리
#   gc.asm         - Simplified Garbage Collection
#   status.asm     - 테이블/통계 출력 함수
# =============================================================================

        .text
        .globl main

main:
        # $sp는 MARS가 초기화해주므로 별도 설정 불필요
        j     menu_loop

# -----------------------------------------------------------------------------
# menu_loop: 메뉴를 반복 출력하고 사용자 입력에 따라 분기한다
# -----------------------------------------------------------------------------
menu_loop:
        la    $a0, msg_menu
        jal   print_string
        jal   read_int             # $v0 = 선택 번호
        move  $t0, $v0

        beq   $t0, $zero, menu_exit
        beq   $t0, 1,     menu_write
        beq   $t0, 2,     menu_read
        beq   $t0, 3,     menu_map_table
        beq   $t0, 4,     menu_phys_table
        beq   $t0, 5,     menu_block
        beq   $t0, 6,     menu_stats
        beq   $t0, 7,     menu_trace
        beq   $t0, 8,     menu_status
        beq   $t0, 9,     menu_demo
        beq   $t0, 10,    menu_reset
        beq   $t0, 11,    menu_gc

        # 그 외 잘못된 입력
        la    $a0, msg_invalid_opt
        jal   print_string
        j     menu_loop

menu_write:
        jal   cmd_write
        j     menu_loop

menu_read:
        jal   cmd_read
        j     menu_loop

menu_map_table:
        jal   cmd_print_mapping
        j     menu_loop

menu_phys_table:
        jal   cmd_print_physical
        j     menu_loop

menu_block:
        jal   cmd_print_block
        j     menu_loop

menu_stats:
        jal   cmd_print_stats
        j     menu_loop

menu_trace:
        jal   cmd_print_trace
        j     menu_loop

menu_status:
        jal   cmd_full_status
        j     menu_loop

menu_demo:
        jal   cmd_demo
        j     menu_loop

menu_reset:
        jal   cmd_reset
        j     menu_loop

menu_gc:
        jal   cmd_gc
        j     menu_loop

menu_exit:
        la    $a0, msg_bye
        jal   print_string
        li    $v0, 10
        syscall
