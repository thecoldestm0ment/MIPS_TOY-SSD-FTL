#define _POSIX_C_SOURCE 199309L

/*
 * final_combined.c
 * C version of final_combined.asm
 *
 * Goal of this translation:
 * - Keep the original assembly program's structure, labels, global state,
 *   menu flow, printed messages, and FTL behavior as intact as possible.
 * - Function names are intentionally close to the original ASM labels.
 * - Some logically odd behaviors are preserved because they exist in the ASM
 *   flow, for example decreasing free_page_count when an old PBA is invalidated.
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#if defined(_WIN32)
#include <windows.h>
#endif

/* =============================================================================
 * Constants translated from .eqv
 * ============================================================================= */

#define LBA_COUNT   4
#define PBA_COUNT   8
#define BLOCK_COUNT 2
#define PBA_PER_BLK 4

#define FREE        0
#define VALID       1
#define INVALID     2

#define TRACE_MAX   20
#define TTYPE_WRITE 1
#define TTYPE_READ  2
#define TTYPE_GC    3
#define TTYPE_RESET 4

/* =============================================================================
 * Global data translated from .data
 * ============================================================================= */

static int lba_map[LBA_COUNT] = { -1, -1, -1, -1 };
static int pba_state[PBA_COUNT] = { 0, 0, 0, 0, 0, 0, 0, 0 };
static int pba_data[PBA_COUNT] = { 0, 0, 0, 0, 0, 0, 0, 0 };
static int block_erase_count[BLOCK_COUNT] = { 0, 0 };

static int trace_type[TRACE_MAX] = { 0 };
static int trace_lba[TRACE_MAX] = { 0 };
static int trace_pba[TRACE_MAX] = { 0 };
static int trace_data[TRACE_MAX] = { 0 };
static int trace_count = 0;

static int total_write_count = 0;
static int total_read_count = 0;
static int total_state_count = 0;
static int total_simulated_time = 0;
static int free_page_count = PBA_COUNT;
static int invalid_page_count = 0;
static int gc_count = 0;

/* =============================================================================
 * Messages translated from .asciiz
 * ============================================================================= */

static const char msg_menu[] =
    "\n=== Toy SSD FTL Simulator ===\n"
    " 1. Submit Write Command\n"
    " 2. Submit Read Command\n"
    " 3. Print Mapping Table\n"
    " 4. Print Physical Page Table\n"
    " 5. Print Block Table\n"
    " 6. Print Statistics\n"
    " 7. Print Trace Log\n"
    " 8. Print Full SSD Status\n"
    " 9. Run Demo Scenario\n"
    "10. Reset SSD\n"
    "11. Run Simple GC\n"
    " 0. Exit\n"
    "Select: ";

static const char msg_invalid_opt[] = "Invalid option. Try again.\n";
#define msg_invalid_op msg_invalid_opt

static const char msg_bye[] = "Goodbye.\n";

static const char msg_newline[] = "\n";
static const char msg_separator[] = "-----------------------------\n";
static const char msg_lba_prefix[] = "LBA ";
static const char msg_pba_prefix[] = "PBA ";
static const char msg_arrow_pba[] = " -> PBA ";
static const char msg_data_eq[] = ", data = ";
static const char msg_sep_state[] = " | state: ";
static const char msg_sep_data[] = " | data: ";
static const char msg_colon_sp[] = ": ";
static const char msg_ms[] = " ms\n";
static const char msg_state_op[] = "[State] ";

static const char msg_write_lba[] = "Write LBA (0-3): ";
static const char msg_write_data[] = "Input data: ";
static const char msg_read_lba[] = "Read LBA (0-3): ";
static const char msg_lba_range[] = "LBA out of range.\n";

static const char msg_sel_lba[] = "Selected LBA: ";
static const char msg_no_old_map[] = "No old mapping. First write for this LBA.\n";
static const char msg_old_pba[] = "Old PBA found: ";
static const char msg_pba_inv_a[] = "PBA ";
static const char msg_pba_inv_b[] = " -> INVALID\n";
static const char msg_new_pba[] = "New PBA allocated: ";
static const char msg_write_ok[] = "Write complete.\n";
static const char msg_no_free[] = "No free page. Please run GC first.\n";

static const char msg_read_lba_p[] = "Read LBA: ";
static const char msg_mapped_pba[] = "Mapped PBA: ";
static const char msg_data_val[] = "Data: ";
static const char msg_no_data[] = "No data for this LBA.\n";

static const char msg_map_hdr[] = "[Mapping Table]\n";
static const char msg_pba_hdr[] = "[Physical Page Table]\nState: 0=FREE, 1=VALID, 2=INVALID\n";
static const char msg_blk_hdr[] = "[Block Table]\n";
static const char msg_blk_line[] = "Block ";
static const char msg_blk_pba[] = " (PBA ";
static const char msg_blk_to[] = " ~ ";
static const char msg_blk_erase[] = ") | erase count: ";
static const char msg_stats_hdr[] = "[Statistics]\n";
static const char msg_full_hdr[] = "\n======= Full SSD Status =======\n";
static const char msg_full_end[] = "================================\n";

static const char msg_st_writes[] = "Total writes        : ";
static const char msg_st_reads[] = "Total reads         : ";
static const char msg_st_states[] = "State ops           : ";
static const char msg_st_time[] = "Simulated time (ms) : ";
static const char msg_st_free[] = "Free pages          : ";
static const char msg_st_valid[] = "Valid pages         : ";
static const char msg_st_inv[] = "Invalid pages       : ";
static const char msg_st_gc[] = "GC runs             : ";

static const char msg_ps_hdr[] = "[Page State Summary]\n";
static const char msg_ps_free[] = "  FREE    : ";
static const char msg_ps_valid[] = "  VALID   : ";
static const char msg_ps_invalid[] = "  INVALID : ";

static const char msg_gc_start[] = "[GC] Scanning INVALID pages...\n";
static const char msg_gc_freed[] = "[GC] Freed pages: ";
static const char msg_gc_done[] = "[GC] Done.\n";
static const char msg_gc_pba_ok[] = "[GC] PBA ";
static const char msg_gc_freed1[] = " -> FREE (Block ";
static const char msg_gc_freed2[] = " erase++)\n";

static const char msg_trace_hdr[] = "[Trace Log]\n";
static const char msg_trace_full[] = "[Trace] Log is full. No more recording.\n";
static const char msg_trace_pipe[] = " | ";
static const char msg_t_write[] = "WRITE";
static const char msg_t_read[] = "READ ";
static const char msg_t_gc[] = "GC   ";
static const char msg_t_reset[] = "RESET";
static const char msg_t_lba[] = " | LBA ";
static const char msg_t_pba[] = " | PBA ";
static const char msg_t_data[] = " | DATA ";
static const char msg_t_freed[] = " | freed pages: ";
static const char msg_trace_none[] = "(no events recorded)\n";

static const char msg_reset_start[] = "[Reset] Resetting all SSD state...\n";
static const char msg_reset_done[] = "[Reset] Done. All pages are FREE.\n";

static const char msg_demo_hdr[] = "\n--- Demo Scenario Start ---\n";
static const char msg_demo_step[] = "[Demo] Step ";
static const char msg_demo_end[] = "--- Demo Scenario End ---\n";
static const char msg_demo_s1[] = ": Write LBA 2, data 100\n";
static const char msg_demo_s2[] = ": Write LBA 1, data 50\n";
static const char msg_demo_s3[] = ": Read LBA 2\n";
static const char msg_demo_s4[] = ": Overwrite LBA 2, data 200\n";
static const char msg_demo_s5[] = ": Read LBA 2 (expect 200)\n";
static const char msg_demo_s6[] = ": Print Mapping Table\n";
static const char msg_demo_s7[] = ": Print Physical Page Table\n";
static const char msg_demo_s8[] = ": Run Simple GC\n";
static const char msg_demo_s9[] = ": Print Physical Page Table (after GC)\n";
static const char msg_demo_s10[] = ": Print Trace Log\n";

/* =============================================================================
 * Function declarations: kept close to ASM labels
 * ============================================================================= */

static void print_string(const char *s);
static void print_int(int value);
static void print_newline(void);
static void print_separator(void);
static int read_int(void);
static void run_state(const char *message, int milliseconds);

static void log_write_event(int lba, int pba, int data);
static void log_read_event(int lba, int pba, int data);
static void log_gc_event(int freed_pages);
static void log_reset_event(void);
static int trace_check_full(void);
static void print_trace_log(void);
static void reset_trace_log(void);

static int check_lba_range(int lba);
static int get_lba_mapping(int lba);
static void set_lba_mapping(int lba, int pba);
static void reset_mapping_table(void);
static void print_mapping_table(void);

static int get_pba_state(int pba);
static void set_pba_state(int pba, int state);
static int get_pba_data(int pba);
static void set_pba_data(int pba, int data);
static int find_free_pba(void);
static void reset_nand_table(void);
static void print_physical_page_table(void);

static int get_block_id_by_pba(int pba);
static void increase_block_erase_count(int block_id);
static void print_block_table(void);
static void reset_block_table(void);

static void submit_write_request(void);
static void ftl_write_core(int lba, int data);
static void submit_read_request(void);
static void ftl_read_core(int lba);
static void run_simple_gc(void);

static int count_valid_pages(void);
static void print_page_state_summary(void);
static void print_statistics(void);
static void print_full_status(void);
static void reset_ssd(void);
static void reset_statistics(void);
static void run_demo_scenario(void);

static void cmd_write(void);
static void cmd_read(void);
static void cmd_print_mapping(void);
static void cmd_print_physical(void);
static void cmd_print_block(void);
static void cmd_print_stats(void);
static void cmd_print_trace(void);
static void cmd_full_status(void);
static void cmd_demo(void);
static void cmd_reset(void);
static void cmd_gc(void);
static void touch_unused_asm_symbols(void);

/* =============================================================================
 * Small utility layer replacing syscall print/read/sleep
 * ============================================================================= */

static void ms_sleep(int milliseconds)
{
    if (milliseconds <= 0) {
        return;
    }

#if defined(_WIN32)
    Sleep((DWORD)milliseconds);
#else
    struct timespec ts;
    ts.tv_sec = milliseconds / 1000;
    ts.tv_nsec = (long)(milliseconds % 1000) * 1000000L;
    nanosleep(&ts, NULL);
#endif
}

static void print_string(const char *s)
{
    fputs(s, stdout);
    fflush(stdout);
}

static void print_int(int value)
{
    printf("%d", value);
    fflush(stdout);
}

static void print_newline(void)
{
    print_string(msg_newline);
}

static void print_separator(void)
{
    print_string(msg_separator);
}

static int read_int(void)
{
    int value = 0;

    if (scanf("%d", &value) != 1) {
        int ch;

        while ((ch = getchar()) != '\n' && ch != EOF) {
            ;
        }

        return 0;
    }

    return value;
}

/* ASM label: run_state */
static void run_state(const char *message, int milliseconds)
{
    print_string(msg_state_op);
    print_string(message);
    print_int(milliseconds);
    print_string(msg_ms);

    total_state_count++;
    total_simulated_time += milliseconds;

    ms_sleep(milliseconds);
}

/* =============================================================================
 * Trace log functions
 * ============================================================================= */

/* ASM label: trace_check_full */
static int trace_check_full(void)
{
    if (trace_count < TRACE_MAX) {
        return 0;
    }

    return 1;
}

/* ASM label: log_write_event */
static void log_write_event(int lba, int pba, int data)
{
    int index;

    if (trace_check_full()) {
        return;
    }

    index = trace_count;
    trace_type[index] = TTYPE_WRITE;
    trace_lba[index] = lba;
    trace_pba[index] = pba;
    trace_data[index] = data;
    trace_count++;
}

/* ASM label: log_read_event */
static void log_read_event(int lba, int pba, int data)
{
    int index;

    if (trace_check_full()) {
        return;
    }

    index = trace_count;
    trace_type[index] = TTYPE_READ;
    trace_lba[index] = lba;
    trace_pba[index] = pba;
    trace_data[index] = data;
    trace_count++;
}

/* ASM label: log_gc_event */
static void log_gc_event(int freed_pages)
{
    int index;

    if (trace_check_full()) {
        return;
    }

    index = trace_count;
    trace_type[index] = TTYPE_GC;
    trace_lba[index] = -1;
    trace_pba[index] = -1;
    trace_data[index] = freed_pages;
    trace_count++;
}

/* ASM label: log_reset_event */
static void log_reset_event(void)
{
    int index;

    if (trace_check_full()) {
        return;
    }

    index = trace_count;
    trace_type[index] = TTYPE_RESET;
    trace_lba[index] = -1;
    trace_pba[index] = -1;
    trace_data[index] = 0;
    trace_count++;
}

/* ASM label: print_trace_log */
static void print_trace_log(void)
{
    int i;

    print_string(msg_trace_hdr);

    if (trace_count == 0) {
        print_string(msg_trace_none);
        return;
    }

    for (i = 0; i < trace_count; i++) {
        print_int(i);
        print_string(msg_trace_pipe);

        switch (trace_type[i]) {
        case TTYPE_WRITE:
            print_string(msg_t_write);
            print_string(msg_t_lba);
            print_int(trace_lba[i]);
            print_string(msg_t_pba);
            print_int(trace_pba[i]);
            print_string(msg_t_data);
            print_int(trace_data[i]);
            print_newline();
            break;

        case TTYPE_READ:
            print_string(msg_t_read);
            print_string(msg_t_lba);
            print_int(trace_lba[i]);
            print_string(msg_t_pba);
            print_int(trace_pba[i]);
            print_string(msg_t_data);
            print_int(trace_data[i]);
            print_newline();
            break;

        case TTYPE_GC:
            print_string(msg_t_gc);
            print_string(msg_t_freed);
            print_int(trace_data[i]);
            print_newline();
            break;

        case TTYPE_RESET:
            print_string(msg_t_reset);
            print_newline();
            break;

        default:
            break;
        }
    }
}

/* ASM label: reset_trace_log */
static void reset_trace_log(void)
{
    trace_count = 0;
}

/* =============================================================================
 * Mapping table functions
 * ============================================================================= */

/* ASM label: check_lba_range */
static int check_lba_range(int lba)
{
    if (lba < 0) {
        return 0;
    }

    if (lba >= LBA_COUNT) {
        return 0;
    }

    return 1;
}

/* ASM label: get_lba_mapping */
static int get_lba_mapping(int lba)
{
    return lba_map[lba];
}

/* ASM label: set_lba_mapping */
static void set_lba_mapping(int lba, int pba)
{
    lba_map[lba] = pba;
}

/* ASM label: reset_mapping_table */
static void reset_mapping_table(void)
{
    int i;

    for (i = 0; i < LBA_COUNT; i++) {
        lba_map[i] = -1;
    }
}

/* ASM label: print_mapping_table */
static void print_mapping_table(void)
{
    int i;

    print_string(msg_map_hdr);

    for (i = 0; i < LBA_COUNT; i++) {
        print_string(msg_lba_prefix);
        print_int(i);
        print_string(msg_arrow_pba);
        print_int(lba_map[i]);
        print_newline();
    }
}

/* Physical page table functions */

/* ASM label: get_pba_state */
static int get_pba_state(int pba)
{
    return pba_state[pba];
}

/* ASM label: set_pba_state */
static void set_pba_state(int pba, int state)
{
    pba_state[pba] = state;
}

/* ASM label: get_pba_data */
static int get_pba_data(int pba)
{
    return pba_data[pba];
}

/* ASM label: set_pba_data */
static void set_pba_data(int pba, int data)
{
    pba_data[pba] = data;
}

/* ASM label: find_free_pba */
static int find_free_pba(void)
{
    int pba;

    for (pba = 0; pba < PBA_COUNT; pba++) {
        if (pba_state[pba] == FREE) {
            return pba;
        }
    }

    return -1;
}

/* ASM label: reset_nand_table */
static void reset_nand_table(void)
{
    int pba;

    for (pba = 0; pba < PBA_COUNT; pba++) {
        pba_state[pba] = FREE;
        pba_data[pba] = 0;
    }
}

/* ASM label: print_physical_page_table */
static void print_physical_page_table(void)
{
    int pba;

    print_string(msg_pba_hdr);

    for (pba = 0; pba < PBA_COUNT; pba++) {
        print_string(msg_pba_prefix);
        print_int(pba);
        print_string(msg_sep_state);
        print_int(get_pba_state(pba));
        print_string(msg_sep_data);
        print_int(get_pba_data(pba));
        print_newline();
    }
}

/* Block table functions */

/* ASM label: get_block_id_by_pba */
static int get_block_id_by_pba(int pba)
{
    return pba / PBA_PER_BLK;
}

/* ASM label: increase_block_erase_count */
static void increase_block_erase_count(int block_id)
{
    block_erase_count[block_id]++;
}

/* ASM label: print_block_table */
static void print_block_table(void)
{
    int block;

    print_string(msg_blk_hdr);

    for (block = 0; block < BLOCK_COUNT; block++) {
        int first_pba = block * PBA_PER_BLK;
        int last_pba = first_pba + (PBA_PER_BLK - 1);

        print_string(msg_blk_line);
        print_int(block);
        print_string(msg_blk_pba);
        print_int(first_pba);
        print_string(msg_blk_to);
        print_int(last_pba);
        print_string(msg_blk_erase);
        print_int(block_erase_count[block]);
        print_newline();
    }
}

/* ASM label: reset_block_table */
static void reset_block_table(void)
{
    block_erase_count[0] = 0;
    block_erase_count[1] = 0;
}

/* =============================================================================
 * FTL command flow
 * ============================================================================= */

/* ASM label: submit_write_request */
static void submit_write_request(void)
{
    int lba;
    int data;

    print_string(msg_write_lba);
    lba = read_int();

    if (!check_lba_range(lba)) {
        print_string(msg_lba_range);
        return;
    }

    print_string(msg_write_data);
    data = read_int();

    ftl_write_core(lba, data);
}

/* ASM label: ftl_write_core */
static void ftl_write_core(int lba, int data)
{
    int old_pba;
    int new_pba;

    print_string(msg_sel_lba);
    print_int(lba);
    print_newline();

    old_pba = get_lba_mapping(lba);

    if (old_pba != -1) {
        print_string(msg_old_pba);
        print_int(old_pba);
        print_newline();

        print_string(msg_pba_inv_a);
        print_int(old_pba);
        print_string(msg_pba_inv_b);

        set_pba_state(old_pba, INVALID);

        /* Preserved from ASM: invalidating an old PBA also decrements free_page_count. */
        free_page_count--;
        invalid_page_count++;
    } else {
        print_string(msg_no_old_map);
    }

    new_pba = find_free_pba();

    if (new_pba == -1) {
        print_string(msg_no_free);
        return;
    }

    set_pba_state(new_pba, VALID);
    set_pba_data(new_pba, data);
    set_lba_mapping(lba, new_pba);

    total_write_count++;
    free_page_count--;

    print_string(msg_new_pba);
    print_int(new_pba);
    print_newline();

    print_string(msg_lba_prefix);
    print_int(lba);
    print_string(msg_arrow_pba);
    print_int(new_pba);
    print_string(msg_data_eq);
    print_int(data);
    print_newline();

    log_write_event(lba, new_pba, data);

    run_state(msg_write_ok, 1);
}

/* ASM label: submit_read_request */
static void submit_read_request(void)
{
    int lba;

    print_string(msg_read_lba);
    lba = read_int();

    if (!check_lba_range(lba)) {
        print_string(msg_lba_range);
        return;
    }

    ftl_read_core(lba);
}

/* ASM label: ftl_read_core */
static void ftl_read_core(int lba)
{
    int pba;
    int data;

    print_string(msg_read_lba_p);
    print_int(lba);
    print_newline();

    pba = get_lba_mapping(lba);

    if (pba == -1) {
        print_string(msg_no_data);
        return;
    }

    print_string(msg_mapped_pba);
    print_int(pba);
    print_newline();

    data = get_pba_data(pba);

    print_string(msg_data_val);
    print_int(data);
    print_newline();

    total_read_count++;

    log_read_event(lba, pba, data);
}

/* ASM label: run_simple_gc */
static void run_simple_gc(void)
{
    int freed_pages = 0;
    int pba;

    print_string(msg_gc_start);

    for (pba = 0; pba < PBA_COUNT; pba++) {
        if (get_pba_state(pba) != INVALID) {
            continue;
        }

        int block_id;

        pba_state[pba] = FREE;

        print_string(msg_gc_pba_ok);
        print_int(pba);
        print_string(msg_gc_freed1);

        block_id = get_block_id_by_pba(pba);

        print_int(block_id);
        print_string(msg_gc_freed2);

        increase_block_erase_count(block_id);

        freed_pages++;
    }

    free_page_count += freed_pages;
    invalid_page_count -= freed_pages;
    gc_count++;

    print_string(msg_gc_freed);
    print_int(freed_pages);
    print_newline();

    print_string(msg_gc_done);

    log_gc_event(freed_pages);
}

/* =============================================================================
 * Statistics and status
 * ============================================================================= */

/* ASM label: count_valid_pages */
static int count_valid_pages(void)
{
    int pba;
    int count = 0;

    for (pba = 0; pba < PBA_COUNT; pba++) {
        if (get_pba_state(pba) == VALID) {
            count++;
        }
    }

    return count;
}

/* ASM label: print_page_state_summary */
static void print_page_state_summary(void)
{
    print_string(msg_ps_hdr);

    print_string(msg_ps_free);
    print_int(free_page_count);
    print_newline();

    print_string(msg_ps_valid);
    print_int(count_valid_pages());
    print_newline();

    print_string(msg_ps_invalid);
    print_int(invalid_page_count);
    print_newline();
}

/* ASM label: print_statistics */
static void print_statistics(void)
{
    print_string(msg_stats_hdr);

    print_string(msg_st_writes);
    print_int(total_write_count);
    print_newline();

    print_string(msg_st_reads);
    print_int(total_read_count);
    print_newline();

    print_string(msg_st_states);
    print_int(total_state_count);
    print_newline();

    print_string(msg_st_time);
    print_int(total_simulated_time);
    print_newline();

    print_string(msg_st_free);
    print_int(free_page_count);
    print_newline();

    print_string(msg_st_valid);
    print_int(count_valid_pages());
    print_newline();

    print_string(msg_st_inv);
    print_int(invalid_page_count);
    print_newline();

    print_string(msg_st_gc);
    print_int(gc_count);
    print_newline();
}

/* ASM label: print_full_status */
static void print_full_status(void)
{
    print_string(msg_full_hdr);

    print_statistics();
    print_separator();

    print_page_state_summary();
    print_separator();

    print_mapping_table();
    print_separator();

    print_physical_page_table();
    print_separator();

    print_block_table();
    print_separator();

    print_trace_log();

    print_string(msg_full_end);
}

/* ASM label: reset_statistics */
static void reset_statistics(void)
{
    total_write_count = 0;
    total_read_count = 0;
    total_state_count = 0;
    total_simulated_time = 0;
    invalid_page_count = 0;
    gc_count = 0;
    free_page_count = PBA_COUNT;
}

/* ASM label: reset_ssd */
static void reset_ssd(void)
{
    print_string(msg_reset_start);

    reset_nand_table();
    reset_mapping_table();
    reset_block_table();
    reset_statistics();
    reset_trace_log();
    log_reset_event();

    print_string(msg_reset_done);
}

/* =============================================================================
 * Demo scenario
 * ============================================================================= */

/* ASM label: run_demo_scenario */
static void run_demo_scenario(void)
{
    print_string(msg_demo_hdr);

    print_string(msg_demo_step);
    print_int(1);
    print_string(msg_demo_s1);
    ftl_write_core(2, 100);
    print_separator();

    print_string(msg_demo_step);
    print_int(2);
    print_string(msg_demo_s2);
    ftl_write_core(1, 50);
    print_separator();

    print_string(msg_demo_step);
    print_int(3);
    print_string(msg_demo_s3);
    ftl_read_core(2);
    print_separator();

    print_string(msg_demo_step);
    print_int(4);
    print_string(msg_demo_s4);
    ftl_write_core(2, 200);
    print_separator();

    print_string(msg_demo_step);
    print_int(5);
    print_string(msg_demo_s5);
    ftl_read_core(2);
    print_separator();

    print_string(msg_demo_step);
    print_int(6);
    print_string(msg_demo_s6);
    print_mapping_table();
    print_separator();

    print_string(msg_demo_step);
    print_int(7);
    print_string(msg_demo_s7);
    print_physical_page_table();
    print_separator();

    print_string(msg_demo_step);
    print_int(8);
    print_string(msg_demo_s8);
    run_simple_gc();
    print_separator();

    print_string(msg_demo_step);
    print_int(9);
    print_string(msg_demo_s9);
    print_physical_page_table();
    print_separator();

    print_string(msg_demo_step);
    print_int(10);
    print_string(msg_demo_s10);
    print_trace_log();

    print_string(msg_demo_end);
}

/* =============================================================================
 * Command wrappers: kept because ASM had cmd_* labels
 * ============================================================================= */

static void cmd_write(void)
{
    submit_write_request();
}

static void cmd_read(void)
{
    submit_read_request();
}

static void cmd_print_mapping(void)
{
    print_mapping_table();
}

static void cmd_print_physical(void)
{
    print_physical_page_table();
}

static void cmd_print_block(void)
{
    print_block_table();
}

static void cmd_print_stats(void)
{
    print_statistics();
}

static void cmd_print_trace(void)
{
    print_trace_log();
}

static void cmd_full_status(void)
{
    print_full_status();
}

static void cmd_demo(void)
{
    run_demo_scenario();
}

static void cmd_reset(void)
{
    reset_ssd();
}

static void cmd_gc(void)
{
    run_simple_gc();
}

/* ASM-defined but currently unused data labels are touched here so the C file
 * can be built with strict warnings while still preserving those symbols. */
static void touch_unused_asm_symbols(void)
{
    (void)msg_trace_full;
    (void)msg_colon_sp;
}

/* =============================================================================
 * main / menu_loop
 * ============================================================================= */

int main(void)
{
    touch_unused_asm_symbols();

    for (;;) {
        int option;

        print_string(msg_menu);
        option = read_int();

        switch (option) {
        case 0:
            print_string(msg_bye);
            return 0;

        case 1:
            cmd_write();
            break;

        case 2:
            cmd_read();
            break;

        case 3:
            cmd_print_mapping();
            break;

        case 4:
            cmd_print_physical();
            break;

        case 5:
            cmd_print_block();
            break;

        case 6:
            cmd_print_stats();
            break;

        case 7:
            cmd_print_trace();
            break;

        case 8:
            cmd_full_status();
            break;

        case 9:
            cmd_demo();
            break;

        case 10:
            cmd_reset();
            break;

        case 11:
            cmd_gc();
            break;

        default:
            print_string(msg_invalid_op);
            break;
        }
    }
}

/*
 * Note:
 * msg_trace_full and msg_colon_sp are intentionally kept even though the ASM code
 * defines them but does not actually print them in the current control flow.
 */
