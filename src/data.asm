# 전역 상수, 배열, 문자열

        .eqv  LBA_COUNT,   4      # LBA는 0~3 사용
        .eqv  PBA_COUNT,   8      # PBA는 0~7 사용
        .eqv  BLOCK_COUNT, 2      # block은 2개
        .eqv  PBA_PER_BLK, 4      # block 하나에 PBA 4개
        .eqv  FREE,        0      # 비어 있는 page
        .eqv  VALID,       1      # 유효한 page
        .eqv  INVALID,     2      # 오래된 page

        .eqv  TRACE_MAX,   20     # Trace 최대 개수

        .eqv  TTYPE_WRITE, 1
        .eqv  TTYPE_READ,  2
        .eqv  TTYPE_GC,    3
        .eqv  TTYPE_RESET, 4

        .data

lba_map:            .word -1, -1, -1, -1
pba_state:          .word  0,  0,  0,  0,  0,  0,  0,  0
pba_data:           .word  0,  0,  0,  0,  0,  0,  0,  0
block_erase_count:  .word  0, 0

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

msg_menu: .asciiz "\n=== SSD FTL 시뮬레이터 ===\n 1. 쓰기 요청\n 2. 읽기 요청\n 3. 매핑 테이블 보기\n 4. 물리 페이지 보기\n 5. 블록 정보 보기\n 6. 통계 보기\n 7. Trace 로그 보기\n 8. 전체 상태 보기\n 9. 데모 실행\n10. SSD 초기화\n11. GC 실행\n 0. 종료\n선택: "
msg_invalid_opt:
msg_invalid_op: .asciiz "잘못된 메뉴입니다.\n"
msg_bye:        .asciiz "종료합니다.\n"

msg_newline:    .asciiz "\n"
msg_separator:  .asciiz "-----------------------------\n"
msg_lba_prefix: .asciiz "LBA "
msg_pba_prefix: .asciiz "PBA "
msg_arrow_pba:  .asciiz " -> PBA "
msg_data_eq:    .asciiz ", 데이터 = "
msg_sep_state:  .asciiz " | 상태: "
msg_sep_data:   .asciiz " | 데이터: "
msg_colon_sp:   .asciiz ": "
msg_ms:         .asciiz " ms\n"
msg_state_op:   .asciiz "[상태] "

msg_write_lba:  .asciiz "쓸 LBA (0-3): "
msg_write_data: .asciiz "데이터 입력: "
msg_read_lba:   .asciiz "읽을 LBA (0-3): "
msg_lba_range:  .asciiz "LBA 범위를 벗어났습니다.\n"

msg_sel_lba:    .asciiz "선택한 LBA: "
msg_no_old_map: .asciiz "이 LBA는 처음 씁니다.\n"
msg_old_pba:    .asciiz "이전 PBA: "
msg_pba_inv_a:  .asciiz "PBA "
msg_pba_inv_b:  .asciiz " -> INVALID\n"
msg_new_pba:    .asciiz "새 PBA 할당: "
msg_write_ok:   .asciiz "쓰기 완료.\n"
msg_no_free:    .asciiz "빈 page가 없습니다. 먼저 GC를 실행하세요.\n"

msg_read_lba_p: .asciiz "읽는 LBA: "
msg_mapped_pba: .asciiz "연결된 PBA: "
msg_data_val:   .asciiz "데이터: "
msg_no_data:    .asciiz "이 LBA에는 데이터가 없습니다.\n"

msg_map_hdr:    .asciiz "[매핑 테이블]\n"
msg_pba_hdr:    .asciiz "[물리 페이지 테이블]\n상태: 0=FREE, 1=VALID, 2=INVALID\n"
msg_blk_hdr:    .asciiz "[블록 정보]\n"
msg_blk_line:   .asciiz "블록 "
msg_blk_pba:    .asciiz " (PBA "
msg_blk_to:     .asciiz " ~ "
msg_blk_erase:  .asciiz ") | erase 횟수: "
msg_stats_hdr:  .asciiz "[통계]\n"
msg_full_hdr:   .asciiz "\n======= 전체 SSD 상태 =======\n"
msg_full_end:   .asciiz "================================\n"

msg_st_writes:  .asciiz "총 WRITE 수       : "
msg_st_reads:   .asciiz "총 READ 수        : "
msg_st_states:  .asciiz "상태 실행 수      : "
msg_st_time:    .asciiz "누적 시간(ms)     : "
msg_st_free:    .asciiz "FREE page 수      : "
msg_st_valid:   .asciiz "VALID page 수     : "
msg_st_inv:     .asciiz "INVALID page 수   : "
msg_st_gc:      .asciiz "GC 실행 수        : "

msg_ps_hdr:     .asciiz "[페이지 상태 요약]\n"
msg_ps_free:    .asciiz "  FREE    : "
msg_ps_valid:   .asciiz "  VALID   : "
msg_ps_invalid: .asciiz "  INVALID : "

msg_gc_start:   .asciiz "[GC] INVALID page 확인 중...\n"
msg_gc_freed:   .asciiz "[GC] 정리한 page 수: "
msg_gc_done:    .asciiz "[GC] 끝.\n"
msg_gc_pba_ok:  .asciiz "[GC] PBA "
msg_gc_freed1:  .asciiz " -> FREE (Block "
msg_gc_freed2:  .asciiz " erase++)\n"

msg_trace_hdr:  .asciiz "[Trace 로그]\n"
msg_trace_full: .asciiz "[Trace] 로그가 꽉 찼습니다.\n"
msg_trace_pipe: .asciiz " | "
msg_t_write:    .asciiz "WRITE"
msg_t_read:     .asciiz "READ "
msg_t_gc:       .asciiz "GC   "
msg_t_reset:    .asciiz "RESET"
msg_t_lba:      .asciiz " | LBA "
msg_t_pba:      .asciiz " | PBA "
msg_t_data:     .asciiz " | DATA "
msg_t_freed:    .asciiz " | 정리한 page: "
msg_trace_none: .asciiz "(기록된 이벤트 없음)\n"

msg_reset_start: .asciiz "[Reset] SSD 상태를 초기화합니다...\n"
msg_reset_done:  .asciiz "[Reset] 초기화가 끝났습니다.\n"

msg_demo_hdr:   .asciiz "\n--- 데모 시작 ---\n"
msg_demo_step:  .asciiz "[Demo] 단계 "
msg_demo_end:   .asciiz "--- 데모 끝 ---\n"
