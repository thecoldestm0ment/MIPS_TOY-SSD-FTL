# =============================================================================
# nand_model.asm  --  물리 페이지(PBA) 상태와 데이터 관리
#
# 실제 NAND 플래시는 page 단위로 read/write, block 단위로 erase가 된다.
# 여기서는 page 상태(FREE/VALID/INVALID)와 데이터를 배열로 모델링한다.
# =============================================================================

        .text

# -----------------------------------------------------------------------------
# get_pba_state
#   역할  : pba_state[pba] 반환
#   입력  : $a0 = PBA 번호
#   출력  : $v0 = 상태 (0=FREE, 1=VALID, 2=INVALID)
# -----------------------------------------------------------------------------
get_pba_state:
        sll   $t0, $a0, 2
        la    $t1, pba_state
        add   $t1, $t1, $t0
        lw    $v0, 0($t1)
        jr    $ra

# -----------------------------------------------------------------------------
# set_pba_state
#   역할  : pba_state[pba] = state
#   입력  : $a0 = PBA 번호
#           $a1 = 새 상태값
#   출력  : 없음
# -----------------------------------------------------------------------------
set_pba_state:
        sll   $t0, $a0, 2
        la    $t1, pba_state
        add   $t1, $t1, $t0
        sw    $a1, 0($t1)
        jr    $ra

# -----------------------------------------------------------------------------
# get_pba_data
#   역할  : pba_data[pba] 반환
#   입력  : $a0 = PBA 번호
#   출력  : $v0 = 저장된 데이터
# -----------------------------------------------------------------------------
get_pba_data:
        sll   $t0, $a0, 2
        la    $t1, pba_data
        add   $t1, $t1, $t0
        lw    $v0, 0($t1)
        jr    $ra

# -----------------------------------------------------------------------------
# set_pba_data
#   역할  : pba_data[pba] = data
#   입력  : $a0 = PBA 번호
#           $a1 = 저장할 데이터
#   출력  : 없음
# -----------------------------------------------------------------------------
set_pba_data:
        sll   $t0, $a0, 2
        la    $t1, pba_data
        add   $t1, $t1, $t0
        sw    $a1, 0($t1)
        jr    $ra

# -----------------------------------------------------------------------------
# find_free_pba
#   역할  : pba_state[0..7]을 순서대로 조회하여 FREE인 첫 번째 PBA를 반환한다.
#           FREE PBA가 없으면 -1을 반환한다.
#   입력  : 없음
#   출력  : $v0 = FREE PBA 번호, 또는 -1
#
# C 대응:
#   for (int i = 0; i < PBA_COUNT; i++)
#       if (pba_state[i] == FREE) return i;
#   return -1;
# -----------------------------------------------------------------------------
find_free_pba:
        li    $t0, 0               # i = 0
        li    $t1, 8               # PBA_COUNT = 8
        la    $t2, pba_state

ffp_loop:
        bge   $t0, $t1, ffp_none

        sll   $t3, $t0, 2
        add   $t4, $t2, $t3
        lw    $t5, 0($t4)          # pba_state[i]

        beqz  $t5, ffp_found       # FREE == 0

        addiu $t0, $t0, 1
        j     ffp_loop

ffp_found:
        move  $v0, $t0
        jr    $ra

ffp_none:
        li    $v0, -1
        jr    $ra

# -----------------------------------------------------------------------------
# reset_nand_table
#   역할  : pba_state 전부 0(FREE), pba_data 전부 0 으로 초기화
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
reset_nand_table:
        li    $t0, 0
        li    $t1, 8               # PBA_COUNT
        la    $t2, pba_state
        la    $t3, pba_data

rnt_loop:
        bge   $t0, $t1, rnt_done

        sll   $t4, $t0, 2
        add   $t5, $t2, $t4
        sw    $zero, 0($t5)        # pba_state[i] = FREE

        add   $t5, $t3, $t4
        sw    $zero, 0($t5)        # pba_data[i]  = 0

        addiu $t0, $t0, 1
        j     rnt_loop

rnt_done:
        jr    $ra

# -----------------------------------------------------------------------------
# print_physical_page_table
#   역할  : PBA 0 ~ 7 의 상태와 데이터를 표 형식으로 출력한다
#   입력  : 없음
#   출력  : 없음
#   주의  : jal 호출 → $ra 스택 저장. $t* 는 jal 후 재로드한다.
# -----------------------------------------------------------------------------
print_physical_page_table:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_pba_hdr
        jal   print_string

        li    $t0, 0               # i = 0

pppt_loop:
        li    $t1, 8               # PBA_COUNT (jal 후 매번 재로드)
        bge   $t0, $t1, pppt_done

        la    $a0, msg_pba_prefix
        jal   print_string
        move  $a0, $t0
        jal   print_int

        la    $a0, msg_sep_state
        jal   print_string

        # pba_state[i]
        la    $t2, pba_state
        sll   $t3, $t0, 2
        add   $t2, $t2, $t3
        lw    $a0, 0($t2)
        jal   print_int

        la    $a0, msg_sep_data
        jal   print_string

        # pba_data[i]
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
