# PBA 상태와 data 관리

        .text

find_free_pba_excluding_block:      # victim block 밖에서 FREE PBA를 찾음
        li    $t0, BLOCK_SIZE
        mul   $t1, $a0, $t0         # start_pba = block_id * BLOCK_SIZE
        add   $t2, $t1, $t0         # end_pba = start_pba + BLOCK_SIZE
        li    $t3, 0                # pba = 0

ffpeb_loop:                         # PBA 0~7을 순회
        li    $t4, PBA_COUNT
        bge   $t3, $t4, ffpeb_none

        blt   $t3, $t1, ffpeb_check # victim 시작 전이면 검사
        blt   $t3, $t2, ffpeb_next  # victim block 내부면 건너뜀

ffpeb_check:                        # victim 밖 PBA가 FREE인지 확인
        la    $t5, pba_state
        sll   $t6, $t3, 2
        add   $t5, $t5, $t6
        lw    $t7, 0($t5)
        beqz  $t7, ffpeb_found

ffpeb_next:                         # 다음 PBA로 이동
        addiu $t3, $t3, 1
        j     ffpeb_loop

ffpeb_found:                        # FREE PBA를 찾았으면 번호 반환
        move  $v0, $t3
        jr    $ra

ffpeb_none:                         # victim 밖에 FREE PBA가 없음
        li    $v0, -1
        jr    $ra

erase_block:                        # block 안의 모든 page를 FREE/data 0으로 erase
        li    $t0, BLOCK_SIZE
        mul   $t1, $a0, $t0         # start_pba
        add   $t2, $t1, $t0         # end_pba
        move  $t3, $t1

eb_loop:                            # block 시작 PBA부터 끝 PBA 전까지 초기화
        bge   $t3, $t2, eb_done
        sll   $t4, $t3, 2

        la    $t5, pba_state
        add   $t5, $t5, $t4
        sw    $zero, 0($t5)

        la    $t5, pba_data
        add   $t5, $t5, $t4
        sw    $zero, 0($t5)

        addiu $t3, $t3, 1
        j     eb_loop

eb_done:                            # block erase 완료
        jr    $ra

recount_page_counts:                # pba_state 전체를 다시 세서 count를 재계산
        li    $t0, 0                # pba = 0
        li    $t1, 0                # free_count = 0
        li    $t2, 0                # invalid_count = 0

rpc_loop:                           # 모든 PBA 상태 확인
        li    $t3, PBA_COUNT
        bge   $t0, $t3, rpc_done

        la    $t4, pba_state
        sll   $t5, $t0, 2
        add   $t4, $t4, $t5
        lw    $t6, 0($t4)

        li    $t7, FREE
        beq   $t6, $t7, rpc_count_free
        li    $t7, INVALID
        beq   $t6, $t7, rpc_count_invalid
        j     rpc_next

rpc_count_free:                     # FREE page 수 증가
        addiu $t1, $t1, 1
        j     rpc_next

rpc_count_invalid:                  # INVALID page 수 증가
        addiu $t2, $t2, 1

rpc_next:                           # 다음 PBA로 이동
        addiu $t0, $t0, 1
        j     rpc_loop

rpc_done:                           # 재계산한 count를 전역 변수에 저장
        sw    $t1, free_page_count
        sw    $t2, invalid_page_count
        jr    $ra

get_pba_state:                      # pba_state[PBA] 값을 읽어 옴
        sll   $t0, $a0, 2           # offset = PBA * 4
        la    $t1, pba_state        # 배열 시작 주소
        add   $t1, $t1, $t0         # &pba_state[PBA]
        lw    $v0, 0($t1)           # pba_state[PBA] 반환
        jr    $ra                   # 호출한 곳으로 복귀

set_pba_state:                      # pba_state[PBA] = state
        sll   $t0, $a0, 2           # offset = PBA * 4
        la    $t1, pba_state        # 배열 시작 주소
        add   $t1, $t1, $t0         # &pba_state[PBA]
        sw    $a1, 0($t1)           # 상태값 저장
        jr    $ra                   # 호출한 곳으로 복귀

get_pba_data:                       # pba_data[PBA] 값을 읽어 옴
        sll   $t0, $a0, 2           # offset = PBA * 4
        la    $t1, pba_data         # 배열 시작 주소
        add   $t1, $t1, $t0         # &pba_data[PBA]
        lw    $v0, 0($t1)           # data 반환
        jr    $ra                   # 호출한 곳으로 복귀

set_pba_data:                       # pba_data[PBA] = data
        sll   $t0, $a0, 2           # offset = PBA * 4
        la    $t1, pba_data         # 배열 시작 주소
        add   $t1, $t1, $t0         # &pba_data[PBA]
        sw    $a1, 0($t1)           # data 저장
        jr    $ra                   # 호출한 곳으로 복귀

find_free_pba:                      # 첫 번째 FREE PBA를 찾음
        li    $t0, 0                # i = 0
        li    $t1, 8                # PBA 개수
        la    $t2, pba_state        # 상태 배열 시작 주소

ffp_loop:                           # pba_state[i] 확인
        bge   $t0, $t1, ffp_none    # 끝까지 가면 실패

        sll   $t3, $t0, 2           # offset = i * 4
        add   $t4, $t2, $t3         # &pba_state[i]
        lw    $t5, 0($t4)           # pba_state[i]

        beqz  $t5, ffp_found        # 값이 0이면 바로 반환

        addiu $t0, $t0, 1           # i++
        j     ffp_loop

ffp_found:                          # FREE PBA를 찾음
        move  $v0, $t0              # 찾은 PBA 번호
        jr    $ra                   # 호출한 곳으로 복귀

ffp_none:                           # FREE PBA가 없음
        li    $v0, -1               # 실패 값 반환
        jr    $ra                   # 호출한 곳으로 복귀

reset_nand_table:                   # 상태와 data를 전부 초기화
        li    $t0, 0                # i = 0
        li    $t1, 8                # PBA 개수
        la    $t2, pba_state        # 상태 배열 시작 주소
        la    $t3, pba_data         # data 배열 시작 주소

rnt_loop:                           # i번째 PBA 초기화
        bge   $t0, $t1, rnt_done    # 끝까지 가면 종료

        sll   $t4, $t0, 2           # offset = i * 4
        add   $t5, $t2, $t4         # &pba_state[i]
        sw    $zero, 0($t5)         # pba_state[i] = FREE

        add   $t5, $t3, $t4         # &pba_data[i]
        sw    $zero, 0($t5)         # pba_data[i] = 0

        addiu $t0, $t0, 1           # i++
        j     rnt_loop

rnt_done:                           # 초기화 끝
        jr    $ra                   # 호출한 곳으로 복귀

print_physical_page_table:          # PBA 상태와 data를 출력
        addiu $sp, $sp, -4
        sw    $ra, 0($sp)           # 복귀 주소

        la    $a0, msg_pba_hdr      # 헤더 출력
        jal   print_string

        li    $t0, 0                # i = 0

pppt_loop:                          # PBA 0~7 출력
        li    $t1, 8                # PBA 개수
        bge   $t0, $t1, pppt_done

        la    $a0, msg_pba_prefix   # "PBA "
        jal   print_string
        move  $a0, $t0              # 현재 PBA 출력
        jal   print_int

        la    $a0, msg_sep_state    # 상태 구분자
        jal   print_string

        la    $t2, pba_state        # 상태 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &pba_state[i]
        lw    $a0, 0($t2)           # 상태 출력
        jal   print_int

        la    $a0, msg_sep_data     # data 구분자
        jal   print_string

        la    $t2, pba_data         # data 배열 시작 주소
        sll   $t3, $t0, 2           # offset = i * 4
        add   $t2, $t2, $t3         # &pba_data[i]
        lw    $a0, 0($t2)           # data 출력
        jal   print_int
        jal   print_newline

        addiu $t0, $t0, 1           # i++
        j     pppt_loop

pppt_done:                          # 출력 끝
        lw    $ra, 0($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 4
        jr    $ra                   # 호출한 곳으로 복귀

