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
