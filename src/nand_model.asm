# PBA 상태와 data 관리

        .text

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
