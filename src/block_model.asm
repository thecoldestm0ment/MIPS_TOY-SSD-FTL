# 블록 정보와 erase 횟수

        .text

get_block_id_by_pba:                # PBA가 속한 block 번호 계산
        srl   $v0, $a0, 2           # PBA / 4
        jr    $ra                   # 호출한 곳으로 복귀

increase_block_erase_count:         # block erase 횟수 1 증가
        sll   $t0, $a0, 2           # offset = block_id * 4
        la    $t1, block_erase_count# 배열 시작 주소
        add   $t1, $t1, $t0         # &block_erase_count[block_id]
        lw    $t2, 0($t1)           # 현재 erase 횟수
        addiu $t2, $t2, 1           # erase 횟수 +1
        sw    $t2, 0($t1)           # 다시 저장
        jr    $ra                   # 호출한 곳으로 복귀

print_block_table:                  # block별 erase 횟수 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_blk_hdr      # 헤더 출력
        jal   print_string

        li    $t0, 0                # block_id = 0
        li    $t1, 2                # block 개수

pbt_loop:                           # block 0~1 출력
        bge   $t0, $t1, pbt_done

        la    $a0, msg_blk_line     # "블록 "
        jal   print_string
        move  $a0, $t0              # block_id 출력
        jal   print_int

        la    $a0, msg_blk_pba      # "(PBA "
        jal   print_string

        sll   $t2, $t0, 2           # 시작 PBA = block_id * 4
        move  $a0, $t2
        jal   print_int

        la    $a0, msg_blk_to       # " ~ "
        jal   print_string

        addiu $t2, $t2, 3           # 끝 PBA = 시작 PBA + 3
        move  $a0, $t2
        jal   print_int

        la    $a0, msg_blk_erase    # erase 횟수 안내
        jal   print_string

        la    $t3, block_erase_count# erase 배열 시작 주소
        sll   $t4, $t0, 2           # offset = block_id * 4
        add   $t3, $t3, $t4         # &block_erase_count[block_id]
        lw    $a0, 0($t3)           # erase 횟수 출력
        jal   print_int
        jal   print_newline

        addiu $t0, $t0, 1           # block_id++
        j     pbt_loop

pbt_done:                           # 출력 끝
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

reset_block_table:                  # block erase 횟수 초기화
        la    $t0, block_erase_count# 배열 시작 주소
        sw    $zero, 0($t0)         # block 0 = 0
        sw    $zero, 4($t0)         # block 1 = 0
        jr    $ra                   # 호출한 곳으로 복귀
