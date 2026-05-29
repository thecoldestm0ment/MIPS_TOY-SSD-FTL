# =============================================================================
# block_model.asm  --  Block 단위 erase count 관리
#
# 실제 SSD에서는 block 단위 erase와 valid page migration이 필요하다.
# 이 프로젝트에서는 MIPS 구현 난이도를 고려하여, INVALID page를 FREE로
# 되돌리고 해당 block의 erase count만 증가시키는 simplified model로 표현했다.
#
# 블록 구조:
#   Block 0 : PBA 0 ~ 3  (PBA / 4 == 0)
#   Block 1 : PBA 4 ~ 7  (PBA / 4 == 1)
#
# block_erase_count[b] : 블록 b가 GC로 회수된 횟수
# =============================================================================

        .text

# -----------------------------------------------------------------------------
# get_block_id_by_pba
#   역할  : PBA 번호로부터 소속 Block ID를 계산한다
#   입력  : $a0 = PBA 번호
#   출력  : $v0 = Block ID (0 또는 1)
#
# 계산: block_id = pba / 4
#   MIPS에서 4로 나누기 = 2비트 오른쪽 shift (srl)
#   srl $v0, $a0, 2  →  $v0 = $a0 / 4
# -----------------------------------------------------------------------------
get_block_id_by_pba:
        srl   $v0, $a0, 2          # block_id = pba >> 2 = pba / 4
        jr    $ra

# -----------------------------------------------------------------------------
# increase_block_erase_count
#   역할  : block_erase_count[block_id] 를 1 증가시킨다
#   입력  : $a0 = Block ID
#   출력  : 없음
# -----------------------------------------------------------------------------
increase_block_erase_count:
        sll   $t0, $a0, 2
        la    $t1, block_erase_count
        add   $t1, $t1, $t0
        lw    $t2, 0($t1)
        addiu $t2, $t2, 1
        sw    $t2, 0($t1)
        jr    $ra

# -----------------------------------------------------------------------------
# print_block_table
#   역할  : Block 0, Block 1 의 PBA 범위와 erase count를 출력한다
#   입력  : 없음
#   출력  : 없음
#   주의  : jal 호출 → $ra 스택 저장
# -----------------------------------------------------------------------------
print_block_table:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_blk_hdr
        jal   print_string

        li    $t0, 0               # block id = 0
        li    $t1, 2               # BLOCK_COUNT = 2

pbt_loop:
        bge   $t0, $t1, pbt_done

        # "Block N (PBA X ~ Y) | erase count: Z"
        la    $a0, msg_blk_line
        jal   print_string
        move  $a0, $t0
        jal   print_int

        la    $a0, msg_blk_pba
        jal   print_string

        # PBA 시작 = block_id * 4
        sll   $t2, $t0, 2          # first_pba = block_id * 4
        move  $a0, $t2
        jal   print_int

        la    $a0, msg_blk_to
        jal   print_string

        addiu $t2, $t2, 3          # last_pba = first_pba + 3
        move  $a0, $t2
        jal   print_int

        la    $a0, msg_blk_erase
        jal   print_string

        # block_erase_count[block_id]
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

# -----------------------------------------------------------------------------
# reset_block_table
#   역할  : block_erase_count 전부 0으로 초기화
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
reset_block_table:
        la    $t0, block_erase_count
        sw    $zero, 0($t0)        # block 0
        sw    $zero, 4($t0)        # block 1
        jr    $ra
