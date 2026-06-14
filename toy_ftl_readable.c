#ifndef _WIN32
#define _POSIX_C_SOURCE 199309L
#endif

#include <stdio.h>
#include <stdlib.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <time.h>
#endif

#define LBA_COUNT 4
#define PBA_COUNT 8
#define BLOCK_SIZE 2
#define BLOCK_COUNT 4

#define FREE 0
#define VALID 1
#define INVALID 2

#define TRACE_MAX 20
#define OUTPUT_DELAY_MS 50

#define TTYPE_WRITE 1
#define TTYPE_READ  2
#define TTYPE_GC    3
#define TTYPE_RESET 4
#define TTYPE_MIGRATE 5

/*
 * data.asm
 *
 * ASM의 전역 배열과 카운터를 C 배열/변수로 그대로 옮긴 설명용 코드다.
 * PBA 2개를 하나의 block으로 보므로 block 구성은 다음과 같다.
 *   block 0: PBA 0, 1
 *   block 1: PBA 2, 3
 *   block 2: PBA 4, 5
 *   block 3: PBA 6, 7
 */
static int lba_map[LBA_COUNT] = { -1, -1, -1, -1 };
static int pba_state[PBA_COUNT] = { FREE, FREE, FREE, FREE, FREE, FREE, FREE, FREE };
static int pba_data[PBA_COUNT] = { 0, 0, 0, 0, 0, 0, 0, 0 };

/*
 * trace 저장 규칙:
 *   trace_type = WRITE/READ/GC/RESET/MIGRATE 중 하나
 *   trace_lba  = 관련 LBA, 없으면 -1
 *   trace_pba  = 관련 PBA 또는 MIGRATE의 old PBA
 *   trace_data = data 값, GC freed count, 또는 MIGRATE의 new PBA
 */
static int trace_type[TRACE_MAX];
static int trace_lba[TRACE_MAX];
static int trace_pba[TRACE_MAX];
static int trace_data[TRACE_MAX];
static int trace_count = 0;

static int total_write_count = 0;
static int total_read_count = 0;
static int total_state_count = 0;
static int total_simulated_time = 0;
static int free_page_count = PBA_COUNT;
static int invalid_page_count = 0;
static int gc_count = 0;
static int erase_count = 0;

/* util.asm */
static void delay_ms(int ms)
{
#ifdef _WIN32
    Sleep((DWORD)ms);
#else
    struct timespec ts;

    ts.tv_sec = ms / 1000;
    ts.tv_nsec = (long)(ms % 1000) * 1000000L;
    nanosleep(&ts, NULL);
#endif
}

#define delayed_printf(...)                 \
    do {                                    \
        printf(__VA_ARGS__);                \
        delay_ms(OUTPUT_DELAY_MS);          \
    } while (0)

static void print_string(const char *s) { delayed_printf("%s", s); }
static void print_int(int value) { delayed_printf("%d", value); }
static void print_newline(void) { delayed_printf("\n"); }
static void print_separator(void) { delayed_printf("-----------------------------\n"); }

static int read_int(void)                          /* 정수 하나 입력 */
{
    char buf[128];

    if (!fgets(buf, sizeof(buf), stdin)) {
        return 0;
    }

    return (int)strtol(buf, NULL, 10);
}

static void run_state(const char *message, int ms) /* 상태 메시지와 시간 누적 */
{
    delayed_printf("[State] %s%d ms\n", message, ms);
    total_state_count++;
    total_simulated_time += ms;
}

/* ftl_mapping.asm */
static int check_lba_range(int lba)                /* LBA가 0~3 범위인지 확인 */
{
    return lba >= 0 && lba < LBA_COUNT;
}

static int get_lba_mapping(int lba)                /* lba_map[LBA] 읽기 */
{
    return lba_map[lba];
}

static void set_lba_mapping(int lba, int pba)      /* lba_map[LBA] = PBA */
{
    lba_map[lba] = pba;
}

static int find_lba_by_pba(int pba)                /* GC migration 때 old PBA가 담당하던 LBA 찾기 */
{
    int lba;

    for (lba = 0; lba < LBA_COUNT; lba++) {
        if (lba_map[lba] == pba) {
            return lba;
        }
    }

    return -1;
}

static void reset_mapping_table(void)              /* 모든 LBA mapping을 비어 있음(-1)으로 초기화 */
{
    int i;

    for (i = 0; i < LBA_COUNT; i++) {
        lba_map[i] = -1;
    }
}

static void print_mapping_table(void)              /* LBA별 현재 PBA mapping 출력 */
{
    int i;

    print_string("[Mapping Table]\n");
    for (i = 0; i < LBA_COUNT; i++) {
        print_string("LBA ");
        print_int(i);
        print_string(" -> PBA ");
        print_int(lba_map[i]);
        print_newline();
    }
}

/* nand_model.asm */
static int find_free_pba_excluding_block(int block_id)
{
    int pba;
    int start = block_id * BLOCK_SIZE;
    int end = start + BLOCK_SIZE;

    /* migration 목적지는 erase될 victim block 안에서 고르면 안 된다. */
    for (pba = 0; pba < PBA_COUNT; pba++) {
        if (pba >= start && pba < end) {
            continue;
        }
        if (pba_state[pba] == FREE) {
            return pba;
        }
    }

    return -1;
}

static void erase_block(int block_id)              /* block 안의 모든 PBA를 FREE/data 0으로 erase */
{
    int pba;
    int start = block_id * BLOCK_SIZE;
    int end = start + BLOCK_SIZE;

    for (pba = start; pba < end; pba++) {
        pba_state[pba] = FREE;
        pba_data[pba] = 0;
    }
}

static void recount_page_counts(void)              /* pba_state 전체를 다시 세서 count 재계산 */
{
    int pba;
    int free_count = 0;
    int invalid_count = 0;

    for (pba = 0; pba < PBA_COUNT; pba++) {
        if (pba_state[pba] == FREE) {
            free_count++;
        } else if (pba_state[pba] == INVALID) {
            invalid_count++;
        }
    }

    free_page_count = free_count;
    invalid_page_count = invalid_count;
}

static int get_pba_state(int pba)                  /* pba_state[PBA] 읽기 */
{
    return pba_state[pba];
}

static void set_pba_state(int pba, int state)      /* pba_state[PBA] = state */
{
    pba_state[pba] = state;
}

static int get_pba_data(int pba)                   /* pba_data[PBA] 읽기 */
{
    return pba_data[pba];
}

static void set_pba_data(int pba, int data)        /* pba_data[PBA] = data */
{
    pba_data[pba] = data;
}

static int find_free_pba(void)                     /* 가장 앞의 FREE PBA 찾기 */
{
    int pba;

    for (pba = 0; pba < PBA_COUNT; pba++) {
        if (pba_state[pba] == FREE) {
            return pba;
        }
    }

    return -1;
}

static void reset_nand_table(void)                 /* 모든 PBA 상태와 data 초기화 */
{
    int pba;

    for (pba = 0; pba < PBA_COUNT; pba++) {
        pba_state[pba] = FREE;
        pba_data[pba] = 0;
    }
}

static void print_physical_page_table(void)        /* PBA별 상태와 data 출력 */
{
    int pba;

    print_string("[Physical Page Table]\n");
    print_string("State: 0=FREE, 1=VALID, 2=INVALID\n");

    for (pba = 0; pba < PBA_COUNT; pba++) {
        print_string("PBA ");
        print_int(pba);
        print_string(" | State: ");
        print_int(get_pba_state(pba));
        print_string(" | data ");
        print_int(get_pba_data(pba));
        print_newline();
    }
}

/* trace.asm */
static int trace_check_full(void)                  /* trace가 꽉 찼는지 확인 */
{
    return trace_count >= TRACE_MAX;
}

static void log_write_event(int lba, int pba, int data)
{
    if (trace_check_full()) {
        return;
    }

    trace_type[trace_count] = TTYPE_WRITE;
    trace_lba[trace_count] = lba;
    trace_pba[trace_count] = pba;
    trace_data[trace_count] = data;
    trace_count++;
}

static void log_read_event(int lba, int pba, int data)
{
    if (trace_check_full()) {
        return;
    }

    trace_type[trace_count] = TTYPE_READ;
    trace_lba[trace_count] = lba;
    trace_pba[trace_count] = pba;
    trace_data[trace_count] = data;
    trace_count++;
}

static void log_gc_event(int freed_count)
{
    if (trace_check_full()) {
        return;
    }

    trace_type[trace_count] = TTYPE_GC;
    trace_lba[trace_count] = -1;
    trace_pba[trace_count] = -1;
    trace_data[trace_count] = freed_count;
    trace_count++;
}

static void log_migrate_event(int lba, int old_pba, int new_pba)
{
    if (trace_check_full()) {
        return;
    }

    trace_type[trace_count] = TTYPE_MIGRATE;
    trace_lba[trace_count] = lba;
    trace_pba[trace_count] = old_pba;
    trace_data[trace_count] = new_pba;             /* MIGRATE에서는 trace_data가 new PBA */
    trace_count++;
}

static void log_reset_event(void)
{
    if (trace_check_full()) {
        return;
    }

    trace_type[trace_count] = TTYPE_RESET;
    trace_lba[trace_count] = -1;
    trace_pba[trace_count] = -1;
    trace_data[trace_count] = 0;
    trace_count++;
}

static void print_trace_log(void)
{
    int i;

    print_string("[Trace Log]\n");

    if (trace_count == 0) {
        print_string("(No recorded events)\n");
        return;
    }

    for (i = 0; i < trace_count; i++) {
        delayed_printf("%d | ", i);

        if (trace_type[i] == TTYPE_WRITE) {
            delayed_printf("WRITE | LBA %d | PBA %d | DATA %d\n",
                           trace_lba[i], trace_pba[i], trace_data[i]);
        } else if (trace_type[i] == TTYPE_READ) {
            delayed_printf("READ  | LBA %d | PBA %d | DATA %d\n",
                           trace_lba[i], trace_pba[i], trace_data[i]);
        } else if (trace_type[i] == TTYPE_GC) {
            delayed_printf("GC    | Freed pages: %d\n", trace_data[i]);
        } else if (trace_type[i] == TTYPE_RESET) {
            delayed_printf("RESET\n");
        } else if (trace_type[i] == TTYPE_MIGRATE) {
            delayed_printf("MIGRATE | LBA %d | PBA %d -> PBA %d\n",
                           trace_lba[i], trace_pba[i], trace_data[i]);
        }
    }
}

static void reset_trace_log(void)                  /* trace_count만 0으로 돌리면 이전 기록은 무시됨 */
{
    trace_count = 0;
}

/* gc.asm */
static void run_gc(void)
{
    int block;
    int victim_block = -1;
    int victim_invalid_count = 0;
    int victim_start;
    int victim_end;
    int victim_valid_count = 0;
    int outside_free_count = 0;
    int pba;

    print_string("[GC] Scanning blocks...\n");

    /* 1. 모든 block을 검사해서 INVALID page가 가장 많은 block을 victim으로 고른다. */
    for (block = 0; block < BLOCK_COUNT; block++) {
        int start = block * BLOCK_SIZE;
        int end = start + BLOCK_SIZE;
        int invalid_count = 0;

        for (pba = start; pba < end; pba++) {
            if (pba_state[pba] == INVALID) {
                invalid_count++;
            }
        }

        if (invalid_count > victim_invalid_count) {
            victim_invalid_count = invalid_count;
            victim_block = block;
        }
    }

    if (victim_invalid_count == 0) {
        print_string("[GC] No block has invalid pages.\n");
        return;
    }

    delayed_printf("[GC] Victim block: %d\n", victim_block);

    victim_start = victim_block * BLOCK_SIZE;
    victim_end = victim_start + BLOCK_SIZE;

    /*
     * 2. migration 전에 미리 검사한다.
     * victim 안 VALID 수보다 victim 밖 FREE 수가 적으면 상태를 건드리지 않고 실패한다.
     */
    for (pba = 0; pba < PBA_COUNT; pba++) {
        if (pba >= victim_start && pba < victim_end) {
            if (pba_state[pba] == VALID) {
                victim_valid_count++;
            }
        } else if (pba_state[pba] == FREE) {
            outside_free_count++;
        }
    }

    if (outside_free_count < victim_valid_count) {
        print_string("[GC] Not enough free page outside victim block.\n");
        return;
    }

    /*
     * 3. victim block 안의 VALID page를 victim 밖 FREE PBA로 복사한다.
     * lba_map을 old PBA에서 new PBA로 바꿔야 read가 계속 최신 data를 찾을 수 있다.
     */
    for (pba = victim_start; pba < victim_end; pba++) {
        if (pba_state[pba] == VALID) {
            int data = get_pba_data(pba);
            int lba = find_lba_by_pba(pba);
            int new_pba;

            if (lba == -1) {
                print_string("[GC] Not enough free page outside victim block.\n");
                return;
            }

            new_pba = find_free_pba_excluding_block(victim_block);
            if (new_pba == -1) {
                print_string("[GC] Not enough free page outside victim block.\n");
                return;
            }

            delayed_printf("[GC] Move valid page PBA %d -> PBA %d\n", pba, new_pba);

            set_pba_state(new_pba, VALID);
            set_pba_data(new_pba, data);
            set_lba_mapping(lba, new_pba);
            log_migrate_event(lba, pba, new_pba);
        }
    }

    /* 4. VALID page를 모두 옮겼으므로 victim block 전체를 erase한다. */
    delayed_printf("[GC] Erase block %d -> FREE pages\n", victim_block);
    erase_block(victim_block);
    recount_page_counts();

    gc_count++;
    erase_count++;

    delayed_printf("[GC] Freed page count: %d\n", victim_invalid_count);
    print_string("[GC] Done\n");

    log_gc_event(victim_invalid_count);
}

/* status.asm */
static int count_valid_pages(void)                  /* VALID page 개수 계산 */
{
    int pba;
    int count = 0;

    for (pba = 0; pba < PBA_COUNT; pba++) {
        if (pba_state[pba] == VALID) {
            count++;
        }
    }

    return count;
}

static void print_page_state_summary(void)
{
    print_string("[Page State Summary]\n");
    delayed_printf("  FREE    : %d\n", free_page_count);
    delayed_printf("  VALID   : %d\n", count_valid_pages());
    delayed_printf("  INVALID : %d\n", invalid_page_count);
}

static void print_statistics(void)
{
    print_string("[Statistics]\n");
    delayed_printf("Total WRITE count : %d\n", total_write_count);
    delayed_printf("Total READ count  : %d\n", total_read_count);
    delayed_printf("State run count   : %d\n", total_state_count);
    delayed_printf("Total time (ms)   : %d\n", total_simulated_time);
    delayed_printf("FREE page count   : %d\n", free_page_count);
    delayed_printf("VALID page count  : %d\n", count_valid_pages());
    delayed_printf("INVALID page count: %d\n", invalid_page_count);
    delayed_printf("GC run count      : %d\n", gc_count);
    delayed_printf("Block erase count : %d\n", erase_count);
}

static void print_full_status(void)
{
    print_string("\n======= Full SSD Status =======\n");
    print_statistics();
    print_separator();
    print_page_state_summary();
    print_separator();
    print_mapping_table();
    print_separator();
    print_physical_page_table();
    print_separator();
    print_trace_log();
    print_string("================================\n");
}

/* ftl_write.asm */
static void ftl_write_core(int lba, int data)
{
    int old_pba;
    int new_pba;

    delayed_printf("Selected LBA: %d\n", lba);

    old_pba = get_lba_mapping(lba);

    /*
     * 새 FREE PBA를 먼저 찾는다.
     * FREE가 없으면 기존 VALID page를 INVALID로 바꾸지 않고 실패해야 data가 보존된다.
     */
    new_pba = find_free_pba();
    if (new_pba == -1) {
        print_string("No free page. Run GC first.\n");
        return;
    }

    if (old_pba != -1) {
        delayed_printf("Old PBA: %d\n", old_pba);
        delayed_printf("PBA %d -> INVALID\n", old_pba);
        set_pba_state(old_pba, INVALID);
    } else {
        print_string("This LBA has no previous mapping.\n");
    }

    set_pba_state(new_pba, VALID);
    set_pba_data(new_pba, data);
    set_lba_mapping(lba, new_pba);

    recount_page_counts();
    total_write_count++;

    delayed_printf("Assigned new PBA: %d\n", new_pba);
    delayed_printf("LBA %d -> PBA %d, data = %d\n", lba, new_pba, data);

    log_write_event(lba, new_pba, data);
    run_state("Write complete. ", 1);
}

static void submit_write_request(void)
{
    int lba;
    int data;

    print_string("Enter LBA to write (0-3): ");
    lba = read_int();

    if (!check_lba_range(lba)) {
        print_string("LBA is out of range.\n");
        return;
    }

    print_string("Enter data: ");
    data = read_int();

    ftl_write_core(lba, data);
}

/* ftl_read.asm */
static void ftl_read_core(int lba)
{
    int pba;
    int data;

    delayed_printf("Reading LBA: %d\n", lba);

    pba = get_lba_mapping(lba);
    if (pba == -1) {
        print_string("No data for this LBA.\n");
        return;
    }

    delayed_printf("Mapped PBA: %d\n", pba);

    data = get_pba_data(pba);
    delayed_printf("data: %d\n", data);

    total_read_count++;
    log_read_event(lba, pba, data);
}

static void submit_read_request(void)
{
    int lba;

    print_string("Enter LBA to read (0-3): ");
    lba = read_int();

    if (!check_lba_range(lba)) {
        print_string("LBA is out of range.\n");
        return;
    }

    ftl_read_core(lba);
}

/* reset.asm */
static void reset_statistics(void)
{
    total_write_count = 0;
    total_read_count = 0;
    total_state_count = 0;
    total_simulated_time = 0;
    free_page_count = PBA_COUNT;
    invalid_page_count = 0;
    gc_count = 0;
    erase_count = 0;
}

static void reset_ssd(void)
{
    print_string("[Reset] Resetting SSD state...\n");

    reset_nand_table();
    reset_mapping_table();
    reset_statistics();
    reset_trace_log();
    log_reset_event();

    print_string("[Reset] Reset complete.\n");
}

/* demo.asm */
static void run_demo_scenario(void)
{
    print_string("\n--- Demo start ---\n");

    print_string("[Demo] Step 1: Write 100 to LBA 2\n");
    ftl_write_core(2, 100);        /* PBA 0에 LBA 2의 data 100 저장 */
    print_separator();

    print_string("[Demo] Step 2: Write 50 to LBA 1\n");
    ftl_write_core(1, 50);         /* PBA 1에 LBA 1의 data 50 저장 */
    print_separator();

    print_string("[Demo] Step 3: Read LBA 2\n");
    ftl_read_core(2);
    print_separator();

    print_string("[Demo] Step 4: Write 200 to LBA 2 again\n");
    ftl_write_core(2, 200);        /* PBA 0은 INVALID, 새 PBA는 VALID */
    print_separator();

    print_string("[Demo] Step 5: Read LBA 2 again (expect 200)\n");
    ftl_read_core(2);
    print_separator();

    print_string("[Demo] Step 6: Print mapping table before GC\n");
    print_mapping_table();
    print_separator();

    print_string("[Demo] Step 7: Print physical page table before GC\n");
    print_physical_page_table();   /* block 0: PBA 0 INVALID + PBA 1 VALID */
    print_separator();

    print_string("[Demo] Step 8: Run GC (expect valid page migration)\n");
    run_gc();                      /* PBA 1의 VALID page를 victim 밖 FREE PBA로 이동 */
    print_separator();

    print_string("[Demo] Step 9: Read LBA 1 after GC (expect 50)\n");
    ftl_read_core(1);              /* migration 후에도 LBA 1 data가 보존됐는지 확인 */
    print_separator();

    print_string("[Demo] Step 10: Print mapping table after GC\n");
    print_mapping_table();         /* LBA 1 mapping이 old PBA에서 new PBA로 바뀐 것 확인 */
    print_separator();

    print_string("[Demo] Step 11: Print physical page table after GC\n");
    print_physical_page_table();   /* victim block은 erase되어 FREE/data 0이 되어야 함 */
    print_separator();

    print_string("[Demo] Step 12: Print trace log\n");
    print_trace_log();             /* MIGRATE와 GC event가 같이 남는지 확인 */

    print_string("--- Demo end ---\n");
}

/* command.asm */
static void cmd_write(void) { submit_write_request(); }
static void cmd_read(void) { submit_read_request(); }
static void cmd_print_mapping(void) { print_mapping_table(); }
static void cmd_print_physical(void) { print_physical_page_table(); }
static void cmd_print_stats(void) { print_statistics(); }
static void cmd_print_trace(void) { print_trace_log(); }
static void cmd_full_status(void) { print_full_status(); }
static void cmd_demo(void) { run_demo_scenario(); }
static void cmd_reset(void) { reset_ssd(); }
static void cmd_gc(void) { run_gc(); }

/* main.asm */
int main(void)
{
    while (1) {
        int menu;

        print_string(
            "\n=== SSD FTL Simulator ===\n"
            " 1. Write request\n"
            " 2. Read request\n"
            " 3. Show mapping table\n"
            " 4. Show physical pages\n"
            " 5. Show statistics\n"
            " 6. Show trace log\n"
            " 7. Show full status\n"
            " 8. Run demo\n"
            " 9. Reset SSD\n"
            "10. Run GC\n"
            " 0. Exit\n"
            "Select: "
        );

        menu = read_int();

        switch (menu) {
        case 0:
            print_string("Exiting.\n");
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
            cmd_print_stats();
            break;
        case 6:
            cmd_print_trace();
            break;
        case 7:
            cmd_full_status();
            break;
        case 8:
            cmd_demo();
            break;
        case 9:
            cmd_reset();
            break;
        case 10:
            cmd_gc();
            break;
        default:
            print_string("Invalid menu option.\n");
            break;
        }
    }
}
