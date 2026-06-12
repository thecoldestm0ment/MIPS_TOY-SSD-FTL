# SSD FTL Simulator 면담 대비 정리

## 1. 프로젝트 한 줄 설명

이 프로젝트는 작은 SSD의 FTL(Flash Translation Layer)을 MIPS 어셈블리로 구현한 시뮬레이터입니다.
논리 주소인 LBA 0~3을 물리 페이지인 PBA 0~7에 매핑하고, 쓰기/읽기/GC/Reset/상태 출력/Trace 기록을 메뉴 방식으로 실행합니다.

## 2. 소스 구성

- `src/data.asm`: 전역 상수, 배열, 문자열 메시지 정의
- `src/main.asm`: 메뉴 루프와 사용자 입력 분기
- `src/command.asm`: 메뉴 번호를 실제 기능 함수로 연결하는 wrapper
- `src/ftl_write.asm`: 쓰기 요청 처리와 LBA -> PBA 매핑 갱신
- `src/ftl_read.asm`: 읽기 요청 처리와 매핑된 데이터 출력
- `src/ftl_mapping.asm`: LBA 매핑 테이블 조회/수정/초기화/출력
- `src/nand_model.asm`: PBA 상태/데이터 배열 조회/수정, free page 검색
- `src/gc.asm`: INVALID page를 FREE로 바꾸는 단순 GC
- `src/trace.asm`: WRITE/READ/GC/RESET 이벤트 기록과 출력
- `src/status.asm`: 통계, 페이지 상태, 전체 상태 출력
- `src/reset.asm`: SSD 상태 전체 초기화
- `src/demo.asm`: 정해진 시나리오로 기능 검증
- `src/util.asm`: 문자열/정수 출력, 입력, 구분선, state 처리
- `toy_ftl.asm`: 위 `src` 파일들을 하나로 합친 실행용 asm 파일
- `toy_ftl_readable.c`: asm 로직을 이해하기 쉽게 C 형태로 옮긴 참고용 파일

## 3. 핵심 자료구조

### LBA/PBA 개념

- LBA(Logical Block Address): 사용자가 요청하는 논리 주소입니다. 이 프로젝트에서는 0~3만 사용합니다.
- PBA(Physical Block Address 또는 Physical Page Address): 실제 NAND에 해당하는 물리 페이지입니다. 이 프로젝트에서는 0~7을 사용합니다.
- FTL의 핵심 역할은 `lba_map[LBA] = PBA` 형태로 논리 주소와 물리 페이지를 연결하는 것입니다.

### 주요 배열

- `lba_map[4]`: 각 LBA가 현재 어느 PBA를 가리키는지 저장합니다. 초기값은 `-1`이며, 아직 데이터가 없다는 뜻입니다.
- `pba_state[8]`: 각 PBA의 상태를 저장합니다.
  - `FREE = 0`: 비어 있는 페이지
  - `VALID = 1`: 현재 유효한 데이터가 있는 페이지
  - `INVALID = 2`: 덮어쓰기 때문에 더 이상 최신 데이터가 아닌 페이지
- `pba_data[8]`: 각 PBA에 저장된 데이터 값입니다.
- `trace_type`, `trace_lba`, `trace_pba`, `trace_data`: 최대 20개의 이벤트 로그를 저장합니다.

## 4. 주요 로직 설명

### 쓰기 로직

핵심 함수는 `ftl_write_core`입니다.

1. 사용자가 입력한 LBA가 기존에 어떤 PBA에 매핑되어 있는지 `get_lba_mapping`으로 확인합니다.
2. 기존 PBA가 있으면 그 PBA는 최신 데이터가 아니므로 `INVALID` 상태로 바꿉니다.
3. `find_free_pba`로 첫 번째 FREE PBA를 찾습니다.
4. FREE PBA가 없으면 "No free page. Run GC first."를 출력하고 종료합니다.
5. 새 PBA를 `VALID`로 만들고, `pba_data[new_pba]`에 데이터를 저장합니다.
6. `lba_map[lba] = new_pba`로 매핑 테이블을 갱신합니다.
7. write 통계와 trace log를 갱신합니다.

중요한 점은 NAND flash는 기존 페이지를 바로 덮어쓰는 모델이 아니라, 새 물리 페이지에 쓰고 기존 페이지를 INVALID 처리하는 방식으로 구현했다는 점입니다.

### 읽기 로직

핵심 함수는 `ftl_read_core`입니다.

1. 입력 LBA로 `lba_map`을 조회합니다.
2. 매핑값이 `-1`이면 아직 저장된 데이터가 없으므로 "No data for this LBA."를 출력합니다.
3. 매핑된 PBA가 있으면 `pba_data[pba]`에서 값을 읽어 출력합니다.
4. read 통계와 trace log를 갱신합니다.

### GC 로직

핵심 함수는 `run_gc`입니다.

1. PBA 0~7을 순회합니다.
2. 상태가 `INVALID`인 PBA를 찾습니다.
3. 해당 PBA의 상태를 `FREE`로 되돌립니다.
4. 해제한 페이지 수를 세고, free/invalid count와 gc count를 갱신합니다.
5. GC 이벤트를 trace log에 남깁니다.

이 GC는 실제 SSD처럼 valid page copy, block erase 단위 처리, wear leveling까지 구현한 것은 아닙니다.
과제 범위에 맞춰 INVALID page를 다시 FREE로 바꾸는 단순화된 GC입니다.

### Reset 로직

핵심 함수는 `reset_ssd`입니다.

1. `pba_state`를 모두 FREE로 초기화합니다.
2. `pba_data`를 모두 0으로 초기화합니다.
3. `lba_map`을 모두 `-1`로 초기화합니다.
4. 통계와 trace count를 초기화합니다.
5. RESET 이벤트를 trace log에 기록합니다.

### Trace 로직

WRITE, READ, GC, RESET 이벤트를 배열 4개에 나누어 저장합니다.

- `trace_type`: 이벤트 종류
- `trace_lba`: 관련 LBA
- `trace_pba`: 관련 PBA
- `trace_data`: 데이터 값 또는 GC에서 해제된 페이지 수

GC/RESET처럼 LBA/PBA가 직접 없는 이벤트는 LBA와 PBA에 `-1`을 넣습니다.

## 5. 예상 질문과 답변

### Q1. 이 프로그램은 무엇을 구현한 것인가요?

A. SSD 내부의 FTL을 단순화해서 구현했습니다. 사용자는 LBA에 읽기/쓰기를 요청하고, 내부에서는 LBA를 PBA로 매핑합니다. 쓰기, 읽기, GC, Reset, 통계 출력, Trace log 기능을 포함합니다.

### Q2. 왜 LBA는 4개이고 PBA는 8개인가요?

A. 작은 toy simulator라서 동작을 눈으로 확인하기 쉽게 LBA는 4개, PBA는 8개로 제한했습니다. PBA를 LBA보다 많이 둔 이유는 같은 LBA에 다시 쓰기할 때 기존 페이지를 INVALID로 남기고 새 PBA에 쓰는 FTL 동작을 보여주기 위해서입니다.

### Q3. `lba_map`은 어떤 역할인가요?

A. 논리 주소가 현재 어느 물리 페이지를 가리키는지 저장하는 매핑 테이블입니다. 예를 들어 `lba_map[2] = 5`이면 LBA 2의 최신 데이터가 PBA 5에 있다는 의미입니다.

### Q4. 쓰기할 때 기존 PBA를 바로 지우지 않고 INVALID로 바꾸는 이유는 무엇인가요?

A. NAND flash는 일반 메모리처럼 기존 위치를 즉시 덮어쓰기 어렵습니다. 그래서 새 페이지에 데이터를 쓰고, 이전 페이지는 더 이상 최신 데이터가 아니므로 INVALID로 표시합니다. 나중에 GC가 INVALID page를 회수합니다.

### Q5. `find_free_pba`는 어떻게 동작하나요?

A. `pba_state` 배열을 PBA 0부터 7까지 순서대로 검사해서 상태가 FREE인 첫 번째 PBA 번호를 반환합니다. 없으면 `-1`을 반환합니다.

### Q6. READ는 어떻게 최신 데이터를 찾나요?

A. READ는 전체 PBA를 검색하지 않고 `lba_map[lba]`를 바로 조회합니다. 이 값은 항상 최신 PBA로 갱신되므로, 그 PBA의 `pba_data`를 읽으면 최신 데이터를 얻을 수 있습니다.

### Q7. 같은 LBA에 두 번 쓰면 무슨 일이 발생하나요?

A. 첫 번째 쓰기에서는 빈 PBA에 데이터가 저장되고 `lba_map`이 갱신됩니다. 두 번째 쓰기에서는 기존 PBA가 INVALID가 되고, 새로운 FREE PBA에 새 데이터가 저장됩니다. 이후 `lba_map`은 새 PBA를 가리킵니다.

예시:

```text
Write LBA 2 = 100 -> LBA 2 maps to PBA 0
Write LBA 2 = 200 -> PBA 0 becomes INVALID, LBA 2 maps to PBA 1
Read LBA 2 -> reads data 200 from PBA 1
```

### Q8. GC는 정확히 무엇을 하나요?

A. 현재 구현의 GC는 `pba_state`에서 INVALID 상태인 페이지를 찾아 FREE로 바꿉니다. 그리고 해제된 페이지 수를 통계와 trace에 기록합니다.

### Q9. 실제 SSD의 GC와 다른 점은 무엇인가요?

A. 실제 SSD는 block 단위 erase, valid page migration, wear leveling, erase count 관리 등이 필요합니다. 이 프로젝트는 과제용 toy model이라서 page 단위 상태만 관리하고 INVALID page를 FREE로 직접 바꾸는 방식으로 단순화했습니다.

### Q10. Trace log는 왜 만들었나요?

A. 사용자가 어떤 작업을 했는지 순서대로 확인하기 위해서입니다. WRITE/READ/GC/RESET 이벤트를 기록하므로, 프로그램 동작을 검증하거나 데모 시나리오 결과를 설명할 때 도움이 됩니다.

### Q11. `TRACE_MAX`가 20인데 로그가 꽉 차면 어떻게 되나요?

A. `trace_check_full`에서 `trace_count >= TRACE_MAX`인지 확인합니다. 꽉 찬 경우 새 이벤트를 추가하지 않고 반환합니다. 즉, 오래된 로그를 덮어쓰는 ring buffer 방식은 아닙니다.

### Q12. 메뉴 구조는 어떻게 연결되어 있나요?

A. `main.asm`에서 메뉴 번호를 입력받고, 번호에 따라 `cmd_write`, `cmd_read`, `cmd_gc` 같은 command 함수를 호출합니다. `command.asm`은 메뉴와 실제 기능 함수 사이의 얇은 연결 역할을 합니다.

### Q13. 왜 `command.asm`을 따로 두었나요?

A. `main.asm`이 너무 많은 기능 세부사항을 직접 알지 않게 하려고 분리했습니다. 메뉴 분기, 기능 호출, 실제 FTL 로직을 나누면 구조가 더 읽기 쉽습니다.

### Q14. `toy_ftl.asm`과 `src` 폴더의 차이는 무엇인가요?

A. `src` 폴더는 기능별로 나눈 원본 소스이고, `toy_ftl.asm`은 실행 또는 제출 편의를 위해 하나로 합친 통합본입니다. 로직은 같은 흐름입니다.

### Q15. `toy_ftl_readable.c`는 왜 있나요?

A. 어셈블리 코드를 사람이 읽기 쉽게 같은 로직을 C 스타일로 풀어쓴 참고 파일입니다. 실제 과제 구현은 asm 기준이고, C 파일은 면담이나 디버깅 때 구조를 설명하기 위한 보조 자료입니다.

### Q16. 직접 코드를 짰는지 확인하려고 `ftl_write_core`를 물어보면 어떻게 설명하면 되나요?

A. `ftl_write_core`는 먼저 기존 매핑을 확인하고, 기존 PBA가 있으면 INVALID로 바꾼 뒤, `find_free_pba`로 새 PBA를 찾습니다. 새 PBA에 데이터를 쓰고 상태를 VALID로 변경한 다음 `lba_map`을 새 PBA로 갱신합니다. 마지막으로 write count와 trace를 갱신합니다.

### Q17. 직접 코드를 짰는지 확인하려고 `ftl_read_core`를 물어보면 어떻게 설명하면 되나요?

A. `ftl_read_core`는 LBA를 받아 `get_lba_mapping`으로 PBA를 찾습니다. PBA가 `-1`이면 데이터가 없다고 출력하고, 아니면 `get_pba_data`로 데이터를 읽어서 출력합니다. 이후 read count와 trace log를 갱신합니다.

### Q18. 직접 코드를 짰는지 확인하려고 `run_gc`를 물어보면 어떻게 설명하면 되나요?

A. `run_gc`는 INVALID가 가장 많은 victim block을 고르고, 그 안의 VALID page를 victim block 밖 FREE PBA로 옮긴 뒤 block 전체를 erase합니다. 마지막에는 page count를 다시 계산하고 GC/erase count와 trace를 갱신합니다.

### Q19. 어셈블리에서 배열 인덱싱은 어떻게 했나요?

A. `.word` 배열이므로 원소 하나가 4바이트입니다. 그래서 인덱스에 `sll index, index, 2`를 적용해 `index * 4` offset을 만들고, 배열 시작 주소에 더해서 해당 원소 주소를 계산했습니다. 그 다음 `lw`로 읽고 `sw`로 저장합니다.

### Q20. 함수 호출 시 레지스터 보존은 어떻게 했나요?

A. 다른 함수를 `jal`로 호출하는 함수에서는 `$ra`를 stack에 저장했다가 복구했습니다. 필요한 경우 `$s0`, `$s1` 같은 saved register도 stack에 저장하고 함수 종료 전에 복구했습니다.

### Q21. FREE page count 처리가 조금 이상해 보일 수 있는데 어떻게 답하나요?

A. 현재 C readable 파일에도 주석으로 표시했듯이, `ftl_write_core`는 asm 로직을 그대로 따라갑니다. 기존 PBA를 INVALID로 만들 때 `invalid_page_count`를 증가시키고, 새 PBA에 쓸 때 `free_page_count`를 감소시킵니다. 다만 엄밀한 page count 관점에서는 기존 VALID가 INVALID로 바뀌는 것은 FREE가 줄어드는 사건은 아니므로, 이 부분은 과제 구현의 단순 카운터 로직이며 개선하려면 old PBA invalid 처리 시 free count 감소는 제거하는 것이 맞습니다.

### Q22. 프로그램의 한계는 무엇인가요?

A. block 단위 erase, wear leveling, bad block 관리, valid page migration, 실제 NAND timing은 구현하지 않았습니다. 목적은 FTL의 기본 매핑, out-of-place write, invalidation, simple GC 흐름을 보여주는 것입니다.

### Q23. 데모 시나리오에서 무엇을 확인할 수 있나요?

A. LBA 2에 100을 쓰고, LBA 1에 50을 쓰고, LBA 2를 읽은 뒤, 다시 LBA 2에 200을 씁니다. 이후 LBA 2를 읽으면 200이 나와야 합니다. 이 과정을 통해 overwrite 시 기존 PBA가 INVALID가 되고, 매핑 테이블이 새 PBA로 바뀌는 것을 확인할 수 있습니다.

### Q24. 교수님이 "이 코드에서 제일 중요한 부분이 어디냐"고 물으면?

A. `ftl_write_core`가 제일 중요합니다. FTL의 핵심인 out-of-place write, 기존 PBA invalidation, free PBA 할당, LBA-PBA mapping 갱신이 모두 이 함수에 들어 있기 때문입니다.

### Q25. 교수님이 "왜 이 구조로 나눴냐"고 물으면?

A. 기능별로 분리해서 설명과 디버깅을 쉽게 하기 위해서입니다. mapping, NAND model, write, read, GC, trace, status, reset을 따로 나눠두면 각 파일의 책임이 명확해지고, 면담에서도 특정 기능만 따로 설명할 수 있습니다.

## 6. 면담 때 바로 말하기 좋은 요약

이 코드는 SSD FTL의 기본 원리를 보여주는 MIPS 어셈블리 시뮬레이터입니다.
사용자는 LBA에 쓰기/읽기를 요청하고, 내부에서는 `lba_map`으로 LBA를 PBA에 매핑합니다.
쓰기에서는 기존 PBA를 덮어쓰지 않고 INVALID로 표시한 뒤 새 FREE PBA에 데이터를 저장합니다.
읽기에서는 `lba_map`이 가리키는 최신 PBA에서 데이터를 가져옵니다.
GC는 INVALID page를 다시 FREE로 바꾸는 단순 회수 방식입니다.
Trace와 statistics는 실행 과정을 확인하기 위해 추가했습니다.

## 7. 시연 추천 순서

1. 메뉴 8번 Demo 실행
2. LBA 2에 100이 쓰이는지 확인
3. LBA 2에 다시 200을 쓰면 기존 PBA가 INVALID가 되는지 확인
4. Read LBA 2 결과가 200인지 확인
5. Mapping table에서 LBA 2가 새 PBA를 가리키는지 확인
6. Physical page table에서 이전 PBA가 INVALID인지 확인
7. GC 실행 후 INVALID page가 FREE로 바뀌는지 확인
8. Trace log에서 WRITE/READ/GC 기록 순서 확인

## 8. 조심해서 답할 부분

- "실제 SSD와 완전히 같나요?"라고 물으면 아니라고 답해야 합니다. 실제 SSD보다 단순화한 toy model입니다.
- "GC가 실제 erase를 하나요?"라고 물으면 실제 block erase는 아니고 INVALID page를 FREE로 되돌리는 단순 GC라고 답해야 합니다.
- "C 파일이 원본인가요?"라고 물으면 `src/*.asm`이 기능별 원본이고, `toy_ftl.asm`은 통합본, `toy_ftl_readable.c`는 설명용 참고 파일이라고 답하는 것이 좋습니다.
- "가장 중요한 함수는?"이라고 물으면 `ftl_write_core`라고 답하면 됩니다.
- "직접 구현한 흔적은?"이라고 물으면 기능별 파일 분리, stack frame으로 `$ra/$s` 레지스터 보존, `.word` 배열 offset 계산, trace/statistics/demo 기능을 설명하면 됩니다.

