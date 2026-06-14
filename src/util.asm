# 공용 입출력 함수

        .text

print_string:                       # $a0가 가리키는 문자열 출력
        li    $v0, 4                # 문자열 출력 준비
        syscall
        li    $a0, OUTPUT_DELAY_MS
        li    $v0, 32
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

print_int:                          # $a0에 든 정수 출력
        li    $v0, 1                # 정수 출력 준비
        syscall
        li    $a0, OUTPUT_DELAY_MS
        li    $v0, 32
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

print_newline:                      # 줄바꿈 1번 출력
        la    $a0, msg_newline      # 줄바꿈 문자열 주소
        li    $v0, 4                # 문자열 출력 준비
        syscall
        li    $a0, OUTPUT_DELAY_MS
        li    $v0, 32
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

print_separator:                    # 구분선 출력
        la    $a0, msg_separator    # 구분선 문자열 주소
        li    $v0, 4                # 문자열 출력 준비
        syscall
        li    $a0, OUTPUT_DELAY_MS
        li    $v0, 32
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

read_int:                           # 정수 하나를 입력받아 반환
        li    $v0, 5                # 정수 입력 준비
        syscall
        jr    $ra                   # 호출한 곳으로 복귀

run_state:                          # 상태 메시지와 시간을 같이 처리
        addiu $sp, $sp, -12
        sw    $ra, 8($sp)           # 복귀 주소
        sw    $a0, 4($sp)           # 메시지 주소
        sw    $a1, 0($sp)           # duration

        la    $a0, msg_state_op     # "[상태] " 출력
        li    $v0, 4
        syscall

        lw    $a0, 4($sp)           # 원래 메시지 출력
        li    $v0, 4
        syscall

        lw    $a0, 0($sp)           # duration 출력
        li    $v0, 1
        syscall

        la    $a0, msg_ms           # 단위 출력
        li    $v0, 4
        syscall
        li    $a0, OUTPUT_DELAY_MS
        li    $v0, 32
        syscall

        lw    $t0, total_state_count
        addiu $t0, $t0, 1           # 상태 실행 수 +1
        sw    $t0, total_state_count

        lw    $t0, total_simulated_time
        lw    $t1, 0($sp)
        add   $t0, $t0, $t1         # 누적 시간에 duration 더함
        sw    $t0, total_simulated_time

        lw    $a0, 0($sp)           # duration만큼 대기
        li    $v0, 32
        syscall

        lw    $ra, 8($sp)           # 복귀 주소 복구
        addiu $sp, $sp, 12
        jr    $ra                   # 호출한 곳으로 복귀
