#include <stdio.h>
#include <stdlib.h>

#define LBA_COUNT 4
#define PBA_COUNT 8

#define FREE 0
#define VALID 1
#define INVALID 2

#define TRACE_MAX 20

#define TTYPE_WRITE 1
#define TTYPE_READ  2
#define TTYPE_GC    3
#define TTYPE_RESET 4

/* toy_ftl.asm의 전역 데이터 */
static int lba_map[LBA_COUNT] = { -1, -1, -1, -1 };
static int pba_state[PBA_COUNT] = { 0, 0, 0, 0, 0, 0, 0, 0 };
static int pba_data[PBA_COUNT] = { 0, 0, 0, 0, 0, 0, 0, 0 };

static int trace_type[TRACE_MAX];
static int trace_lba[TRACE_MAX];
static int trace_pba[TRACE_MAX];
static int trace_data[TRACE_MAX];
static int trace_count = 0;

static int total_write_count = 0;
static int total_read_count = 0;
static int total_state_count = 0;
static int total_simulated_time = 0;
static int free_page_count = 8;
static int invalid_page_count = 0;
static int gc_count = 0;

/* util.asm */
static void print_string(const char *s)                { printf("%s", s); }
static void print_int(int value)                       { printf("%d", value); }
static void print_newline(void)                        { printf("\n"); }
static void print_separator(void)                      { printf("-----------------------------\n"); }

static int read_int(void)                              /* 정수 하나 입력 */
{
    char buf[128];

    if (!fgets(buf, sizeof(buf), stdin)) {
        return 0;
    }

    return (int)strtol(buf, NULL, 10);
}

static void run_state(const char *message, int ms)     /* 상태 메시지와 시간 처리 */
{
    printf("[State] %s%d ms\n", message, ms);
    total_state_count++;
    total_simulated_time += ms;
}

/* ftl_mapping.asm */
static int check_lba_range(int lba)                    /* LBA가 0~3인지 확인 */
{
    return lba >= 0 && lba < LBA_COUNT;
}

static int get_lba_mapping(int lba)                    /* lba_map[LBA] 반환 */
{
    return lba_map[lba];
}

static void set_lba_mapping(int lba, int pba)          /* lba_map[LBA] = PBA */
{
    lba_map[lba] = pba;
}

static void reset_mapping_table(void)                  /* 매핑을 전부 -1로 초기화 */
{
    int i;

    for (i = 0; i < LBA_COUNT; i++) {
        lba_map[i] = -1;
    }
}

static void print_mapping_table(void)                  /* LBA별 매핑 출력 */
{
    int i;

    print_string("[Mapping Table]\n");
    for (i = 0; i < LBA_COUNT; i++) {
        printf("LBA %d -> PBA %d\n", i, lba_map[i]);
    }
}

/* nand_model.asm */
static int get_pba_state(int pba)                      /* pba_state[PBA] 반환 */
{
    return pba_state[pba];
}

static void set_pba_state(int pba, int state)          /* pba_state[PBA] = state */
{
    pba_state[pba] = state;
}

static int get_pba_data(int pba)                       /* pba_data[PBA] 반환 */
{
    return pba_data[pba];
}

static void set_pba_data(int pba, int data)            /* pba_data[PBA] = data */
{
    pba_data[pba] = data;
}

static int find_free_pba(void)                         /* 첫 번째 FREE PBA 찾기 */
{
    int i;

    for (i = 0; i < PBA_COUNT; i++) {
        if (pba_state[i] == FREE) {
            return i;
        }
    }

    return -1;
}

static void reset_nand_table(void)                     /* 상태와 data 초기화 */
{
    int i;

    for (i = 0; i < PBA_COUNT; i++) {
        pba_state[i] = FREE;
        pba_data[i] = 0;
    }
}

static void print_physical_page_table(void)            /* PBA 상태와 data 출력 */
{
    int i;

    print_string("[Physical Page Table]\n");
    print_string("State: 0=FREE, 1=VALID, 2=INVALID\n");

    for (i = 0; i < PBA_COUNT; i++) {
        printf("PBA %d | State: %d | data %d\n", i, pba_state[i], pba_data[i]);
    }
}

/* trace.asm */
static int trace_check_full(void)                      /* Trace가 가득 찼는지 확인 */
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
        printf("%d | ", i);

        if (trace_type[i] == TTYPE_WRITE) {
            printf("WRITE | LBA %d | PBA %d | DATA %d\n",
                   trace_lba[i], trace_pba[i], trace_data[i]);
        } else if (trace_type[i] == TTYPE_READ) {
            printf("READ  | LBA %d | PBA %d | DATA %d\n",
                   trace_lba[i], trace_pba[i], trace_data[i]);
        } else if (trace_type[i] == TTYPE_GC) {
            printf("GC    | Freed pages: %d\n", trace_data[i]);
        } else if (trace_type[i] == TTYPE_RESET) {
            printf("RESET\n");
        }
    }
}

static void reset_trace_log(void)                      /* Trace 개수만 0으로 초기화 */
{
    trace_count = 0;
}

/* gc.asm */
static void run_simple_gc(void)                        /* INVALID page를 FREE로 변경 */
{
    int i;
    int freed = 0;

    print_string("[GC] Scanning INVALID pages...\n");

    for (i = 0; i < PBA_COUNT; i++) {
        if (pba_state[i] != INVALID) {
            continue;
        }

        pba_state[i] = FREE;
        printf("[GC] PBA %d -> FREE\n", i);
        freed++;
    }

    free_page_count += freed;
    invalid_page_count -= freed;
    gc_count++;

    printf("[GC] Freed page count: %d\n", freed);
    print_string("[GC] Done\n");

    log_gc_event(freed);
}

/* status.asm */
static int count_valid_pages(void)                     /* VALID page 개수 계산 */
{
    int i;
    int count = 0;

    for (i = 0; i < PBA_COUNT; i++) {
        if (pba_state[i] == VALID) {
            count++;
        }
    }

    return count;
}

static void print_page_state_summary(void)
{
    print_string("[Page State Summary]\n");
    printf("  FREE    : %d\n", free_page_count);
    printf("  VALID   : %d\n", count_valid_pages());
    printf("  INVALID : %d\n", invalid_page_count);
}

static void print_statistics(void)
{
    print_string("[Statistics]\n");
    printf("Total WRITE count : %d\n", total_write_count);
    printf("Total READ count  : %d\n", total_read_count);
    printf("State run count   : %d\n", total_state_count);
    printf("Total time (ms)   : %d\n", total_simulated_time);
    printf("FREE page count   : %d\n", free_page_count);
    printf("VALID page count  : %d\n", count_valid_pages());
    printf("INVALID page count: %d\n", invalid_page_count);
    printf("GC run count      : %d\n", gc_count);
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

    printf("Selected LBA: %d\n", lba);

    old_pba = get_lba_mapping(lba);

    if (old_pba != -1) {
        printf("Old PBA: %d\n", old_pba);
        printf("PBA %d -> INVALID\n", old_pba);
        set_pba_state(old_pba, INVALID);

        /*
         * 아래 카운트 갱신은 현재 ASM 로직을 그대로 따른다.
         * 덮어쓰기 시 FREE count를 한 번 더 줄이는 점도 그대로 유지한다.
         */
        free_page_count--;
        invalid_page_count++;
    } else {
        print_string("This LBA has no previous mapping.\n");
    }

    new_pba = find_free_pba();
    if (new_pba == -1) {
        print_string("No free page. Run GC first.\n");
        return;
    }

    set_pba_state(new_pba, VALID);
    set_pba_data(new_pba, data);
    set_lba_mapping(lba, new_pba);

    total_write_count++;
    free_page_count--;

    printf("Assigned new PBA: %d\n", new_pba);
    printf("LBA %d -> PBA %d, data = %d\n", lba, new_pba, data);

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

    printf("Reading LBA: %d\n", lba);

    pba = get_lba_mapping(lba);
    if (pba == -1) {
        print_string("No data for this LBA.\n");
        return;
    }

    printf("Mapped PBA: %d\n", pba);

    data = get_pba_data(pba);
    printf("data: %d\n", data);

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
    invalid_page_count = 0;
    gc_count = 0;
    free_page_count = 8;
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
    ftl_write_core(2, 100);
    print_separator();

    print_string("[Demo] Step 2: Write 50 to LBA 1\n");
    ftl_write_core(1, 50);
    print_separator();

    print_string("[Demo] Step 3: Read LBA 2\n");
    ftl_read_core(2);
    print_separator();

    print_string("[Demo] Step 4: Write 200 to LBA 2 again\n");
    ftl_write_core(2, 200);
    print_separator();

    print_string("[Demo] Step 5: Read LBA 2 again (expect 200)\n");
    ftl_read_core(2);
    print_separator();

    print_string("[Demo] Step 6: Print mapping table\n");
    print_mapping_table();
    print_separator();

    print_string("[Demo] Step 7: Print physical page table\n");
    print_physical_page_table();
    print_separator();

    print_string("[Demo] Step 8: Run GC\n");
    run_simple_gc();
    print_separator();

    print_string("[Demo] Step 9: Print physical page table after GC\n");
    print_physical_page_table();
    print_separator();

    print_string("[Demo] Step 10: Print trace log\n");
    print_trace_log();

    print_string("--- Demo end ---\n");
}

/* command.asm */
static void cmd_write(void)         { submit_write_request(); }
static void cmd_read(void)          { submit_read_request(); }
static void cmd_print_mapping(void) { print_mapping_table(); }
static void cmd_print_physical(void){ print_physical_page_table(); }
static void cmd_print_stats(void)   { print_statistics(); }
static void cmd_print_trace(void)   { print_trace_log(); }
static void cmd_full_status(void)   { print_full_status(); }
static void cmd_demo(void)          { run_demo_scenario(); }
static void cmd_reset(void)         { reset_ssd(); }
static void cmd_gc(void)            { run_simple_gc(); }

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
