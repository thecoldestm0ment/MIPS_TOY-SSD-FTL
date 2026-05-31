# LBA-PBA 매핑

        .text

check_lba_range:                    # LBA가 0~3 범위인지 확인
        li    $v0, 0                # 기본값은 실패
        bltz  $a0, clr_fail         # LBA가 0보다 작으면 실패
        li    $t0, 4                # LBA 개수
        bge   $a0, $t0, clr_fail    # LBA가 4 이상이면 실패
        li    $v0, 1                # 범위 안이면 성공

clr_fail:                           # 검사 끝
        jr    $ra                   # 호출한 곳으로 복귀

get_lba_mapping:                    # lba_map[LBA] 값을 읽어 옴
        sll   $t0, $a0, 2           # offset = LBA * 4
        la    $t1, lba_map          # 배열 시작 주소
        add   $t1, $t1, $t0         # &lba_map[LBA]
        lw    $v0, 0($t1)           # lba_map[LBA] 반환
        jr    $ra                   # 호출한 곳으로 복귀

set_lba_mapping:                    # lba_map[LBA] = PBA
        sll   $t0, $a0, 2           # offset = LBA * 4
        la    $t1, lba_map          # 배열 시작 주소
        add   $t1, $t1, $t0         # &lba_map[LBA]
        sw    $a1, 0($t1)           # lba_map[LBA] = PBA
        jr    $ra                   # 호출한 곳으로 복귀

reset_mapping_table:                # 매핑 테이블을 전부 -1로 초기화
        li    $t0, 0                # i = 0
        li    $t1, 4                # 반복할 LBA 수
        la    $t2, lba_map          # 배열 시작 주소

rmt_loop:                           # lba_map[i] 초기화
        bge   $t0, $t1, rmt_done    # 끝까지 가면 종료
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t4, $t2, $t3         # &lba_map[i]
        li    $t5, -1               # 비어 있는 매핑 값
        sw    $t5, 0($t4)           # lba_map[i] = -1
        addiu $t0, $t0, 1           # i++
        j     rmt_loop

rmt_done:                           # 초기화 끝
        jr    $ra                   # 호출한 곳으로 복귀

print_mapping_table:                # LBA별 현재 매핑을 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # $ra 저장

        la    $a0, msg_map_hdr      # 헤더 출력
        jal   print_string

        li    $t0, 0                # i = 0
        li    $t1, 4                # LBA 개수
        la    $t2, lba_map          # 테이블 시작 주소

pmt_loop:                           # LBA 0~3 출력
        bge   $t0, $t1, pmt_done

        la    $a0, msg_lba_prefix   # "LBA "
        jal   print_string
        move  $a0, $t0              # 현재 LBA 출력
        jal   print_int
        la    $a0, msg_arrow_pba    # " -> PBA "
        jal   print_string

        sll   $t3, $t0, 2           # offset = i * 4
        add   $t4, $t2, $t3         # &lba_map[i]
        lw    $a0, 0($t4)           # 매핑된 PBA 출력
        jal   print_int
        jal   print_newline

        li    $t1, 4                # jal 뒤에 반복 끝 값 다시 준비
        la    $t2, lba_map          # jal 뒤에 테이블 주소 다시 준비
        addiu $t0, $t0, 1           # i++
        j     pmt_loop

pmt_done:                           # 출력 끝
        lw    $ra, 0($sp)           # $ra 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀
