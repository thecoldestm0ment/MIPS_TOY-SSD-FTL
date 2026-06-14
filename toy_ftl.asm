# 전역 상수, 배열, 문자열
        .eqv  LBA_COUNT,   4      # LBA는 0~3 사용
        .eqv  PBA_COUNT,   8      # PBA는 0~7 사용
        .eqv  FREE,        0      # 비어 있는 page
        .eqv  VALID,       1      # 유효한 page
        .eqv  INVALID,     2      # 오래된 page

        .eqv  TRACE_MAX,   20     # Trace 최대 개수
        .eqv  OUTPUT_DELAY_MS, 50  # 출력 후 잠깐 대기

        .eqv  TTYPE_WRITE, 1      # trace event: write
        .eqv  TTYPE_READ,  2      # trace event: read
        .eqv  TTYPE_GC,    3      # trace event: block erase GC
        .eqv  TTYPE_RESET, 4      # trace event: reset
        .eqv  TTYPE_MIGRATE, 5    # trace event: GC valid page migration
        .eqv  BLOCK_SIZE,  2      # block 하나에 들어가는 PBA 수
        .eqv  BLOCK_COUNT, 4      # 전체 block 수 = PBA_COUNT / BLOCK_SIZE

        .data

lba_map:            .word -1, -1, -1, -1
pba_state:          .word  0,  0,  0,  0,  0,  0,  0,  0
pba_data:           .word  0,  0,  0,  0,  0,  0,  0,  0

trace_type:  .word 0:20           # event 종류 저장
trace_lba:   .word 0:20           # 관련 LBA, 없으면 -1
trace_pba:   .word 0:20           # 관련 PBA 또는 migration 전 old PBA
trace_data:  .word 0:20           # data, freed count, 또는 migration 후 new PBA
trace_count: .word 0

total_write_count:    .word 0
total_read_count:     .word 0
total_state_count:    .word 0
total_simulated_time: .word 0
free_page_count:      .word 8
invalid_page_count:   .word 0
gc_count:             .word 0
erase_count:          .word 0

msg_menu: .asciiz "\n=== SSD FTL Simulator ===\n 1. Write request\n 2. Read request\n 3. Show mapping table\n 4. Show physical pages\n 5. Show statistics\n 6. Show trace log\n 7. Show full status\n 8. Run demo\n 9. Reset SSD\n10. Run GC\n 0. Exit\nSelect: "
msg_invalid_opt:
msg_invalid_op: .asciiz "Invalid menu option.\n"
msg_bye:        .asciiz "Exiting.\n"

msg_newline:    .asciiz "\n"
msg_separator:  .asciiz "-----------------------------\n"
msg_lba_prefix: .asciiz "LBA "
msg_pba_prefix: .asciiz "PBA "
msg_arrow_pba:  .asciiz " -> PBA "
msg_data_eq:    .asciiz ", data = "
msg_sep_state:  .asciiz " | State: "
msg_sep_data:   .asciiz " | data "
msg_colon_sp:   .asciiz ": "
msg_ms:         .asciiz " ms\n"
msg_state_op:   .asciiz "[State] "

msg_write_lba:  .asciiz "Enter LBA to write (0-3): "
msg_write_data: .asciiz "Enter data: "
msg_read_lba:   .asciiz "Enter LBA to read (0-3): "
msg_lba_range:  .asciiz "LBA is out of range.\n"

msg_sel_lba:    .asciiz "Selected LBA: "
msg_no_old_map: .asciiz "This LBA has no previous mapping.\n"
msg_old_pba:    .asciiz "Old PBA: "
msg_pba_inv_a:  .asciiz "PBA "
msg_pba_inv_b:  .asciiz " -> INVALID\n"
msg_new_pba:    .asciiz "Assigned new PBA: "
msg_write_ok:   .asciiz "Write complete.\n"
msg_no_free:    .asciiz "No free page. Run GC first.\n"

msg_read_lba_p: .asciiz "Reading LBA: "
msg_mapped_pba: .asciiz "Mapped PBA: "
msg_data_val:   .asciiz "data: "
msg_no_data:    .asciiz "No data for this LBA.\n"

msg_map_hdr:    .asciiz "[Mapping Table]\n"
msg_pba_hdr:    .asciiz "[Physical Page Table]\nState: 0=FREE, 1=VALID, 2=INVALID\n"
msg_stats_hdr:  .asciiz "[Statistics]\n"
msg_full_hdr:   .asciiz "\n======= Full SSD Status =======\n"
msg_full_end:   .asciiz "================================\n"

msg_st_writes:  .asciiz "Total WRITE count : "
msg_st_reads:   .asciiz "Total READ count  : "
msg_st_states:  .asciiz "State run count   : "
msg_st_time:    .asciiz "Total time (ms)   : "
msg_st_free:    .asciiz "FREE page count   : "
msg_st_valid:   .asciiz "VALID page count  : "
msg_st_inv:     .asciiz "INVALID page count: "
msg_st_gc:      .asciiz "GC run count      : "
msg_st_erase:   .asciiz "Block erase count : "

msg_ps_hdr:     .asciiz "[Page State Summary]\n"
msg_ps_free:    .asciiz "  FREE    : "
msg_ps_valid:   .asciiz "  VALID   : "
msg_ps_invalid: .asciiz "  INVALID : "

msg_gc_block_start: .asciiz "[GC] Scanning blocks...\n"
msg_gc_no_victim: .asciiz "[GC] No block has invalid pages.\n"
msg_gc_victim: .asciiz "[GC] Victim block: "
msg_gc_move:    .asciiz "[GC] Move valid page PBA "
msg_gc_to_pba:  .asciiz " -> PBA "
msg_gc_no_space: .asciiz "[GC] Not enough free page outside victim block.\n"
msg_gc_freed:   .asciiz "[GC] Freed page count: "
msg_gc_done:    .asciiz "[GC] Done\n"
msg_gc_erase_block: .asciiz "[GC] Erase block "
msg_gc_block_free:  .asciiz " -> FREE pages\n"

msg_trace_hdr:  .asciiz "[Trace Log]\n"
msg_trace_full: .asciiz "[Trace] Log is full.\n"
msg_trace_pipe: .asciiz " | "
msg_t_write:    .asciiz "WRITE"
msg_t_read:     .asciiz "READ "
msg_t_gc:       .asciiz "GC   "
msg_t_reset:    .asciiz "RESET"
msg_t_migrate:  .asciiz "MIGRATE"
msg_t_lba:      .asciiz " | LBA "
msg_t_pba:      .asciiz " | PBA "
msg_t_to_pba:   .asciiz " -> PBA "
msg_t_data:     .asciiz " | DATA "
msg_t_freed:    .asciiz " | Freed pages: "
msg_trace_none: .asciiz "(No recorded events)\n"

msg_reset_start: .asciiz "[Reset] Resetting SSD state...\n"
msg_reset_done:  .asciiz "[Reset] Reset complete.\n"

msg_demo_hdr:   .asciiz "\n--- Demo start ---\n"
msg_demo_step:  .asciiz "[Demo] Step "
msg_demo_end:   .asciiz "--- Demo end ---\n"

# 통합본 시작점
# MARS/RARS가 main이 아니라 첫 .text 명령부터 실행하는 설정일 때를 대비한다.
        .text

program_start:
        j     main                  # 실제 프로그램 시작점으로 이동

# 공용 입출력 함수

        .text

print_string:                       # $a0가 가리키는 문자열 출력
        li    $v0, 4                # 문자열 출력 준비
        syscall
        li    $a0, OUTPUT_DELAY_MS  
        li    $v0, 32
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

print_int:                          # $a0에 든 정수 출력
        li    $v0, 1                # 정수 출력 준비
        syscall
        li    $a0, OUTPUT_DELAY_MS  
        li    $v0, 32
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

print_newline:                      # 줄바꿈 1번 출력
        la    $a0, msg_newline      # 줄바꿈 문자열 주소
        li    $v0, 4                # 문자열 출력 준비
        syscall
        li    $a0, OUTPUT_DELAY_MS  
        li    $v0, 32
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

print_separator:                    # 구분선 출력
        la    $a0, msg_separator    # 구분선 문자열 주소
        li    $v0, 4                # 문자열 출력 준비
        syscall
        li    $a0, OUTPUT_DELAY_MS  
        li    $v0, 32
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

read_int:                           # 정수 하나를 입력받아 반환
        li    $v0, 5                # 정수 입력 준비
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

run_state:                          # 상태 메시지와 시간을 같이 처리
        addiu $sp, $sp, -12
        sw    $ra, 8($sp)           # 복귀 주소
        sw    $a0, 4($sp)           # 메시지 주소
        sw    $a1, 0($sp)           # duration

        la    $a0, msg_state_op     # "[상태] " 출력
        li    $v0, 4
        syscall

        lw    $a0, 4($sp)           # 원래 메시지 출력
        li    $v0, 4
        syscall

        lw    $a0, 0($sp)           # duration 출력
        li    $v0, 1
        syscall

        la    $a0, msg_ms           # 단위 출력
        li    $v0, 4
        syscall
        li    $a0, OUTPUT_DELAY_MS  
        li    $v0, 32
        syscall

        lw    $t0, total_state_count
        addiu $t0, $t0, 1           # 상태 실행 수 +1
        sw    $t0, total_state_count

        lw    $t0, total_simulated_time
        lw    $t1, 0($sp)
        add   $t0, $t0, $t1         # 누적 시간에 duration 더함
        sw    $t0, total_simulated_time

        lw    $a0, 0($sp)           # duration만큼 대기
        li    $v0, 32
        syscall

        lw    $ra, 8($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 12
        jr    $ra                   # 호출한 곳으로 복귀

# LBA-PBA 매핑

        .text

check_lba_range:                    # LBA가 0~3 범위인지 확인
        li    $v0, 0                # 기본값은 실패
        bltz  $a0, clr_fail         # LBA가 0보다 작으면 실패
        li    $t0, 4                # LBA 개수
        bge   $a0, $t0, clr_fail    # LBA가 4 이상이면 실패
        li    $v0, 1                # 범위 안이면 성공

clr_fail:                           # 검사 끝
        jr    $ra                   # 호출한 곳으로 복귀

get_lba_mapping:                    # lba_map[LBA] 값을 읽어 옴
        sll   $t0, $a0, 2           # offset = LBA * 4
        la    $t1, lba_map          # 배열 시작 주소
        add   $t1, $t1, $t0         # &lba_map[LBA]
        lw    $v0, 0($t1)           # lba_map[LBA] 반환
        jr    $ra                   # 호출한 곳으로 복귀

set_lba_mapping:                    # lba_map[LBA] = PBA
        sll   $t0, $a0, 2           # offset = LBA * 4
        la    $t1, lba_map          # 배열 시작 주소
        add   $t1, $t1, $t0         # &lba_map[LBA]
        sw    $a1, 0($t1)           # lba_map[LBA] = PBA
        jr    $ra                   # 호출한 곳으로 복귀

find_lba_by_pba:                    # 특정 PBA를 가리키는 LBA를 찾음
        li    $t0, 0                # lba = 0
        li    $t1, LBA_COUNT        # LBA 0~3까지 검사
        la    $t2, lba_map          # mapping table 시작 주소

flbp_loop:                          # lba_map[lba] == PBA인지 확인
        bge   $t0, $t1, flbp_none
        sll   $t3, $t0, 2
        add   $t4, $t2, $t3
        lw    $t5, 0($t4)
        beq   $t5, $a0, flbp_found
        addiu $t0, $t0, 1
        j     flbp_loop

flbp_found:                         # 해당 PBA를 가리키는 LBA 발견
        move  $v0, $t0              # 찾은 LBA 반환
        jr    $ra

flbp_none:                          # 해당 PBA를 가리키는 LBA가 없음
        li    $v0, -1               # 실패 값 반환
        jr    $ra

reset_mapping_table:                # 매핑 테이블을 전부 -1로 초기화
        li    $t0, 0                # i = 0
        li    $t1, 4                # 반복할 LBA 수
        la    $t2, lba_map          # 배열 시작 주소

rmt_loop:                           # lba_map[i] 초기화
        bge   $t0, $t1, rmt_done    # 끝까지 가면 종료
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t4, $t2, $t3         # &lba_map[i]
        li    $t5, -1               # 비어 있는 매핑 값
        sw    $t5, 0($t4)           # lba_map[i] = -1
        addiu $t0, $t0, 1           # i++
        j     rmt_loop

rmt_done:                           # 초기화 끝
        jr    $ra                   # 호출한 곳으로 복귀

print_mapping_table:                # LBA별 현재 매핑을 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # $ra 저장

        la    $a0, msg_map_hdr      # 헤더 출력
        jal   print_string

        li    $t0, 0                # i = 0
        li    $t1, 4                # LBA 개수
        la    $t2, lba_map          # 테이블 시작 주소

pmt_loop:                           # LBA 0~3 출력
        bge   $t0, $t1, pmt_done

        la    $a0, msg_lba_prefix   # "LBA "
        jal   print_string
        move  $a0, $t0              # 현재 LBA 출력
        jal   print_int
        la    $a0, msg_arrow_pba    # " -> PBA "
        jal   print_string

        sll   $t3, $t0, 2           # offset = i * 4
        add   $t4, $t2, $t3         # &lba_map[i]
        lw    $a0, 0($t4)           # 매핑된 PBA 출력
        jal   print_int
        jal   print_newline

        li    $t1, 4                # jal 뒤에 반복 끝 값 다시 준비
        la    $t2, lba_map          # jal 뒤에 테이블 주소 다시 준비
        addiu $t0, $t0, 1           # i++
        j     pmt_loop

pmt_done:                           # 출력 끝
        lw    $ra, 0($sp)           # $ra 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

# PBA 상태와 data 관리

        .text

find_free_pba_excluding_block:      # victim block 밖에서 FREE PBA를 찾음
        li    $t0, BLOCK_SIZE
        mul   $t1, $a0, $t0         # start_pba = block_id * BLOCK_SIZE
        add   $t2, $t1, $t0         # end_pba = start_pba + BLOCK_SIZE
        li    $t3, 0                # pba = 0

ffpeb_loop:                         # PBA 0~7을 순회
        li    $t4, PBA_COUNT
        bge   $t3, $t4, ffpeb_none

        blt   $t3, $t1, ffpeb_check # victim 시작 전이면 검사
        blt   $t3, $t2, ffpeb_next  # victim block 내부면 건너뜀

ffpeb_check:                        # victim 밖 PBA가 FREE인지 확인
        la    $t5, pba_state
        sll   $t6, $t3, 2
        add   $t5, $t5, $t6
        lw    $t7, 0($t5)
        beqz  $t7, ffpeb_found

ffpeb_next:                         # 다음 PBA로 이동
        addiu $t3, $t3, 1
        j     ffpeb_loop

ffpeb_found:                        # FREE PBA를 찾았으면 번호 반환
        move  $v0, $t3
        jr    $ra

ffpeb_none:                         # victim 밖에 FREE PBA가 없음
        li    $v0, -1
        jr    $ra

erase_block:                        # block 안의 모든 page를 FREE/data 0으로 erase
        li    $t0, BLOCK_SIZE
        mul   $t1, $a0, $t0         # start_pba
        add   $t2, $t1, $t0         # end_pba
        move  $t3, $t1

eb_loop:                            # block 시작 PBA부터 끝 PBA 전까지 초기화
        bge   $t3, $t2, eb_done
        sll   $t4, $t3, 2

        la    $t5, pba_state
        add   $t5, $t5, $t4
        sw    $zero, 0($t5)

        la    $t5, pba_data
        add   $t5, $t5, $t4
        sw    $zero, 0($t5)

        addiu $t3, $t3, 1
        j     eb_loop

eb_done:                            # block erase 완료
        jr    $ra

recount_page_counts:                # pba_state 전체를 다시 세서 count를 재계산
        li    $t0, 0                # pba = 0
        li    $t1, 0                # free_count = 0
        li    $t2, 0                # invalid_count = 0

rpc_loop:                           # 모든 PBA 상태 확인
        li    $t3, PBA_COUNT
        bge   $t0, $t3, rpc_done

        la    $t4, pba_state
        sll   $t5, $t0, 2
        add   $t4, $t4, $t5
        lw    $t6, 0($t4)

        li    $t7, FREE
        beq   $t6, $t7, rpc_count_free
        li    $t7, INVALID
        beq   $t6, $t7, rpc_count_invalid
        j     rpc_next

rpc_count_free:                     # FREE page 수 증가
        addiu $t1, $t1, 1
        j     rpc_next

rpc_count_invalid:                  # INVALID page 수 증가
        addiu $t2, $t2, 1

rpc_next:                           # 다음 PBA로 이동
        addiu $t0, $t0, 1
        j     rpc_loop

rpc_done:                           # 재계산한 count를 전역 변수에 저장
        sw    $t1, free_page_count
        sw    $t2, invalid_page_count
        jr    $ra

get_pba_state:                      # pba_state[PBA] 값을 읽어 옴
        sll   $t0, $a0, 2           # offset = PBA * 4
        la    $t1, pba_state        # 배열 시작 주소
        add   $t1, $t1, $t0         # &pba_state[PBA]
        lw    $v0, 0($t1)           # pba_state[PBA] 반환
        jr    $ra                   # 호출한 곳으로 복귀

set_pba_state:                      # pba_state[PBA] = state
        sll   $t0, $a0, 2           # offset = PBA * 4
        la    $t1, pba_state        # 배열 시작 주소
        add   $t1, $t1, $t0         # &pba_state[PBA]
        sw    $a1, 0($t1)           # 상태값 저장
        jr    $ra                   # 호출한 곳으로 복귀

get_pba_data:                       # pba_data[PBA] 값을 읽어 옴
        sll   $t0, $a0, 2           # offset = PBA * 4
        la    $t1, pba_data         # 배열 시작 주소
        add   $t1, $t1, $t0         # &pba_data[PBA]
        lw    $v0, 0($t1)           # data 반환
        jr    $ra                   # 호출한 곳으로 복귀

set_pba_data:                       # pba_data[PBA] = data
        sll   $t0, $a0, 2           # offset = PBA * 4
        la    $t1, pba_data         # 배열 시작 주소
        add   $t1, $t1, $t0         # &pba_data[PBA]
        sw    $a1, 0($t1)           # data 저장
        jr    $ra                   # 호출한 곳으로 복귀

find_free_pba:                      # 첫 번째 FREE PBA를 찾음
        li    $t0, 0                # i = 0
        li    $t1, 8                # PBA 개수
        la    $t2, pba_state        # 상태 배열 시작 주소

ffp_loop:                           # pba_state[i] 확인
        bge   $t0, $t1, ffp_none    # 끝까지 가면 실패

        sll   $t3, $t0, 2           # offset = i * 4
        add   $t4, $t2, $t3         # &pba_state[i]
        lw    $t5, 0($t4)           # pba_state[i]

        beqz  $t5, ffp_found        # 값이 0이면 바로 반환

        addiu $t0, $t0, 1           # i++
        j     ffp_loop

ffp_found:                          # FREE PBA를 찾음
        move  $v0, $t0              # 찾은 PBA 번호
        jr    $ra                   # 호출한 곳으로 복귀

ffp_none:                           # FREE PBA가 없음
        li    $v0, -1               # 실패 값 반환
        jr    $ra                   # 호출한 곳으로 복귀

reset_nand_table:                   # 상태와 data를 전부 초기화
        li    $t0, 0                # i = 0
        li    $t1, 8                # PBA 개수
        la    $t2, pba_state        # 상태 배열 시작 주소
        la    $t3, pba_data         # data 배열 시작 주소

rnt_loop:                           # i번째 PBA 초기화
        bge   $t0, $t1, rnt_done    # 끝까지 가면 종료

        sll   $t4, $t0, 2           # offset = i * 4
        add   $t5, $t2, $t4         # &pba_state[i]
        sw    $zero, 0($t5)         # pba_state[i] = FREE

        add   $t5, $t3, $t4         # &pba_data[i]
        sw    $zero, 0($t5)         # pba_data[i] = 0

        addiu $t0, $t0, 1           # i++
        j     rnt_loop

rnt_done:                           # 초기화 끝
        jr    $ra                   # 호출한 곳으로 복귀

print_physical_page_table:          # PBA 상태와 data를 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_pba_hdr      # 헤더 출력
        jal   print_string

        li    $t0, 0                # i = 0

pppt_loop:                          # PBA 0~7 출력
        li    $t1, 8                # PBA 개수
        bge   $t0, $t1, pppt_done

        la    $a0, msg_pba_prefix   # "PBA "
        jal   print_string
        move  $a0, $t0              # 현재 PBA 출력
        jal   print_int

        la    $a0, msg_sep_state    # 상태 구분자
        jal   print_string

        la    $t2, pba_state        # 상태 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &pba_state[i]
        lw    $a0, 0($t2)           # 상태 출력
        jal   print_int

        la    $a0, msg_sep_data     # data 구분자
        jal   print_string

        la    $t2, pba_data         # data 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &pba_data[i]
        lw    $a0, 0($t2)           # data 출력
        jal   print_int
        jal   print_newline

        addiu $t0, $t0, 1           # i++
        j     pppt_loop

pppt_done:                          # 출력 끝
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

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

# 통계와 상태 출력

        .text

count_valid_pages:                  # VALID page 개수를 셈
        li    $t0, 0                # i = 0
        li    $t1, 8                # PBA 개수
        la    $t2, pba_state        # 상태 배열 시작 주소
        li    $v0, 0                # count = 0

cvp_loop:                           # pba_state[i] 확인
        bge   $t0, $t1, cvp_done

        sll   $t3, $t0, 2           # offset = i * 4
        add   $t4, $t2, $t3         # &pba_state[i]
        lw    $t5, 0($t4)           # pba_state[i]

        li    $t6, 1                # VALID 값
        bne   $t5, $t6, cvp_next
        addiu $v0, $v0, 1           # VALID면 count++

cvp_next:                           # 다음 page로 이동
        addiu $t0, $t0, 1           # i++
        j     cvp_loop

cvp_done:                           # 계산 끝
        jr    $ra                   # 호출한 곳으로 복귀

print_page_state_summary:           # FREE, VALID, INVALID 요약 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_ps_hdr       # 헤더 출력
        jal   print_string

        la    $a0, msg_ps_free      # FREE 개수 출력
        jal   print_string
        lw    $a0, free_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_ps_valid     # VALID 개수 출력
        jal   print_string
        jal   count_valid_pages
        move  $a0, $v0
        jal   print_int
        jal   print_newline

        la    $a0, msg_ps_invalid   # INVALID 개수 출력
        jal   print_string
        lw    $a0, invalid_page_count
        jal   print_int
        jal   print_newline

        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

print_statistics:                   # 누적 통계 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_stats_hdr    # 헤더 출력
        jal   print_string

        la    $a0, msg_st_writes    # WRITE 수 출력
        jal   print_string
        lw    $a0, total_write_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_reads     # READ 수 출력
        jal   print_string
        lw    $a0, total_read_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_states    # 상태 실행 수 출력
        jal   print_string
        lw    $a0, total_state_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_time      # 누적 시간 출력
        jal   print_string
        lw    $a0, total_simulated_time
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_free      # FREE page 수 출력
        jal   print_string
        lw    $a0, free_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_valid     # VALID page 수 출력
        jal   print_string
        jal   count_valid_pages
        move  $a0, $v0
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_inv       # INVALID page 수 출력
        jal   print_string
        lw    $a0, invalid_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_gc        # GC 횟수 출력
        jal   print_string
        lw    $a0, gc_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_erase
        jal   print_string
        lw    $a0, erase_count
        jal   print_int
        jal   print_newline

        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

print_full_status:                  # 전체 상태를 한 번에 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_full_hdr     # 전체 상태 헤더
        jal   print_string

        jal   print_statistics
        jal   print_separator

        jal   print_page_state_summary
        jal   print_separator

        jal   print_mapping_table
        jal   print_separator

        jal   print_physical_page_table
        jal   print_separator

        jal   print_trace_log

        la    $a0, msg_full_end     # 전체 상태 끝 표시
        jal   print_string

        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

# 쓰기 처리

        .text

submit_write_request:               # 입력받은 LBA/data로 write core 호출
        addiu $sp, $sp, -12
        sw    $ra, 8($sp)
        sw    $s0, 4($sp)
        sw    $s1, 0($sp)

        la    $a0, msg_write_lba
        jal   print_string
        jal   read_int
        move  $s0, $v0

        move  $a0, $s0
        jal   check_lba_range
        beqz  $v0, swr_bad_lba

        la    $a0, msg_write_data
        jal   print_string
        jal   read_int
        move  $s1, $v0

        move  $a0, $s0
        move  $a1, $s1
        jal   ftl_write_core
        j     swr_done

swr_bad_lba:                        # LBA 범위가 잘못된 경우
        la    $a0, msg_lba_range
        jal   print_string

swr_done:                           # 입력 처리 종료
        lw    $ra, 8($sp)
        lw    $s0, 4($sp)
        lw    $s1, 0($sp)
        addiu $sp, $sp, 12
        jr    $ra

ftl_write_core:                     # out-of-place write로 새 PBA에 data 저장
        addiu $sp, $sp, -20
        sw    $ra, 16($sp)
        sw    $s0, 12($sp)          # lba
        sw    $s1,  8($sp)          # data
        sw    $s2,  4($sp)          # old_pba
        sw    $s3,  0($sp)          # new_pba

        move  $s0, $a0
        move  $s1, $a1

        la    $a0, msg_sel_lba
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        move  $a0, $s0              # 기존 mapping 확인
        jal   get_lba_mapping
        move  $s2, $v0

        jal   find_free_pba         # 상태 변경 전에 새 FREE PBA를 먼저 찾음
        move  $s3, $v0

        li    $t0, -1
        beq   $s3, $t0, fwc_no_free # 실패 시 기존 mapping/PBA는 건드리지 않음

        li    $t0, -1
        beq   $s2, $t0, fwc_no_old

        la    $a0, msg_old_pba
        jal   print_string
        move  $a0, $s2
        jal   print_int
        jal   print_newline

        la    $a0, msg_pba_inv_a
        jal   print_string
        move  $a0, $s2
        jal   print_int
        la    $a0, msg_pba_inv_b
        jal   print_string

        move  $a0, $s2              # overwrite이면 old PBA를 INVALID 처리
        li    $a1, INVALID
        jal   set_pba_state
        j     fwc_program_new

fwc_no_old:                         # 처음 쓰는 LBA라면 invalid 처리할 old PBA가 없음
        la    $a0, msg_no_old_map
        jal   print_string

fwc_program_new:                    # 새 PBA에 data를 쓰고 mapping 갱신
        move  $a0, $s3
        li    $a1, VALID
        jal   set_pba_state

        move  $a0, $s3
        move  $a1, $s1
        jal   set_pba_data

        move  $a0, $s0
        move  $a1, $s3
        jal   set_lba_mapping

        jal   recount_page_counts   # 수동 증감 대신 실제 pba_state 기준으로 count 재계산

        lw    $t0, total_write_count
        addiu $t0, $t0, 1
        sw    $t0, total_write_count

        la    $a0, msg_new_pba
        jal   print_string
        move  $a0, $s3
        jal   print_int
        jal   print_newline

        la    $a0, msg_lba_prefix
        jal   print_string
        move  $a0, $s0
        jal   print_int
        la    $a0, msg_arrow_pba
        jal   print_string
        move  $a0, $s3
        jal   print_int
        la    $a0, msg_data_eq
        jal   print_string
        move  $a0, $s1
        jal   print_int
        jal   print_newline

        move  $a0, $s0
        move  $a1, $s3
        move  $a2, $s1
        jal   log_write_event

        la    $a0, msg_write_ok
        li    $a1, 1
        jal   run_state
        j     fwc_done

fwc_no_free:                        # FREE PBA가 없으면 write 실패, trace/count 변경 없음
        la    $a0, msg_no_free
        jal   print_string

fwc_done:                           # 저장한 register 복구 후 종료
        lw    $ra, 16($sp)
        lw    $s0, 12($sp)
        lw    $s1,  8($sp)
        lw    $s2,  4($sp)
        lw    $s3,  0($sp)
        addiu $sp, $sp, 20
        jr    $ra

# 읽기 처리

        .text

submit_read_request:                # 입력받은 LBA로 읽기 함수 호출
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)           # 복귀 주소
        sw    $s0, 0($sp)           # 입력받은 LBA

        la    $a0, msg_read_lba     # LBA 입력 안내
        jal   print_string
        jal   read_int
        move  $s0, $v0              # 입력된 LBA

        move  $a0, $s0              # 범위 검사할 LBA
        jal   check_lba_range
        beqz  $v0, srr_bad          # 범위 밖이면 에러 출력

        move  $a0, $s0              # 읽을 LBA 전달
        jal   ftl_read_core
        j     srr_done

srr_bad:                            # 잘못된 LBA 입력
        la    $a0, msg_lba_range
        jal   print_string

srr_done:                           # 입력 처리 끝
        lw    $ra, 4($sp)           # 복귀 주소 복구
        lw    $s0, 0($sp)           # 저장한 LBA 복구
        addiu $sp, $sp, 8
        jr    $ra                   # 호출한 곳으로 복귀

ftl_read_core:                      # LBA에 연결된 data를 읽어서 출력
        addiu $sp, $sp, -12
        sw    $ra,  8($sp)          # 복귀 주소
        sw    $s0,  4($sp)          # LBA
        sw    $s1,  0($sp)          # PBA

        move  $s0, $a0              # 현재 LBA

        la    $a0, msg_read_lba_p   # 읽는 LBA 표시
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        move  $a0, $s0              # mapping 먼저 확인
        jal   get_lba_mapping
        move  $s1, $v0              # PBA

        li    $t0, -1
        beq   $s1, $t0, frc_no_data # mapping 없으면 종료

        la    $a0, msg_mapped_pba   # 연결된 PBA 출력
        jal   print_string
        move  $a0, $s1
        jal   print_int
        jal   print_newline

        move  $a0, $s1              # PBA에 저장된 data 읽기
        jal   get_pba_data
        move  $s0, $v0              # syscall 출력 전에 data를 먼저 보관

        la    $a0, msg_data_val     # data 출력
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        lw    $t0, total_read_count
        addiu $t0, $t0, 1           # READ 횟수 +1
        sw    $t0, total_read_count

        lw    $t1, 4($sp)           # 원래 LBA 복구
        move  $a0, $t1              # lba
        move  $a1, $s1              # pba
        move  $a2, $s0              # data
        jal   log_read_event

        j     frc_done

frc_no_data:                        # 아직 data가 없는 LBA
        la    $a0, msg_no_data
        jal   print_string

frc_done:                           # 읽기 처리 끝
        lw    $ra,  8($sp)          # 복귀 주소 복구
        lw    $s0,  4($sp)          # LBA 복구
        lw    $s1,  0($sp)          # PBA 복구
        addiu $sp, $sp, 12
        jr    $ra                   # 호출한 곳으로 복귀

# SSD 초기화

        .text

reset_ssd:                          # SSD 상태를 처음으로 돌림
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_reset_start  # reset 시작 메시지
        jal   print_string

        jal   reset_nand_table
        jal   reset_mapping_table
        jal   reset_statistics
        jal   reset_trace_log
        jal   log_reset_event       # reset 이벤트도 Trace에 남김

        la    $a0, msg_reset_done   # reset 완료 메시지
        jal   print_string

        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

reset_statistics:                   # 통계 값을 처음 상태로 돌림
        sw    $zero, total_write_count
        sw    $zero, total_read_count
        sw    $zero, total_state_count
        sw    $zero, total_simulated_time
        sw    $zero, invalid_page_count
        sw    $zero, gc_count
        sw    $zero, erase_count

        li    $t0, 8                # 시작할 때는 FREE page가 8개
        sw    $t0, free_page_count

        jr    $ra                   # 호출한 곳으로 복귀

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

# 메뉴용 래퍼 함수

        .text
        .globl cmd_write, cmd_read
        .globl cmd_print_mapping, cmd_print_physical
        .globl cmd_print_stats
        .globl cmd_print_trace, cmd_full_status
        .globl cmd_demo, cmd_reset, cmd_gc

cmd_write:                          # 쓰기 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   submit_write_request
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_read:                           # 읽기 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   submit_read_request
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_print_mapping:                  # 매핑 테이블 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   print_mapping_table
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_print_physical:                 # 물리 페이지 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   print_physical_page_table
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_print_stats:                    # 통계 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   print_statistics
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_print_trace:                    # Trace 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   print_trace_log
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_full_status:                    # 전체 상태 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   print_full_status
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_demo:                           # demo 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   run_demo_scenario
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_reset:                          # reset 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   reset_ssd
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

cmd_gc:                             # GC 메뉴 처리
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소
        jal   run_gc
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

# 메인 메뉴

        .text

main:
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
