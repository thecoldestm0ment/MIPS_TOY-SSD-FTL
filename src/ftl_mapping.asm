# =============================================================================
# ftl_mapping.asm  --  LBA-PBA 매핑 테이블 관리 함수
#
# 배열 접근 공식:
#   address = base_address + index * 4
#
# MIPS에는 정수 곱셈 대신 sll(shift left logical)을 자주 쓴다.
#   sll $t0, $a0, 2   →   $t0 = $a0 * 4
# 2비트 왼쪽으로 밀면 값이 4배가 되는 원리다.
# (binary에서 1비트 왼쪽 이동 = ×2, 2비트 이동 = ×4)
# =============================================================================

        .text

# -----------------------------------------------------------------------------
# check_lba_range
#   역할  : LBA가 유효한 범위(0 이상, LBA_COUNT 미만)인지 검사한다
#   입력  : $a0 = 검사할 LBA 번호
#   출력  : $v0 = 1 (유효), 0 (범위 초과)
# -----------------------------------------------------------------------------
check_lba_range:
        li    $v0, 0
        bltz  $a0, clr_fail        # LBA < 0 이면 실패
        li    $t0, 4               # LBA_COUNT = 4
        bge   $a0, $t0, clr_fail   # LBA >= 4 이면 실패
        li    $v0, 1
clr_fail:
        jr    $ra

# -----------------------------------------------------------------------------
# get_lba_mapping
#   역할  : lba_map[lba]를 읽어 반환한다
#   입력  : $a0 = LBA 번호
#   출력  : $v0 = 매핑된 PBA (-1이면 미매핑)
#
# C 대응:
#   return lba_map[lba];
# -----------------------------------------------------------------------------
get_lba_mapping:
        sll   $t0, $a0, 2          # $t0 = lba * 4  (byte offset)
        la    $t1, lba_map         # $t1 = lba_map 배열 시작 주소
        add   $t1, $t1, $t0        # $t1 = &lba_map[lba]
        lw    $v0, 0($t1)          # $v0 = lba_map[lba]
        jr    $ra

# -----------------------------------------------------------------------------
# set_lba_mapping
#   역할  : lba_map[lba] = pba 로 매핑을 갱신한다
#   입력  : $a0 = LBA 번호
#           $a1 = 새 PBA 번호
#   출력  : 없음
#
# C 대응:
#   lba_map[lba] = pba;
# -----------------------------------------------------------------------------
set_lba_mapping:
        sll   $t0, $a0, 2          # offset = lba * 4
        la    $t1, lba_map
        add   $t1, $t1, $t0        # &lba_map[lba]
        sw    $a1, 0($t1)          # lba_map[lba] = pba
        jr    $ra

# -----------------------------------------------------------------------------
# reset_mapping_table
#   역할  : lba_map 전체를 -1로 초기화한다
#   입력  : 없음
#   출력  : 없음
# -----------------------------------------------------------------------------
reset_mapping_table:
        li    $t0, 0
        li    $t1, 4               # LBA_COUNT
        la    $t2, lba_map

rmt_loop:
        bge   $t0, $t1, rmt_done
        sll   $t3, $t0, 2
        add   $t4, $t2, $t3
        li    $t5, -1
        sw    $t5, 0($t4)          # lba_map[i] = -1
        addiu $t0, $t0, 1
        j     rmt_loop

rmt_done:
        jr    $ra

# -----------------------------------------------------------------------------
# print_mapping_table
#   역할  : LBA 0 ~ 3 의 현재 매핑 상태를 출력한다
#   입력  : 없음
#   출력  : 없음
#   주의  : jal 호출 → $ra 스택 저장 필요
# -----------------------------------------------------------------------------
print_mapping_table:
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)

        la    $a0, msg_map_hdr
        jal   print_string

        li    $t0, 0               # i = 0
        li    $t1, 4               # LBA_COUNT = 4
        la    $t2, lba_map

pmt_loop:
        bge   $t0, $t1, pmt_done

        la    $a0, msg_lba_prefix
        jal   print_string
        move  $a0, $t0
        jal   print_int
        la    $a0, msg_arrow_pba
        jal   print_string

        # lba_map[i] 읽기
        # $t0, $t1, $t2 는 $t* 이므로 jal 이후 다시 로드해야 한다
        sll   $t3, $t0, 2
        add   $t4, $t2, $t3
        lw    $a0, 0($t4)
        jal   print_int
        jal   print_newline

        # jal 후 $t* 재로드
        li    $t1, 4
        la    $t2, lba_map
        addiu $t0, $t0, 1
        j     pmt_loop

pmt_done:
        lw    $ra, 0($sp)
        addiu $sp, $sp, 4
        jr    $ra
