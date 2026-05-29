# =============================================================================
# final_combined.asm
# Standalone combined version of the Toy SSD FTL simulator.
# =============================================================================

        .eqv  LBA_COUNT,   4
        .eqv  PBA_COUNT,   8
        .eqv  BLOCK_COUNT, 2
        .eqv  PBA_PER_BLK, 4
        .eqv  FREE,        0
        .eqv  VALID,       1
        .eqv  INVALID,     2
        .eqv  TRACE_MAX,   20
        .eqv  TTYPE_WRITE, 1
        .eqv  TTYPE_READ,  2
        .eqv  TTYPE_GC,    3
        .eqv  TTYPE_RESET, 4

        .data

lba_map:            .word  -1, -1, -1, -1
pba_state:          .word   0,  0,  0,  0,  0,  0,  0,  0
pba_data:           .word   0,  0,  0,  0,  0,  0,  0,  0
block_erase_count:  .word   0, 0

trace_type:         .word 0:20
trace_lba:          .word 0:20
trace_pba:          .word 0:20
trace_data:         .word 0:20
trace_count:        .word 0

total_write_count:    .word 0
total_read_count:     .word 0
total_state_count:    .word 0
total_simulated_time: .word 0
free_page_count:      .word 8
invalid_page_count:   .word 0
gc_count:             .word 0

msg_menu:         .asciiz "\n=== Toy SSD FTL Simulator ===\n 1. Submit Write Command\n 2. Submit Read Command\n 3. Print Mapping Table\n 4. Print Physical Page Table\n 5. Print Block Table\n 6. Print Statistics\n 7. Print Trace Log\n 8. Print Full SSD Status\n 9. Run Demo Scenario\n10. Reset SSD\n11. Run Simple GC\n 0. Exit\nSelect: "
msg_invalid_opt:
msg_invalid_op:   .asciiz "Invalid option. Try again.\n"
msg_bye:          .asciiz "Goodbye.\n"

msg_newline:      .asciiz "\n"
msg_separator:    .asciiz "-----------------------------\n"
msg_lba_prefix:   .asciiz "LBA "
msg_pba_prefix:   .asciiz "PBA "
msg_arrow_pba:    .asciiz " -> PBA "
msg_data_eq:      .asciiz ", data = "
msg_sep_state:    .asciiz " | state: "
msg_sep_data:     .asciiz " | data: "
msg_colon_sp:     .asciiz ": "
msg_ms:           .asciiz " ms\n"
msg_state_op:     .asciiz "[State] "

msg_write_lba:    .asciiz "Write LBA (0-3): "
msg_write_data:   .asciiz "Input data: "
msg_read_lba:     .asciiz "Read LBA (0-3): "
msg_lba_range:    .asciiz "LBA out of range.\n"

msg_sel_lba:      .asciiz "Selected LBA: "
msg_no_old_map:   .asciiz "No old mapping. First write for this LBA.\n"
msg_old_pba:      .asciiz "Old PBA found: "
msg_pba_inv_a:    .asciiz "PBA "
msg_pba_inv_b:    .asciiz " -> INVALID\n"
msg_new_pba:      .asciiz "New PBA allocated: "
msg_write_ok:     .asciiz "Write complete.\n"
msg_no_free:      .asciiz "No free page. Please run GC first.\n"

msg_read_lba_p:   .asciiz "Read LBA: "
msg_mapped_pba:   .asciiz "Mapped PBA: "
msg_data_val:     .asciiz "Data: "
msg_no_data:      .asciiz "No data for this LBA.\n"

msg_map_hdr:      .asciiz "[Mapping Table]\n"
msg_pba_hdr:      .asciiz "[Physical Page Table]\nState: 0=FREE, 1=VALID, 2=INVALID\n"
msg_blk_hdr:      .asciiz "[Block Table]\n"
msg_blk_line:     .asciiz "Block "
msg_blk_pba:      .asciiz " (PBA "
msg_blk_to:       .asciiz " ~ "
msg_blk_erase:    .asciiz ") | erase count: "
msg_stats_hdr:    .asciiz "[Statistics]\n"
msg_full_hdr:     .asciiz "\n======= Full SSD Status =======\n"
msg_full_end:     .asciiz "================================\n"

msg_st_writes:    .asciiz "Total writes        : "
msg_st_reads:     .asciiz "Total reads         : "
msg_st_states:    .asciiz "State ops           : "
msg_st_time:      .asciiz "Simulated time (ms) : "
msg_st_free:      .asciiz "Free pages          : "
msg_st_valid:     .asciiz "Valid pages         : "
msg_st_inv:       .asciiz "Invalid pages       : "
msg_st_gc:        .asciiz "GC runs             : "

msg_ps_hdr:       .asciiz "[Page State Summary]\n"
msg_ps_free:      .asciiz "  FREE    : "
msg_ps_valid:     .asciiz "  VALID   : "
msg_ps_invalid:   .asciiz "  INVALID : "

msg_gc_start:     .asciiz "[GC] Scanning INVALID pages...\n"
msg_gc_freed:     .asciiz "[GC] Freed pages: "
msg_gc_done:      .asciiz "[GC] Done.\n"
msg_gc_pba_ok:    .asciiz "[GC] PBA "
msg_gc_freed1:    .asciiz " -> FREE (Block "
msg_gc_freed2:    .asciiz " erase++)\n"

msg_trace_hdr:    .asciiz "[Trace Log]\n"
msg_trace_full:   .asciiz "[Trace] Log is full. No more recording.\n"
msg_trace_pipe:   .asciiz " | "
msg_t_write:      .asciiz "WRITE"
msg_t_read:       .asciiz "READ "
msg_t_gc:         .asciiz "GC   "
msg_t_reset:      .asciiz "RESET"
msg_t_lba:        .asciiz " | LBA "
msg_t_pba:        .asciiz " | PBA "
msg_t_data:       .asciiz " | DATA "
msg_t_freed:      .asciiz " | freed pages: "
msg_trace_none:   .asciiz "(no events recorded)\n"

msg_reset_start:  .asciiz "[Reset] Resetting all SSD state...\n"
msg_reset_done:   .asciiz "[Reset] Done. All pages are FREE.\n"

msg_demo_hdr:     .asciiz "\n--- Demo Scenario Start ---\n"
msg_demo_step:    .asciiz "[Demo] Step "
msg_demo_end:     .asciiz "--- Demo Scenario End ---\n"
msg_demo_s1:      .asciiz ": Write LBA 2, data 100\n"
msg_demo_s2:      .asciiz ": Write LBA 1, data 50\n"
msg_demo_s3:      .asciiz ": Read LBA 2\n"
msg_demo_s4:      .asciiz ": Overwrite LBA 2, data 200\n"
msg_demo_s5:      .asciiz ": Read LBA 2 (expect 200)\n"
msg_demo_s6:      .asciiz ": Print Mapping Table\n"
msg_demo_s7:      .asciiz ": Print Physical Page Table\n"
msg_demo_s8:      .asciiz ": Run Simple GC\n"
msg_demo_s9:      .asciiz ": Print Physical Page Table (after GC)\n"
msg_demo_s10:     .asciiz ": Print Trace Log\n"

        .text
        .globl main

main:
        j     menu_loop
        nop

print_string:
        li    $v0, 4
        syscall
        jr    $ra

print_int:
        li    $v0, 1
        syscall
        jr    $ra

print_newline:
        la    $a0, msg_newline
        li    $v0, 4
        syscall
        jr    $ra

print_separator:
        la    $a0, msg_separator
        li    $v0, 4
        syscall
        jr    $ra

read_int:
        li    $v0, 5
        syscall
        jr    $ra

run_state:
        addiu $sp, $sp, -12
        sw    $ra, 8($sp)
        sw    $a0, 4($sp)
        sw    $a1, 0($sp)

        la    $a0, msg_state_op
        li    $v0, 4
        syscall

        lw    $a0, 4($sp)
        li    $v0, 4
        syscall

        lw    $a0, 0($sp)
        li    $v0, 1
        syscall

        la    $a0, msg_ms
        li    $v0, 4
        syscall

        lw    $t0, total_state_count
        addiu $t0, $t0, 1
        sw    $t0, total_state_count

        lw    $t0, total_simulated_time
        lw    $t1, 0($sp)
        add   $t0, $t0, $t1
        sw    $t0, total_simulated_time

        lw    $a0, 0($sp)
        li    $v0, 32
        syscall

        lw    $ra, 8($sp)
        addiu $sp, $sp, 12
        jr    $ra

log_write_event:
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)
        sw    $a0,  8($sp)
        sw    $a1,  4($sp)
        sw    $a2,  0($sp)

        jal   trace_check_full
        bnez  $v0, lwe_done

        lw    $t0, trace_count

        sll   $t1, $t0, 2
        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, 1
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

log_read_event:
        addiu $sp, $sp, -16
        sw    $ra, 12($sp)
        sw    $a0,  8($sp)
        sw    $a1,  4($sp)
        sw    $a2,  0($sp)

        jal   trace_check_full
        bnez  $v0, lre_done

        lw    $t0, trace_count
        sll   $t1, $t0, 2

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, 2
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

log_gc_event:
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)
        sw    $a0, 0($sp)

        jal   trace_check_full
        bnez  $v0, lge_done

        lw    $t0, trace_count
        sll   $t1, $t0, 2

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, 3
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

log_reset_event:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        jal   trace_check_full
        bnez  $v0, lrese_done

        lw    $t0, trace_count
        sll   $t1, $t0, 2

        la    $t2, trace_type
        add   $t2, $t2, $t1
        li    $t3, 4
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

trace_check_full:
        lw    $t0, trace_count
        li    $t1, 20
        li    $v0, 0
        blt   $t0, $t1, tcf_ok
        li    $v0, 1
tcf_ok:
        jr    $ra

print_trace_log:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_trace_hdr
        jal   print_string

        lw    $t0, trace_count
        beqz  $t0, ptl_empty

        li    $t0, 0

ptl_loop:
        lw    $t1, trace_count
        bge   $t0, $t1, ptl_done

        move  $a0, $t0
        jal   print_int
        la    $a0, msg_trace_pipe
        jal   print_string

        la    $t2, trace_type
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $t4, 0($t2)

        li    $t5, 1
        beq   $t4, $t5, ptl_write
        li    $t5, 2
        beq   $t4, $t5, ptl_read
        li    $t5, 3
        beq   $t4, $t5, ptl_gc
        li    $t5, 4
        beq   $t4, $t5, ptl_reset
        j     ptl_type_done

ptl_write:
        la    $a0, msg_t_write
        jal   print_string
        j     ptl_print_lba

ptl_read:
        la    $a0, msg_t_read
        jal   print_string
        j     ptl_print_lba

ptl_gc:
        la    $a0, msg_t_gc
        jal   print_string

        la    $t2, trace_data
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)

        move  $a2, $a0
        la    $a0, msg_t_freed
        jal   print_string
        move  $a0, $a2
        jal   print_int
        jal   print_newline
        j     ptl_next

ptl_reset:
        la    $a0, msg_t_reset
        jal   print_string
        jal   print_newline
        j     ptl_next

ptl_print_lba:
        la    $a0, msg_t_lba
        jal   print_string
        la    $t2, trace_lba
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)
        jal   print_int

        la    $a0, msg_t_pba
        jal   print_string
        la    $t2, trace_pba
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)
        jal   print_int

        la    $a0, msg_t_data
        jal   print_string
        la    $t2, trace_data
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)
        jal   print_int
        jal   print_newline

ptl_type_done:
ptl_next:
        addiu $t0, $t0, 1
        j     ptl_loop

ptl_empty:
        la    $a0, msg_trace_none
        jal   print_string

ptl_done:
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

reset_trace_log:
        sw    $zero, trace_count
        jr    $ra

check_lba_range:
        li    $v0, 0
        bltz  $a0, clr_fail
        li    $t0, 4
        bge   $a0, $t0, clr_fail
        li    $v0, 1
clr_fail:
        jr    $ra

get_lba_mapping:
        sll   $t0, $a0, 2
        la    $t1, lba_map
        add   $t1, $t1, $t0
        lw    $v0, 0($t1)
        jr    $ra

set_lba_mapping:
        sll   $t0, $a0, 2
        la    $t1, lba_map
        add   $t1, $t1, $t0
        sw    $a1, 0($t1)
        jr    $ra

reset_mapping_table:
        li    $t0, 0
        li    $t1, 4
        la    $t2, lba_map

rmt_loop:
        bge   $t0, $t1, rmt_done
        sll   $t3, $t0, 2
        add   $t4, $t2, $t3
        li    $t5, -1
        sw    $t5, 0($t4)
        addiu $t0, $t0, 1
        j     rmt_loop

rmt_done:
        jr    $ra

print_mapping_table:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_map_hdr
        jal   print_string

        li    $t0, 0
        li    $t1, 4
        la    $t2, lba_map

pmt_loop:
        bge   $t0, $t1, pmt_done

        la    $a0, msg_lba_prefix
        jal   print_string
        move  $a0, $t0
        jal   print_int
        la    $a0, msg_arrow_pba
        jal   print_string

        sll   $t3, $t0, 2
        add   $t4, $t2, $t3
        lw    $a0, 0($t4)
        jal   print_int
        jal   print_newline

        li    $t1, 4
        la    $t2, lba_map
        addiu $t0, $t0, 1
        j     pmt_loop

pmt_done:
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

get_pba_state:
        sll   $t0, $a0, 2
        la    $t1, pba_state
        add   $t1, $t1, $t0
        lw    $v0, 0($t1)
        jr    $ra

set_pba_state:
        sll   $t0, $a0, 2
        la    $t1, pba_state
        add   $t1, $t1, $t0
        sw    $a1, 0($t1)
        jr    $ra

get_pba_data:
        sll   $t0, $a0, 2
        la    $t1, pba_data
        add   $t1, $t1, $t0
        lw    $v0, 0($t1)
        jr    $ra

set_pba_data:
        sll   $t0, $a0, 2
        la    $t1, pba_data
        add   $t1, $t1, $t0
        sw    $a1, 0($t1)
        jr    $ra

find_free_pba:
        li    $t0, 0
        li    $t1, 8
        la    $t2, pba_state

ffp_loop:
        bge   $t0, $t1, ffp_none

        sll   $t3, $t0, 2
        add   $t4, $t2, $t3
        lw    $t5, 0($t4)

        beqz  $t5, ffp_found

        addiu $t0, $t0, 1
        j     ffp_loop

ffp_found:
        move  $v0, $t0
        jr    $ra

ffp_none:
        li    $v0, -1
        jr    $ra

reset_nand_table:
        li    $t0, 0
        li    $t1, 8
        la    $t2, pba_state
        la    $t3, pba_data

rnt_loop:
        bge   $t0, $t1, rnt_done

        sll   $t4, $t0, 2
        add   $t5, $t2, $t4
        sw    $zero, 0($t5)

        add   $t5, $t3, $t4
        sw    $zero, 0($t5)

        addiu $t0, $t0, 1
        j     rnt_loop

rnt_done:
        jr    $ra

print_physical_page_table:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_pba_hdr
        jal   print_string

        li    $t0, 0

pppt_loop:
        li    $t1, 8
        bge   $t0, $t1, pppt_done

        la    $a0, msg_pba_prefix
        jal   print_string
        move  $a0, $t0
        jal   print_int

        la    $a0, msg_sep_state
        jal   print_string

        la    $t2, pba_state
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)
        jal   print_int

        la    $a0, msg_sep_data
        jal   print_string

        la    $t2, pba_data
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)
        jal   print_int
        jal   print_newline

        addiu $t0, $t0, 1
        j     pppt_loop

pppt_done:
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

get_block_id_by_pba:
        srl   $v0, $a0, 2
        jr    $ra

increase_block_erase_count:
        sll   $t0, $a0, 2
        la    $t1, block_erase_count
        add   $t1, $t1, $t0
        lw    $t2, 0($t1)
        addiu $t2, $t2, 1
        sw    $t2, 0($t1)
        jr    $ra

print_block_table:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_blk_hdr
        jal   print_string

        li    $t0, 0
        li    $t1, 2

pbt_loop:
        bge   $t0, $t1, pbt_done

        la    $a0, msg_blk_line
        jal   print_string
        move  $a0, $t0
        jal   print_int

        la    $a0, msg_blk_pba
        jal   print_string

        sll   $t2, $t0, 2
        move  $a0, $t2
        jal   print_int

        la    $a0, msg_blk_to
        jal   print_string

        addiu $t2, $t2, 3
        move  $a0, $t2
        jal   print_int

        la    $a0, msg_blk_erase
        jal   print_string

        la    $t3, block_erase_count
        sll   $t4, $t0, 2
        add   $t3, $t3, $t4
        lw    $a0, 0($t3)
        jal   print_int
        jal   print_newline

        addiu $t0, $t0, 1
        j     pbt_loop

pbt_done:
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

reset_block_table:
        la    $t0, block_erase_count
        sw    $zero, 0($t0)
        sw    $zero, 4($t0)
        jr    $ra

submit_write_request:
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

swr_bad_lba:
        la    $a0, msg_lba_range
        jal   print_string

swr_done:
        lw    $ra, 8($sp)
        lw    $s0, 4($sp)
        lw    $s1, 0($sp)
        addiu $sp, $sp, 12
        jr    $ra

ftl_write_core:
        addiu $sp, $sp, -20
        sw    $ra, 16($sp)
        sw    $s0, 12($sp)
        sw    $s1,  8($sp)
        sw    $s2,  4($sp)
        sw    $s3,  0($sp)

        move  $s0, $a0
        move  $s1, $a1

        la    $a0, msg_sel_lba
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        move  $a0, $s0
        jal   get_lba_mapping
        move  $s2, $v0

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

        move  $a0, $s2
        li    $a1, 2
        jal   set_pba_state

        lw    $t0, free_page_count
        addiu $t0, $t0, -1
        sw    $t0, free_page_count

        lw    $t0, invalid_page_count
        addiu $t0, $t0, 1
        sw    $t0, invalid_page_count

        j     fwc_find_free

fwc_no_old:
        la    $a0, msg_no_old_map
        jal   print_string

fwc_find_free:
        jal   find_free_pba
        move  $s3, $v0

        li    $t0, -1
        beq   $s3, $t0, fwc_no_free

        move  $a0, $s3
        li    $a1, 1
        jal   set_pba_state

        move  $a0, $s3
        move  $a1, $s1
        jal   set_pba_data

        move  $a0, $s0
        move  $a1, $s3
        jal   set_lba_mapping

        lw    $t0, total_write_count
        addiu $t0, $t0, 1
        sw    $t0, total_write_count

        lw    $t0, free_page_count
        addiu $t0, $t0, -1
        sw    $t0, free_page_count

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

fwc_no_free:
        la    $a0, msg_no_free
        jal   print_string

fwc_done:
        lw    $ra, 16($sp)
        lw    $s0, 12($sp)
        lw    $s1,  8($sp)
        lw    $s2,  4($sp)
        lw    $s3,  0($sp)
        addiu $sp, $sp, 20
        jr    $ra

submit_read_request:
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)
        sw    $s0, 0($sp)

        la    $a0, msg_read_lba
        jal   print_string
        jal   read_int
        move  $s0, $v0

        move  $a0, $s0
        jal   check_lba_range
        beqz  $v0, srr_bad

        move  $a0, $s0
        jal   ftl_read_core
        j     srr_done

srr_bad:
        la    $a0, msg_lba_range
        jal   print_string

srr_done:
        lw    $ra, 4($sp)
        lw    $s0, 0($sp)
        addiu $sp, $sp, 8
        jr    $ra

ftl_read_core:
        addiu $sp, $sp, -12
        sw    $ra,  8($sp)
        sw    $s0,  4($sp)
        sw    $s1,  0($sp)

        move  $s0, $a0

        la    $a0, msg_read_lba_p
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        move  $a0, $s0
        jal   get_lba_mapping
        move  $s1, $v0

        li    $t0, -1
        beq   $s1, $t0, frc_no_data

        la    $a0, msg_mapped_pba
        jal   print_string
        move  $a0, $s1
        jal   print_int
        jal   print_newline

        move  $a0, $s1
        jal   get_pba_data

        la    $a0, msg_data_val
        jal   print_string
        move  $s0, $v0
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        lw    $t0, total_read_count
        addiu $t0, $t0, 1
        sw    $t0, total_read_count

        lw    $t1, 4($sp)
        move  $a0, $t1
        move  $a1, $s1
        move  $a2, $s0
        jal   log_read_event

        j     frc_done

frc_no_data:
        la    $a0, msg_no_data
        jal   print_string

frc_done:
        lw    $ra,  8($sp)
        lw    $s0,  4($sp)
        lw    $s1,  0($sp)
        addiu $sp, $sp, 12
        jr    $ra

run_simple_gc:
        addiu $sp, $sp, -8
        sw    $ra, 4($sp)
        sw    $s0, 0($sp)

        la    $a0, msg_gc_start
        jal   print_string

        li    $s0, 0
        li    $t0, 0

gc_loop:
        li    $t1, 8
        bge   $t0, $t1, gc_done

        la    $t2, pba_state
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $t4, 0($t2)

        li    $t5, 2
        bne   $t4, $t5, gc_next

        sw    $zero, 0($t2)

        la    $a0, msg_gc_pba_ok
        jal   print_string
        move  $a0, $t0
        jal   print_int
        la    $a0, msg_gc_freed1
        jal   print_string

        move  $a0, $t0
        jal   get_block_id_by_pba
        move  $t6, $v0

        move  $a0, $t6
        jal   print_int
        la    $a0, msg_gc_freed2
        jal   print_string

        move  $a0, $t6
        jal   increase_block_erase_count

        addiu $s0, $s0, 1

gc_next:
        addiu $t0, $t0, 1
        j     gc_loop

gc_done:
        lw    $t0, free_page_count
        add   $t0, $t0, $s0
        sw    $t0, free_page_count

        lw    $t0, invalid_page_count
        sub   $t0, $t0, $s0
        sw    $t0, invalid_page_count

        lw    $t0, gc_count
        addiu $t0, $t0, 1
        sw    $t0, gc_count

        la    $a0, msg_gc_freed
        jal   print_string
        move  $a0, $s0
        jal   print_int
        jal   print_newline

        la    $a0, msg_gc_done
        jal   print_string

        move  $a0, $s0
        jal   log_gc_event

        lw    $ra, 4($sp)
        lw    $s0, 0($sp)
        addiu $sp, $sp, 8
        jr    $ra

count_valid_pages:
        li    $t0, 0
        li    $t1, 8
        la    $t2, pba_state
        li    $v0, 0

cvp_loop:
        bge   $t0, $t1, cvp_done

        sll   $t3, $t0, 2
        add   $t4, $t2, $t3
        lw    $t5, 0($t4)

        li    $t6, 1
        bne   $t5, $t6, cvp_next
        addiu $v0, $v0, 1

cvp_next:
        addiu $t0, $t0, 1
        j     cvp_loop

cvp_done:
        jr    $ra

print_page_state_summary:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_ps_hdr
        jal   print_string

        la    $a0, msg_ps_free
        jal   print_string
        lw    $a0, free_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_ps_valid
        jal   print_string
        jal   count_valid_pages
        move  $a0, $v0
        jal   print_int
        jal   print_newline

        la    $a0, msg_ps_invalid
        jal   print_string
        lw    $a0, invalid_page_count
        jal   print_int
        jal   print_newline

        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

print_statistics:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_stats_hdr
        jal   print_string

        la    $a0, msg_st_writes
        jal   print_string
        lw    $a0, total_write_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_reads
        jal   print_string
        lw    $a0, total_read_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_states
        jal   print_string
        lw    $a0, total_state_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_time
        jal   print_string
        lw    $a0, total_simulated_time
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_free
        jal   print_string
        lw    $a0, free_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_valid
        jal   print_string
        jal   count_valid_pages
        move  $a0, $v0
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_inv
        jal   print_string
        lw    $a0, invalid_page_count
        jal   print_int
        jal   print_newline

        la    $a0, msg_st_gc
        jal   print_string
        lw    $a0, gc_count
        jal   print_int
        jal   print_newline

        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

print_full_status:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_full_hdr
        jal   print_string

        jal   print_statistics
        jal   print_separator

        jal   print_page_state_summary
        jal   print_separator

        jal   print_mapping_table
        jal   print_separator

        jal   print_physical_page_table
        jal   print_separator

        jal   print_block_table
        jal   print_separator

        jal   print_trace_log

        la    $a0, msg_full_end
        jal   print_string

        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

reset_ssd:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_reset_start
        jal   print_string

        jal   reset_nand_table
        jal   reset_mapping_table
        jal   reset_block_table
        jal   reset_statistics
        jal   reset_trace_log
        jal   log_reset_event

        la    $a0, msg_reset_done
        jal   print_string

        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

reset_statistics:
        sw    $zero, total_write_count
        sw    $zero, total_read_count
        sw    $zero, total_state_count
        sw    $zero, total_simulated_time
        sw    $zero, invalid_page_count
        sw    $zero, gc_count

        li    $t0, 8
        sw    $t0, free_page_count

        jr    $ra

run_demo_scenario:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_demo_hdr
        jal   print_string

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 1
        jal   print_int
        la    $a0, msg_demo_s1
        jal   print_string
        li    $a0, 2
        li    $a1, 100
        jal   ftl_write_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 2
        jal   print_int
        la    $a0, msg_demo_s2
        jal   print_string
        li    $a0, 1
        li    $a1, 50
        jal   ftl_write_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 3
        jal   print_int
        la    $a0, msg_demo_s3
        jal   print_string
        li    $a0, 2
        jal   ftl_read_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 4
        jal   print_int
        la    $a0, msg_demo_s4
        jal   print_string
        li    $a0, 2
        li    $a1, 200
        jal   ftl_write_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 5
        jal   print_int
        la    $a0, msg_demo_s5
        jal   print_string
        li    $a0, 2
        jal   ftl_read_core
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 6
        jal   print_int
        la    $a0, msg_demo_s6
        jal   print_string
        jal   print_mapping_table
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 7
        jal   print_int
        la    $a0, msg_demo_s7
        jal   print_string
        jal   print_physical_page_table
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 8
        jal   print_int
        la    $a0, msg_demo_s8
        jal   print_string
        jal   run_simple_gc
        jal   print_separator

        la    $a0, msg_demo_step
        jal   print_string
        li    $a0, 9
        jal   print_int
        la    $a0, msg_demo_s9
        jal   print_string
        jal   print_physical_page_table
        jal   print_separator

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

cmd_write:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   submit_write_request
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

cmd_read:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   submit_read_request
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

cmd_print_mapping:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   print_mapping_table
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

cmd_print_physical:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   print_physical_page_table
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

cmd_print_block:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   print_block_table
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

cmd_print_stats:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   print_statistics
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

cmd_print_trace:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   print_trace_log
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

cmd_full_status:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   print_full_status
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

cmd_demo:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   run_demo_scenario
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

cmd_reset:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   reset_ssd
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

cmd_gc:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)
        jal   run_simple_gc
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra

menu_loop:
        la    $a0, msg_menu
        jal   print_string
        jal   read_int
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
