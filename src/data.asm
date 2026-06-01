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

msg_ps_hdr:     .asciiz "[Page State Summary]\n"
msg_ps_free:    .asciiz "  FREE    : "
msg_ps_valid:   .asciiz "  VALID   : "
msg_ps_invalid: .asciiz "  INVALID : "

msg_gc_start:   .asciiz "[GC] Scanning INVALID pages...\n"
msg_gc_freed:   .asciiz "[GC] Freed page count: "
msg_gc_done:    .asciiz "[GC] Done\n"
msg_gc_pba_ok:  .asciiz "[GC] PBA "
msg_gc_to_free: .asciiz " -> FREE\n"

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
