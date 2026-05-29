# =============================================================================
# data.asm  --  전역 데이터, 상수, 배열, 메시지 문자열
#
# 이 프로젝트는 실제 SSD firmware나 FEMU를 구현하는 것이 아니라,
# FEMU/SSD FTL 구조에서 핵심이 되는 Host read/write 요청,
# LBA-PBA mapping, out-of-place update, page state transition,
# simplified GC, trace log를 MIPS 어셈블리어로 단순화해
# 시뮬레이션하는 학습용 프로그램이다.
# =============================================================================

# ---- 상수 정의 ----
# .eqv 는 MARS 전용 매크로로, 숫자 리터럴에 이름을 붙여준다.
# C의 #define 과 같은 역할이다.

        .eqv  LBA_COUNT,   4      # 논리 페이지 주소 범위: 0 ~ 3
        .eqv  PBA_COUNT,   8      # 물리 페이지 주소 범위: 0 ~ 7
        .eqv  BLOCK_COUNT, 2      # 블록 수: Block0(PBA 0~3), Block1(PBA 4~7)
        .eqv  PBA_PER_BLK, 4      # 블록당 페이지 수

        .eqv  FREE,        0      # 페이지 상태: 비어있음
        .eqv  VALID,       1      # 페이지 상태: 유효한 데이터 있음
        .eqv  INVALID,     2      # 페이지 상태: 덮어쓰여진 구 데이터 (GC 대상)

        .eqv  TRACE_MAX,   20     # trace log 최대 기록 개수

        # trace 이벤트 타입 코드
        .eqv  TTYPE_WRITE, 1
        .eqv  TTYPE_READ,  2
        .eqv  TTYPE_GC,    3
        .eqv  TTYPE_RESET, 4

        .data

# =============================================================================
# ---- 핵심 FTL 배열 ----
#
# C로 표현하면:
#   int lba_map[4]    = { -1, -1, -1, -1 };
#   int pba_state[8]  = {  0,  0,  0,  0,  0,  0,  0,  0 };
#   int pba_data[8]   = {  0,  0,  0,  0,  0,  0,  0,  0 };
#
# lba_map[lba] = pba  : 해당 LBA가 현재 어느 PBA에 저장되어 있는지
# pba_state[pba]      : 해당 물리 페이지의 상태 (FREE/VALID/INVALID)
# pba_data[pba]       : 해당 물리 페이지에 저장된 정수 데이터
# =============================================================================

lba_map:          .word  -1, -1, -1, -1
pba_state:        .word   0,  0,  0,  0,  0,  0,  0,  0
pba_data:         .word   0,  0,  0,  0,  0,  0,  0,  0

# =============================================================================
# ---- block model ----
#
# SSD는 실제로 block 단위로 erase가 이루어진다.
# Block 0: PBA 0 ~ 3, Block 1: PBA 4 ~ 7
# block_erase_count[b] : 해당 블록이 GC로 회수된 횟수
# =============================================================================

block_erase_count: .word  0, 0

# =============================================================================
# ---- trace log ----
#
# 이벤트 발생 순서대로 기록. 배열 4개를 같은 인덱스로 접근한다.
# trace_type[i]  : 이벤트 종류 (1=WRITE, 2=READ, 3=GC, 4=RESET)
# trace_lba[i]   : 관련 LBA (-1이면 해당 없음)
# trace_pba[i]   : 관련 PBA (-1이면 해당 없음)
# trace_data[i]  : 관련 데이터 값 (-1이면 해당 없음)
# =============================================================================

trace_type:  .word 0:20
trace_lba:   .word 0:20
trace_pba:   .word 0:20
trace_data:  .word 0:20
trace_count: .word 0

# =============================================================================
# ---- 통계 변수 ----
# =============================================================================

total_write_count:    .word 0
total_read_count:     .word 0
total_state_count:    .word 0
total_simulated_time: .word 0
free_page_count:      .word 8    # 초기에는 전부 FREE
invalid_page_count:   .word 0
gc_count:             .word 0

# =============================================================================
# ---- 출력 메시지 문자열 ----
# 역할별로 묶어서 관리한다.
# =============================================================================

# 메뉴
msg_menu:       .asciiz "\n=== Toy SSD FTL Simulator ===\n 1. Submit Write Command\n 2. Submit Read Command\n 3. Print Mapping Table\n 4. Print Physical Page Table\n 5. Print Block Table\n 6. Print Statistics\n 7. Print Trace Log\n 8. Print Full SSD Status\n 9. Run Demo Scenario\n10. Reset SSD\n11. Run Simple GC\n 0. Exit\nSelect: "
msg_invalid_op: .asciiz "Invalid option. Try again.\n"
msg_bye:        .asciiz "Goodbye.\n"

# 공통 조각
msg_newline:    .asciiz "\n"
msg_separator:  .asciiz "-----------------------------\n"
msg_lba_prefix: .asciiz "LBA "
msg_pba_prefix: .asciiz "PBA "
msg_arrow_pba:  .asciiz " -> PBA "
msg_data_eq:    .asciiz ", data = "
msg_sep_state:  .asciiz " | state: "
msg_sep_data:   .asciiz " | data: "
msg_colon_sp:   .asciiz ": "
msg_ms:         .asciiz " ms\n"
msg_state_op:   .asciiz "[State] "

# write/read 입력 프롬프트
msg_write_lba:  .asciiz "Write LBA (0-3): "
msg_write_data: .asciiz "Input data: "
msg_read_lba:   .asciiz "Read LBA (0-3): "
msg_lba_range:  .asciiz "LBA out of range.\n"

# write 진행 메시지
msg_sel_lba:    .asciiz "Selected LBA: "
msg_no_old_map: .asciiz "No old mapping. First write for this LBA.\n"
msg_old_pba:    .asciiz "Old PBA found: "
msg_pba_inv_a:  .asciiz "PBA "
msg_pba_inv_b:  .asciiz " -> INVALID\n"
msg_new_pba:    .asciiz "New PBA allocated: "
msg_write_ok:   .asciiz "Write complete.\n"
msg_no_free:    .asciiz "No free page. Please run GC first.\n"

# read 진행 메시지
msg_read_lba_p: .asciiz "Read LBA: "
msg_mapped_pba: .asciiz "Mapped PBA: "
msg_data_val:   .asciiz "Data: "
msg_no_data:    .asciiz "No data for this LBA.\n"

# 테이블 헤더
msg_map_hdr:    .asciiz "[Mapping Table]\n"
msg_pba_hdr:    .asciiz "[Physical Page Table]\nState: 0=FREE, 1=VALID, 2=INVALID\n"
msg_blk_hdr:    .asciiz "[Block Table]\n"
msg_blk_line:   .asciiz "Block "
msg_blk_pba:    .asciiz " (PBA "
msg_blk_to:     .asciiz " ~ "
msg_blk_erase:  .asciiz ") | erase count: "
msg_stats_hdr:  .asciiz "[Statistics]\n"
msg_full_hdr:   .asciiz "\n======= Full SSD Status =======\n"
msg_full_end:   .asciiz "================================\n"

# 통계 레이블
msg_st_writes:  .asciiz "Total writes        : "
msg_st_reads:   .asciiz "Total reads         : "
msg_st_states:  .asciiz "State ops           : "
msg_st_time:    .asciiz "Simulated time (ms) : "
msg_st_free:    .asciiz "Free pages          : "
msg_st_valid:   .asciiz "Valid pages         : "
msg_st_inv:     .asciiz "Invalid pages       : "
msg_st_gc:      .asciiz "GC runs             : "

# page state 요약
msg_ps_hdr:     .asciiz "[Page State Summary]\n"
msg_ps_free:    .asciiz "  FREE    : "
msg_ps_valid:   .asciiz "  VALID   : "
msg_ps_invalid: .asciiz "  INVALID : "

# GC 메시지
msg_gc_start:   .asciiz "[GC] Scanning INVALID pages...\n"
msg_gc_freed:   .asciiz "[GC] Freed pages: "
msg_gc_done:    .asciiz "[GC] Done.\n"
msg_gc_pba_ok:  .asciiz "[GC] PBA "
msg_gc_freed1:  .asciiz " -> FREE (Block "
msg_gc_freed2:  .asciiz " erase++)\n"

# trace 메시지
msg_trace_hdr:  .asciiz "[Trace Log]\n"
msg_trace_full: .asciiz "[Trace] Log is full. No more recording.\n"
msg_trace_pipe: .asciiz " | "
msg_t_write:    .asciiz "WRITE"
msg_t_read:     .asciiz "READ "
msg_t_gc:       .asciiz "GC   "
msg_t_reset:    .asciiz "RESET"
msg_t_lba:      .asciiz " | LBA "
msg_t_pba:      .asciiz " | PBA "
msg_t_data:     .asciiz " | DATA "
msg_t_freed:    .asciiz " | freed pages: "
msg_trace_none: .asciiz "(no events recorded)\n"

# reset 메시지
msg_reset_start: .asciiz "[Reset] Resetting all SSD state...\n"
msg_reset_done:  .asciiz "[Reset] Done. All pages are FREE.\n"

# demo 메시지
msg_demo_hdr:   .asciiz "\n--- Demo Scenario Start ---\n"
msg_demo_step:  .asciiz "[Demo] Step "
msg_demo_end:   .asciiz "--- Demo Scenario End ---\n"
