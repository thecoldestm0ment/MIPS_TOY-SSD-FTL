# 전역 상수, 배열, 문자열
        .eqv  LBA_COUNT,   4      # LBA는 0~3 사용
        .eqv  PBA_COUNT,   8      # PBA는 0~7 사용
        .eqv  FREE,        0      # 비어 있는 page
        .eqv  VALID,       1      # 유효한 page
        .eqv  INVALID,     2      # 오래된 page

        .eqv  TRACE_MAX,   20     # Trace 최대 개수

        .eqv  TTYPE_WRITE, 1
        .eqv  TTYPE_READ,  2
        .eqv  TTYPE_GC,    3
        .eqv  TTYPE_RESET, 4
        .eqv  BLOCK_SIZE,  2
        .eqv  BLOCK_COUNT, 4

        .data

lba_map:            .word -1, -1, -1, -1
pba_state:          .word  0,  0,  0,  0,  0,  0,  0,  0
pba_data:           .word  0,  0,  0,  0,  0,  0,  0,  0

trace_type:  .word 0:20
trace_lba:   .word 0:20
trace_pba:   .word 0:20
trace_data:  .word 0:20
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

msg_gc_start:   .asciiz "[GC] Scanning INVALID pages...\n"
msg_gc_block_start: .asciiz "[GC] Scanning blocks...\n"
msg_gc_freed:   .asciiz "[GC] Freed page count: "
msg_gc_done:    .asciiz "[GC] Done\n"
msg_gc_pba_ok:  .asciiz "[GC] PBA "
msg_gc_to_free: .asciiz " -> FREE\n"
msg_gc_erase_block: .asciiz "[GC] Erase block "
msg_gc_block_free:  .asciiz " -> FREE pages\n"

msg_trace_hdr:  .asciiz "[Trace Log]\n"
msg_trace_full: .asciiz "[Trace] Log is full.\n"
msg_trace_pipe: .asciiz " | "
msg_t_write:    .asciiz "WRITE"
msg_t_read:     .asciiz "READ "
msg_t_gc:       .asciiz "GC   "
msg_t_reset:    .asciiz "RESET"
msg_t_lba:      .asciiz " | LBA "
msg_t_pba:      .asciiz " | PBA "
msg_t_data:     .asciiz " | DATA "
msg_t_freed:    .asciiz " | Freed pages: "
msg_trace_none: .asciiz "(No recorded events)\n"

msg_reset_start: .asciiz "[Reset] Resetting SSD state...\n"
msg_reset_done:  .asciiz "[Reset] Reset complete.\n"

msg_demo_hdr:   .asciiz "\n--- Demo start ---\n"
msg_demo_step:  .asciiz "[Demo] Step "
msg_demo_end:   .asciiz "--- Demo end ---\n"

# 공용 입출력 함수

        .text

print_string:                       # $a0가 가리키는 문자열 출력
        li    $v0, 4                # 문자열 출력 준비
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

print_int:                          # $a0에 든 정수 출력
        li    $v0, 1                # 정수 출력 준비
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

print_newline:                      # 줄바꿈 1번 출력
        la    $a0, msg_newline      # 줄바꿈 문자열 주소
        li    $v0, 4                # 문자열 출력 준비
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

print_separator:                    # 구분선 출력
        la    $a0, msg_separator    # 구분선 문자열 주소
        li    $v0, 4                # 문자열 출력 준비
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

# Trace 기록과 출력

        .text

log_write_event:                    # WRITE 이벤트를 Trace에 기록
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)          # 복귀 주소
        sw    $a0,  8($sp)          # lba
        sw    $a1,  4($sp)          # pba
        sw    $a2,  0($sp)          # data

        jal   trace_check_full
        bnez  $v0, lwe_done         # Trace가 가득 찼으면 종료

        lw    $t0, trace_count      # 현재 Trace index
        sll   $t1, $t0, 2           # offset = index * 4

        la    $t2, trace_type       # type 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_type[index]
        li    $t3, 1
        sw    $t3, 0($t2)           # type = WRITE

        la    $t2, trace_lba        # lba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_lba[index]
        lw    $t3, 8($sp)           # lba
        sw    $t3, 0($t2)

        la    $t2, trace_pba        # pba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_pba[index]
        lw    $t3, 4($sp)           # pba
        sw    $t3, 0($t2)

        la    $t2, trace_data       # data 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_data[index]
        lw    $t3, 0($sp)           # data
        sw    $t3, 0($t2)

        addiu $t0, $t0, 1           # trace_count++
        sw    $t0, trace_count

lwe_done:                           # WRITE 기록 끝
        lw    $ra, 12($sp)          # 복귀 주소 복구
        addiu $sp, $sp, 16
        jr    $ra                   # 호출한 곳으로 복귀

log_read_event:                     # READ 이벤트를 Trace에 기록
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)          # 복귀 주소
        sw    $a0,  8($sp)          # lba
        sw    $a1,  4($sp)          # pba
        sw    $a2,  0($sp)          # data

        jal   trace_check_full
        bnez  $v0, lre_done         # Trace가 가득 찼으면 종료

        lw    $t0, trace_count      # 현재 Trace index
        sll   $t1, $t0, 2           # offset = index * 4

        la    $t2, trace_type       # type 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_type[index]
        li    $t3, 2
        sw    $t3, 0($t2)           # type = READ

        la    $t2, trace_lba        # lba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_lba[index]
        lw    $t3, 8($sp)           # lba
        sw    $t3, 0($t2)

        la    $t2, trace_pba        # pba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_pba[index]
        lw    $t3, 4($sp)           # pba
        sw    $t3, 0($t2)

        la    $t2, trace_data       # data 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_data[index]
        lw    $t3, 0($sp)           # data
        sw    $t3, 0($t2)

        addiu $t0, $t0, 1           # trace_count++
        sw    $t0, trace_count

lre_done:                           # READ 기록 끝
        lw    $ra, 12($sp)          # 복귀 주소 복구
        addiu $sp, $sp, 16
        jr    $ra                   # 호출한 곳으로 복귀

log_gc_event:                       # GC 이벤트를 Trace에 기록
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)           # 복귀 주소
        sw    $a0, 0($sp)           # freed count

        jal   trace_check_full
        bnez  $v0, lge_done         # Trace가 가득 찼으면 종료

        lw    $t0, trace_count      # 현재 Trace index
        sll   $t1, $t0, 2           # offset = index * 4

        la    $t2, trace_type       # type 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_type[index]
        li    $t3, 3
        sw    $t3, 0($t2)           # type = GC

        la    $t2, trace_lba        # lba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_lba[index]
        li    $t3, -1
        sw    $t3, 0($t2)           # GC는 lba 없음

        la    $t2, trace_pba        # pba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_pba[index]
        sw    $t3, 0($t2)           # GC는 pba 없음

        la    $t2, trace_data       # data 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_data[index]
        lw    $t3, 0($sp)           # freed count
        sw    $t3, 0($t2)

        addiu $t0, $t0, 1           # trace_count++
        sw    $t0, trace_count

lge_done:                           # GC 기록 끝
        lw    $ra, 4($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 8
        jr    $ra                   # 호출한 곳으로 복귀

log_reset_event:                    # RESET 이벤트를 Trace에 기록
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        jal   trace_check_full
        bnez  $v0, lrese_done       # Trace가 가득 찼으면 종료

        lw    $t0, trace_count      # 현재 Trace index
        sll   $t1, $t0, 2           # offset = index * 4

        la    $t2, trace_type       # type 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_type[index]
        li    $t3, 4
        sw    $t3, 0($t2)           # type = RESET

        la    $t2, trace_lba        # lba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_lba[index]
        li    $t3, -1
        sw    $t3, 0($t2)           # RESET은 lba 없음

        la    $t2, trace_pba        # pba 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_pba[index]
        sw    $t3, 0($t2)           # RESET은 pba 없음

        la    $t2, trace_data       # data 배열 시작 주소
        add   $t2, $t2, $t1         # &trace_data[index]
        sw    $zero, 0($t2)         # RESET은 data 없음

        addiu $t0, $t0, 1           # trace_count++
        sw    $t0, trace_count

lrese_done:                         # RESET 기록 끝
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

trace_check_full:                   # Trace가 가득 찼는지 확인
        lw    $t0, trace_count      # 현재 기록 개수
        li    $t1, 20               # 최대 20개
        li    $v0, 0                # 기본값은 여유 있음
        blt   $t0, $t1, tcf_ok      # 20 미만이면 기록 가능
        li    $v0, 1                # 20 이상이면 가득 참

tcf_ok:                             # 검사 끝
        jr    $ra                   # 호출한 곳으로 복귀

print_trace_log:                    # Trace 내용을 순서대로 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_trace_hdr    # 헤더 출력
        jal   print_string

        lw    $t0, trace_count      # 기록 개수 확인
        beqz  $t0, ptl_empty        # 아무 것도 없으면 안내 출력

        li    $t0, 0                # i = 0

ptl_loop:                           # Trace i번째 출력
        lw    $t1, trace_count
        bge   $t0, $t1, ptl_done

        move  $a0, $t0              # index 출력
        jal   print_int
        la    $a0, msg_trace_pipe
        jal   print_string

        la    $t2, trace_type       # type 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &trace_type[i]
        lw    $t4, 0($t2)           # type 값

        li    $t5, 1
        beq   $t4, $t5, ptl_write
        li    $t5, 2
        beq   $t4, $t5, ptl_read
        li    $t5, 3
        beq   $t4, $t5, ptl_gc
        li    $t5, 4
        beq   $t4, $t5, ptl_reset
        j     ptl_type_done

ptl_write:                          # WRITE 타입 출력
        la    $a0, msg_t_write
        jal   print_string
        j     ptl_print_lba

ptl_read:                           # READ 타입 출력
        la    $a0, msg_t_read
        jal   print_string
        j     ptl_print_lba

ptl_gc:                             # GC 타입 출력
        la    $a0, msg_t_gc
        jal   print_string

        la    $t2, trace_data       # data 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &trace_data[i]
        lw    $a2, 0($t2)           # freed count

        la    $a0, msg_t_freed
        jal   print_string
        move  $a0, $a2
        jal   print_int
        jal   print_newline
        j     ptl_next

ptl_reset:                          # RESET 타입 출력
        la    $a0, msg_t_reset
        jal   print_string
        jal   print_newline
        j     ptl_next

ptl_print_lba:                      # LBA, PBA, DATA 출력
        la    $a0, msg_t_lba
        jal   print_string
        la    $t2, trace_lba        # lba 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &trace_lba[i]
        lw    $a0, 0($t2)           # lba 출력
        jal   print_int

        la    $a0, msg_t_pba
        jal   print_string
        la    $t2, trace_pba        # pba 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &trace_pba[i]
        lw    $a0, 0($t2)           # pba 출력
        jal   print_int

        la    $a0, msg_t_data
        jal   print_string
        la    $t2, trace_data       # data 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &trace_data[i]
        lw    $a0, 0($t2)           # data 출력
        jal   print_int
        jal   print_newline

ptl_type_done:
ptl_next:                           # 다음 Trace로 이동
        addiu $t0, $t0, 1           # i++
        j     ptl_loop

ptl_empty:                          # Trace가 비어 있음
        la    $a0, msg_trace_none
        jal   print_string

ptl_done:                           # Trace 출력 끝
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

reset_trace_log:                    # Trace 개수만 0으로 초기화
        sw    $zero, trace_count
        jr    $ra                   # 호출한 곳으로 복귀

# Block erase GC

        .text

run_simple_gc:                      # erase blocks that have INVALID pages and no VALID pages
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)
        sw    $s0, 8($sp)           # total freed pages
        sw    $s1, 4($sp)           # erased block count
        sw    $s2, 0($sp)           # current block

        la    $a0, msg_gc_block_start
        jal   print_string

        li    $s0, 0                # total_freed = 0
        li    $s1, 0                # erased_blocks = 0
        li    $s2, 0                # block = 0

gc_block_loop:
        li    $t0, BLOCK_COUNT
        bge   $s2, $t0, gc_done

        li    $t1, BLOCK_SIZE
        mul   $t2, $s2, $t1         # start_pba = block * BLOCK_SIZE
        add   $t3, $t2, $t1         # end_pba = start_pba + BLOCK_SIZE
        move  $t4, $t2              # pba = start_pba
        li    $t5, 0                # has_valid = 0
        li    $t6, 0                # invalid_count = 0

gc_scan_loop:
        bge   $t4, $t3, gc_scan_done

        la    $t7, pba_state
        sll   $t8, $t4, 2
        add   $t7, $t7, $t8
        lw    $t9, 0($t7)

        li    $t0, VALID
        beq   $t9, $t0, gc_mark_valid

        li    $t0, INVALID
        bne   $t9, $t0, gc_scan_next
        addiu $t6, $t6, 1           # invalid_count++
        j     gc_scan_next

gc_mark_valid:
        li    $t5, 1                # has_valid = 1

gc_scan_next:
        addiu $t4, $t4, 1
        j     gc_scan_loop

gc_scan_done:
        bnez  $t5, gc_next_block    # keep blocks that contain valid data
        beqz  $t6, gc_next_block    # nothing to reclaim

        la    $a0, msg_gc_erase_block
        jal   print_string
        move  $a0, $s2
        jal   print_int
        la    $a0, msg_gc_block_free
        jal   print_string

        li    $t1, BLOCK_SIZE
        mul   $t2, $s2, $t1         # start_pba = block * BLOCK_SIZE
        add   $t3, $t2, $t1         # end_pba
        move  $t4, $t2

gc_erase_loop:
        bge   $t4, $t3, gc_erase_done

        sll   $t8, $t4, 2

        la    $t7, pba_state
        add   $t7, $t7, $t8
        sw    $zero, 0($t7)         # pba_state[pba] = FREE

        la    $t7, pba_data
        add   $t7, $t7, $t8
        sw    $zero, 0($t7)         # pba_data[pba] = 0

        addiu $t4, $t4, 1
        j     gc_erase_loop

gc_erase_done:
        add   $s0, $s0, $t6         # total_freed += invalid_count
        addiu $s1, $s1, 1           # erased_blocks++

        lw    $t0, free_page_count
        add   $t0, $t0, $t6
        sw    $t0, free_page_count

        lw    $t0, invalid_page_count
        sub   $t0, $t0, $t6
        sw    $t0, invalid_page_count

gc_next_block:
        addiu $s2, $s2, 1
        j     gc_block_loop

gc_done:
        lw    $t0, gc_count
        addiu $t0, $t0, 1
        sw    $t0, gc_count

        lw    $t0, erase_count
        add   $t0, $t0, $s1
        sw    $t0, erase_count

        la    $a0, msg_gc_freed
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        la    $a0, msg_gc_done
        jal   print_string

        move  $a0, $s0
        jal   log_gc_event

        lw    $ra, 12($sp)
        lw    $s0, 8($sp)
        lw    $s1, 4($sp)
        lw    $s2, 0($sp)
        addiu $sp, $sp, 16
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

submit_write_request:               # 입력받은 값으로 쓰기 함수 호출
        addiu $sp, $sp, -12
        sw    $ra, 8($sp)           # 복귀 주소
        sw    $s0, 4($sp)           # LBA
        sw    $s1, 0($sp)           # data

        la    $a0, msg_write_lba    # LBA 입력 안내
        jal   print_string
        jal   read_int
        move  $s0, $v0              # 입력된 LBA

        move  $a0, $s0              # 범위 검사할 LBA
        jal   check_lba_range
        beqz  $v0, swr_bad_lba      # 범위 밖이면 에러 출력

        la    $a0, msg_write_data   # data 입력 안내
        jal   print_string
        jal   read_int
        move  $s1, $v0              # 입력된 data

        move  $a0, $s0              # LBA
        move  $a1, $s1              # data
        jal   ftl_write_core
        j     swr_done

swr_bad_lba:                        # 잘못된 LBA 입력
        la    $a0, msg_lba_range
        jal   print_string

swr_done:                           # 입력 처리 끝
        lw    $ra, 8($sp)           # 복귀 주소 복구
        lw    $s0, 4($sp)           # LBA 복구
        lw    $s1, 0($sp)           # data 복구
        addiu $sp, $sp, 12
        jr    $ra                   # 호출한 곳으로 복귀

ftl_write_core:                     # LBA에 data를 쓰고 mapping 갱신
        addiu $sp, $sp, -20
        sw    $ra, 16($sp)          # 복귀 주소
        sw    $s0, 12($sp)          # lba
        sw    $s1,  8($sp)          # data
        sw    $s2,  4($sp)          # old_pba
        sw    $s3,  0($sp)          # new_pba

        move  $s0, $a0              # 현재 LBA
        move  $s1, $a1              # 현재 data

        la    $a0, msg_sel_lba      # 선택한 LBA 출력
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        move  $a0, $s0              # 기존 mapping 확인
        jal   get_lba_mapping
        move  $s2, $v0              # old_pba

        li    $t0, -1
        beq   $s2, $t0, fwc_no_old  # 처음 쓰는 LBA면 바로 새 PBA 찾기

        la    $a0, msg_old_pba      # 이전 PBA 출력
        jal   print_string
        move  $a0, $s2
        jal   print_int
        jal   print_newline

        la    $a0, msg_pba_inv_a    # INVALID 처리 안내
        jal   print_string
        move  $a0, $s2
        jal   print_int
        la    $a0, msg_pba_inv_b
        jal   print_string

        move  $a0, $s2
        li    $a1, 2
        jal   set_pba_state         # old_pba를 INVALID로 바꿈
        lw    $t0, invalid_page_count
        addiu $t0, $t0, 1           # INVALID page 수 증가
        sw    $t0, invalid_page_count

        j     fwc_find_free

fwc_no_old:                         # 처음 쓰는 LBA
        la    $a0, msg_no_old_map
        jal   print_string

fwc_find_free:                      # 새 PBA 찾기
        jal   find_free_pba
        move  $s3, $v0              # new_pba

        li    $t0, -1
        beq   $s3, $t0, fwc_no_free # 빈 PBA가 없으면 종료

        move  $a0, $s3
        li    $a1, 1
        jal   set_pba_state         # new_pba를 VALID로 설정

        move  $a0, $s3
        move  $a1, $s1
        jal   set_pba_data          # new_pba에 data 저장

        move  $a0, $s0
        move  $a1, $s3
        jal   set_lba_mapping       # LBA -> PBA mapping 갱신

        lw    $t0, total_write_count
        addiu $t0, $t0, 1           # WRITE 횟수 +1
        sw    $t0, total_write_count

        lw    $t0, free_page_count
        addiu $t0, $t0, -1          # FREE page 수 감소
        sw    $t0, free_page_count

        la    $a0, msg_new_pba      # 새 PBA 출력
        jal   print_string
        move  $a0, $s3
        jal   print_int
        jal   print_newline

        la    $a0, msg_lba_prefix   # LBA 출력
        jal   print_string
        move  $a0, $s0
        jal   print_int
        la    $a0, msg_arrow_pba    # PBA 출력
        jal   print_string
        move  $a0, $s3
        jal   print_int
        la    $a0, msg_data_eq      # data 출력
        jal   print_string
        move  $a0, $s1
        jal   print_int
        jal   print_newline

        move  $a0, $s0              # lba
        move  $a1, $s3              # pba
        move  $a2, $s1              # data
        jal   log_write_event

        la    $a0, msg_write_ok
        li    $a1, 1
        jal   run_state             # 상태 메시지와 시간 처리
        j     fwc_done

fwc_no_free:                        # 빈 PBA가 없는 경우
        li    $t0, -1
        beq   $s2, $t0, fwc_no_free_msg

        move  $a0, $s2
        li    $a1, 1
        jal   set_pba_state         # restore old_pba to VALID

        lw    $t0, invalid_page_count
        addiu $t0, $t0, -1
        sw    $t0, invalid_page_count

fwc_no_free_msg:
        la    $a0, msg_no_free
        jal   print_string

fwc_done:                           # 쓰기 처리 끝
        lw    $ra, 16($sp)          # 복귀 주소 복구
        lw    $s0, 12($sp)          # lba 복구
        lw    $s1,  8($sp)          # data 복구
        lw    $s2,  4($sp)          # old_pba 복구
        lw    $s3,  0($sp)          # new_pba 복구
        addiu $sp, $sp, 20
        jr    $ra                   # 호출한 곳으로 복귀


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

        la    $a0, msg_data_val     # data 출력
        jal   print_string
        move  $s0, $v0              # data를 잠깐 저장
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
        jal   run_simple_gc
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

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
