# SSD FTL Simulator 면담 대비 Q&A

이 문서는 현재 최신 구현 기준인 `src/*.asm` 구조와 `toy_ftl_readable.c` 설명 코드를 기준으로 정리한 면담 대비 자료입니다.

핵심 구현은 **LBA-PBA mapping**, **out-of-place write**, **INVALID page 관리**, **block 단위 GC**, **VALID page migration**, **trace log**입니다.

> 제출 전 체크: `src`와 `toy_ftl_readable.c`는 최신 GC migration 구조입니다. 단일 통합 실행본 `toy_ftl.asm`을 제출하거나 실행할 예정이면, 최신 `src` 변경이 통합본에도 반영되어 있는지 따로 확인해야 합니다.

---

## 1. 프로젝트 한 줄 설명

이 프로젝트는 SSD 내부의 FTL(Flash Translation Layer)을 아주 작은 크기로 단순화해서 구현한 MIPS assembly simulator입니다.

사용자는 LBA(Logical Block Address)에 write/read를 요청하고, 내부에서는 `lba_map`을 이용해 LBA를 실제 물리 page인 PBA(Physical Page Address)에 연결합니다.

overwrite가 발생하면 기존 PBA를 바로 덮어쓰지 않고 `INVALID`로 표시한 뒤, 새로운 `FREE` PBA에 최신 data를 씁니다. 이후 GC가 INVALID page가 많은 block을 골라 VALID page를 다른 곳으로 옮기고 block 전체를 erase합니다.

---

## 2. 전체 구조

### 주소와 크기

```text
LBA_COUNT = 4
PBA_COUNT = 8
BLOCK_SIZE = 2
BLOCK_COUNT = 4
```

즉, LBA는 0부터 3까지 있고, PBA는 0부터 7까지 있습니다.

block은 PBA 2개를 묶어서 만듭니다.

```text
Block 0: PBA 0, 1
Block 1: PBA 2, 3
Block 2: PBA 4, 5
Block 3: PBA 6, 7
```

### page 상태

```text
FREE    = 0: 비어 있는 page
VALID   = 1: 현재 최신 data가 들어 있는 page
INVALID = 2: 예전 data라 더 이상 최신이 아닌 page
```

---

## 3. 주요 파일 역할

| 파일 | 역할 |
|---|---|
| `src/data.asm` | 전역 상수, 배열, 메시지 정의 |
| `src/main.asm` | 메뉴 loop와 사용자 입력 분기 |
| `src/command.asm` | 메뉴 번호와 실제 기능 함수를 연결하는 wrapper |
| `src/ftl_write.asm` | write 요청 처리, out-of-place write 구현 |
| `src/ftl_read.asm` | read 요청 처리 |
| `src/ftl_mapping.asm` | LBA-PBA mapping 조회, 수정, 초기화, 역검색 |
| `src/nand_model.asm` | PBA 상태/data 관리, FREE page 검색, block erase, count 재계산 |
| `src/gc.asm` | victim block 선택, VALID page migration, block erase |
| `src/trace.asm` | WRITE/READ/GC/RESET/MIGRATE event 기록과 출력 |
| `src/status.asm` | 통계와 전체 상태 출력 |
| `src/reset.asm` | SSD 상태 초기화 |
| `src/demo.asm` | migration GC를 보여주는 고정 시나리오 |
| `src/util.asm` | 출력, 입력, separator, state 처리 |
| `toy_ftl_readable.c` | 같은 로직을 C로 옮긴 설명용 참고 파일 |

---

## 4. 핵심 자료구조

### `lba_map[4]`

각 LBA가 현재 어느 PBA를 가리키는지 저장합니다.

예:

```text
lba_map[2] = 5
```

이 뜻은 "LBA 2의 최신 data는 PBA 5에 있다"입니다.

초기값은 전부 `-1`입니다. `-1`은 아직 data가 없다는 뜻입니다.

### `pba_state[8]`

각 PBA의 상태를 저장합니다.

예:

```text
pba_state[0] = INVALID
pba_state[1] = VALID
pba_state[2] = FREE
```

### `pba_data[8]`

각 PBA에 저장된 data 값을 저장합니다.

### trace 배열

trace는 실행 중 발생한 event를 순서대로 저장합니다.

```text
trace_type: WRITE, READ, GC, RESET, MIGRATE
trace_lba : 관련 LBA, 없으면 -1
trace_pba : 관련 PBA 또는 migration 전 old PBA
trace_data: data 값, GC freed count, 또는 migration 후 new PBA
```

MIGRATE event에서는 `trace_data`가 data 값이 아니라 **new PBA**로 쓰입니다.

---

## 5. Write 로직 설명

핵심 함수는 `ftl_write_core`입니다.

### 동작 순서

1. 입력받은 LBA의 기존 mapping을 확인합니다.
2. 먼저 `find_free_pba`로 새로 쓸 FREE PBA를 찾습니다.
3. FREE PBA가 없으면 기존 mapping을 건드리지 않고 실패합니다.
4. 기존 PBA가 있으면 그 PBA를 `INVALID`로 바꿉니다.
5. 새 PBA를 `VALID`로 만들고 data를 저장합니다.
6. `lba_map[lba] = new_pba`로 mapping을 최신 PBA로 바꿉니다.
7. `recount_page_counts`로 FREE/INVALID count를 다시 계산합니다.
8. write count와 trace를 기록합니다.

### 중요한 점

FREE PBA를 먼저 찾고 나서 old PBA를 INVALID로 바꿉니다.

이유는 FREE PBA가 없는 상황에서 old PBA를 먼저 INVALID로 바꾸면, write는 실패했는데 기존 최신 data까지 잃어버리는 문제가 생기기 때문입니다.

면담에서 이렇게 말하면 됩니다.

```text
write는 out-of-place 방식입니다.
기존 PBA를 직접 덮어쓰지 않고, 먼저 새 FREE PBA를 찾습니다.
FREE PBA가 있으면 기존 PBA를 INVALID로 만들고 새 PBA에 data를 씁니다.
마지막으로 lba_map을 새 PBA로 갱신해서 read가 항상 최신 data를 보게 합니다.
```

---

## 6. Read 로직 설명

핵심 함수는 `ftl_read_core`입니다.

### 동작 순서

1. 입력 LBA로 `lba_map[lba]`를 조회합니다.
2. 값이 `-1`이면 아직 저장된 data가 없으므로 종료합니다.
3. PBA가 있으면 `pba_data[pba]`를 읽어 출력합니다.
4. read count와 trace를 기록합니다.

면담에서 이렇게 말하면 됩니다.

```text
read는 전체 PBA를 검색하지 않습니다.
lba_map이 최신 PBA를 가리키고 있으므로, lba_map[lba]만 확인하면 바로 최신 data 위치를 알 수 있습니다.
```

---

## 7. Block GC 로직 설명

핵심 함수는 `run_gc`입니다.

현재 GC는 page 하나씩 FREE로 바꾸는 방식이 아니라, 실제 NAND 특성을 반영해서 **block 단위 erase** 흐름을 사용합니다.

다만 실제 SSD처럼 복잡한 wear leveling이나 bad block 관리는 구현하지 않았고, 면담에서 설명 가능한 수준으로 단순화했습니다.

### 전체 흐름

```text
1. 모든 block을 검사한다.
2. INVALID page 수가 가장 많은 block을 victim으로 고른다.
3. INVALID page가 하나도 없으면 GC를 하지 않는다.
4. victim block 안의 VALID page 수를 센다.
5. victim block 밖의 FREE page 수를 센다.
6. 밖의 FREE page가 부족하면 GC를 실패 처리한다.
7. victim 안의 VALID page를 victim 밖 FREE PBA로 migration한다.
8. mapping table을 old PBA에서 new PBA로 갱신한다.
9. victim block 전체를 erase해서 FREE/data 0으로 만든다.
10. page count를 다시 계산하고 GC/erase count와 trace를 기록한다.
```

### victim block 선택

모든 block을 검사해서 INVALID page가 가장 많은 block을 고릅니다.

동률이면 먼저 발견된 block이 유지됩니다. 코드에서는 `invalid_count > victim_invalid_count`일 때만 victim을 바꾸기 때문입니다.

즉, 동률이면 번호가 작은 block이 선택됩니다.

### VALID page migration

block erase는 block 안의 모든 page를 지웁니다.

따라서 victim block 안에 VALID page가 있으면, erase 전에 다른 FREE PBA로 복사해야 합니다.

이 과정이 VALID page migration입니다.

예:

```text
Before GC:
Block 0 = PBA 0 INVALID, PBA 1 VALID

Migration:
PBA 1의 data를 PBA 3으로 복사
lba_map[1] = 3으로 변경

Erase:
Block 0 전체 erase
PBA 0 FREE, PBA 1 FREE
```

### 왜 `find_lba_by_pba`가 필요한가?

GC는 victim block 안의 PBA를 보고 있습니다.

그런데 mapping을 갱신하려면 이 PBA가 어느 LBA의 최신 data인지 알아야 합니다.

그래서 `find_lba_by_pba(old_pba)`가 `lba_map[0..3]`을 순회해서 old PBA를 가리키는 LBA를 찾습니다.

예:

```text
lba_map[1] = 1
```

이면 PBA 1은 LBA 1의 최신 data입니다.

PBA 1을 PBA 3으로 옮기면:

```text
lba_map[1] = 3
```

으로 바꿔야 합니다.

### 왜 victim block 밖에서 FREE PBA를 찾는가?

victim block은 곧 erase됩니다.

만약 migration 목적지를 victim block 안에서 고르면, 복사한 data도 곧 erase되어 사라집니다.

그래서 `find_free_pba_excluding_block(victim_block)`으로 victim 밖의 FREE PBA만 찾습니다.

### 왜 count를 수동 증감하지 않고 다시 세는가?

write와 GC에서는 여러 PBA 상태가 한 번에 바뀔 수 있습니다.

수동으로 `free_page_count++`, `invalid_page_count--`처럼 관리하면 작은 실수로 count가 틀어질 수 있습니다.

그래서 현재 구현은 중요한 상태 변경 후 `recount_page_counts`를 호출해서 `pba_state` 전체를 다시 세고, 그 값을 count에 저장합니다.

면담 답변:

```text
pba_state가 실제 상태의 기준입니다.
count는 pba_state를 다시 스캔해서 계산하는 방식이 더 안전해서 recount_page_counts를 사용했습니다.
```

### GC freed count는 왜 victim의 INVALID 수인가?

GC 중 VALID page는 다른 FREE PBA로 이동합니다.

VALID page를 옮기면 밖의 FREE page를 하나 사용하지만, erase 후 victim 안의 그 page도 FREE가 됩니다.

결과적으로 순수하게 새로 늘어난 FREE page 수는 victim 안에 있던 INVALID page 수와 같습니다.

예:

```text
victim block = INVALID 1개 + VALID 1개

VALID 1개 migration:
밖의 FREE 1개 사용

block erase:
victim 안 PBA 2개가 FREE

순증가 FREE = 1개
```

그래서 trace의 `GC | Freed pages: 1`은 victim block에 있던 INVALID page 수를 기록합니다.

---

## 8. Trace 로직 설명

trace는 프로그램 동작을 나중에 확인하기 위한 기록입니다.

현재 event type은 다음과 같습니다.

```text
TTYPE_WRITE   = 1
TTYPE_READ    = 2
TTYPE_GC      = 3
TTYPE_RESET   = 4
TTYPE_MIGRATE = 5
```

### 출력 예시

```text
WRITE   | LBA 2 | PBA 0 | DATA 100
READ    | LBA 2 | PBA 0 | DATA 100
MIGRATE | LBA 1 | PBA 1 -> PBA 3
GC      | Freed pages: 1
RESET
```

### MIGRATE trace 저장 방식

```text
trace_lba  = 이동된 VALID page의 LBA
trace_pba  = old PBA
trace_data = new PBA
```

예:

```text
MIGRATE | LBA 1 | PBA 1 -> PBA 3
```

뜻:

```text
LBA 1의 최신 data가 원래 PBA 1에 있었는데,
GC 중 PBA 3으로 이동했다.
```

---

## 9. Demo 시나리오 설명

`run_demo_scenario`는 GC migration을 눈으로 확인하기 위한 고정 시나리오입니다.

### 단계

```text
1. Write 100 to LBA 2
2. Write 50 to LBA 1
3. Read LBA 2
4. Write 200 to LBA 2 again
5. Read LBA 2 again (expect 200)
6. Print mapping table before GC
7. Print physical page table before GC
8. Run GC (expect valid page migration)
9. Read LBA 1 after GC (expect 50)
10. Print mapping table after GC
11. Print physical page table after GC
12. Print trace log
```

### demo에서 중요한 상태

초기 write 후:

```text
LBA 2 -> PBA 0, data 100
LBA 1 -> PBA 1, data 50
```

LBA 2를 다시 write하면:

```text
PBA 0 -> INVALID
LBA 2 -> PBA 2, data 200
```

이때 block 0은 다음 상태가 됩니다.

```text
Block 0:
PBA 0 = INVALID
PBA 1 = VALID, data 50
```

GC 실행 후:

```text
PBA 1의 VALID data 50이 PBA 3으로 이동
lba_map[1] = 3
Block 0 erase
PBA 0 = FREE
PBA 1 = FREE
```

그래서 GC 후 `Read LBA 1`을 하면 여전히 data 50이 나와야 합니다.

### 예상 trace 핵심

```text
MIGRATE | LBA 1 | PBA 1 -> PBA 3
GC      | Freed pages: 1
READ    | LBA 1 | PBA 3 | DATA 50
```

`READ LBA 1`은 demo에서 GC 후 검증을 위해 실행하므로, MIGRATE와 GC 뒤에 추가로 남습니다.

---

## 10. 교수님 예상 질문과 답변

### Q1. 이 프로젝트는 무엇을 구현한 건가요?

A. SSD 내부의 FTL을 단순화해서 구현했습니다. 사용자는 LBA 기준으로 write/read를 요청하고, 내부에서는 `lba_map`을 통해 LBA를 PBA로 변환합니다. overwrite 시 기존 PBA는 INVALID로 표시하고 새 FREE PBA에 data를 쓰며, GC는 INVALID가 많은 block을 골라 VALID page를 옮긴 뒤 block erase를 수행합니다.

### Q2. FTL이 왜 필요한가요?

A. 사용자는 논리 주소인 LBA만 알고 있고, 실제 NAND에는 물리 주소인 PBA가 있습니다. FTL은 LBA와 PBA 사이의 mapping을 관리해서 사용자가 같은 LBA를 계속 읽고 써도 내부적으로는 안전하게 다른 PBA를 사용할 수 있게 해줍니다.

### Q3. 왜 기존 PBA에 바로 덮어쓰지 않나요?

A. NAND flash는 일반 메모리처럼 page를 바로 덮어쓰기 어렵습니다. 보통 새 page에 data를 쓰고 기존 page는 INVALID로 표시합니다. 이런 방식을 out-of-place write라고 합니다.

### Q4. overwrite가 발생하면 정확히 어떤 일이 일어나나요?

A. 예를 들어 LBA 2가 PBA 0을 가리키고 있을 때 LBA 2에 새 data를 쓰면, 먼저 새 FREE PBA를 찾습니다. 새 PBA가 있으면 PBA 0을 INVALID로 바꾸고 새 PBA에 data를 저장합니다. 마지막으로 `lba_map[2]`를 새 PBA로 갱신합니다.

### Q5. FREE PBA가 없으면 어떻게 되나요?

A. write를 실패 처리합니다. 중요한 점은 기존 PBA를 INVALID로 바꾸기 전에 FREE PBA를 먼저 찾는다는 것입니다. 그래서 FREE PBA가 없으면 기존 mapping과 기존 VALID data가 그대로 유지됩니다.

### Q6. read는 어떻게 최신 data를 찾나요?

A. read는 전체 PBA를 검색하지 않습니다. `lba_map[lba]`가 항상 최신 PBA를 가리키도록 write와 GC에서 갱신하기 때문에, read는 mapping table만 보고 바로 최신 PBA를 찾습니다.

### Q7. `lba_map`의 초기값이 왜 `-1`인가요?

A. 아직 해당 LBA에 저장된 data가 없다는 표시입니다. read 시 mapping 값이 `-1`이면 "No data for this LBA."를 출력합니다.

### Q8. `pba_state`의 `VALID`와 `INVALID` 차이는 무엇인가요?

A. `VALID`는 현재 최신 data가 있는 page입니다. `INVALID`는 예전에는 data가 있었지만 overwrite 때문에 더 이상 최신이 아닌 page입니다. INVALID page는 GC가 회수할 수 있습니다.

### Q9. GC는 왜 필요한가요?

A. overwrite가 반복되면 INVALID page가 쌓입니다. INVALID page는 최신 data가 아니므로 지워서 다시 FREE page로 만들 수 있습니다. GC는 이런 공간 회수를 담당합니다.

### Q10. 현재 GC의 핵심 알고리즘은 무엇인가요?

A. 모든 block을 검사해서 INVALID page가 가장 많은 block을 victim으로 고릅니다. victim 안의 VALID page는 victim 밖 FREE PBA로 옮기고 mapping을 갱신합니다. 그 다음 victim block 전체를 erase해서 FREE page로 만듭니다.

### Q11. 왜 INVALID가 가장 많은 block을 victim으로 고르나요?

A. INVALID page가 많을수록 erase 후 실제로 회수되는 FREE page가 많기 때문입니다. 즉, 같은 GC를 하더라도 더 많은 공간을 되찾을 가능성이 큽니다.

### Q12. 동률이면 어떤 block이 선택되나요?

A. 번호가 작은 block이 선택됩니다. 코드에서 `invalid_count > victim_invalid_count`일 때만 victim을 갱신하므로, 같은 invalid 수인 경우 기존 victim이 유지됩니다.

### Q13. 왜 VALID page를 migration해야 하나요?

A. block erase는 block 안의 모든 page를 지웁니다. victim block 안에 VALID page가 있으면 그대로 erase할 경우 최신 data를 잃습니다. 그래서 erase 전에 VALID page를 다른 FREE PBA로 복사합니다.

### Q14. migration할 때 어떤 순서로 처리하나요?

A. victim block 안의 PBA를 순회합니다. 상태가 VALID이면 data를 읽고, 그 PBA를 가리키는 LBA를 찾고, victim 밖 FREE PBA를 찾습니다. 그 다음 새 PBA에 data를 복사하고 `lba_map[lba]`를 새 PBA로 갱신합니다.

### Q15. old PBA가 어느 LBA인지 어떻게 찾나요?

A. `find_lba_by_pba`가 `lba_map[0..3]`을 순회합니다. `lba_map[lba] == old_pba`인 LBA를 찾으면 그 LBA가 해당 PBA의 주인입니다.

### Q16. 왜 migration 목적지를 victim block 밖에서 찾나요?

A. victim block은 곧 erase됩니다. victim block 안에 복사하면 복사한 data도 같이 지워집니다. 그래서 victim block을 제외한 곳에서 FREE PBA를 찾아야 합니다.

### Q17. migration 후 old PBA는 바로 INVALID로 바꾸나요?

A. 현재 구현에서는 migration 중 old PBA 상태를 따로 바꾸지 않아도 됩니다. 곧 victim block 전체를 erase할 것이기 때문입니다. 중요한 것은 mapping을 new PBA로 바꾼 뒤 erase한다는 점입니다.

### Q18. GC 전에 FREE 공간이 충분한지 왜 미리 검사하나요?

A. migration 도중 FREE PBA가 부족하면 일부 page만 옮겨진 애매한 상태가 될 수 있습니다. 그래서 먼저 victim 안 VALID page 수와 victim 밖 FREE page 수를 비교합니다. 부족하면 상태를 건드리지 않고 실패합니다.

### Q19. GC 실패 시 count나 trace가 바뀌나요?

A. 아닙니다. victim이 없거나 migration 공간이 부족하면 GC count, erase count, trace를 증가시키지 않고 종료합니다.

### Q20. GC 성공 시 어떤 count가 증가하나요?

A. `gc_count`가 1 증가하고, 실제 block erase를 수행했으므로 `erase_count`도 1 증가합니다. 그리고 `recount_page_counts`로 FREE/INVALID page count를 다시 계산합니다.

### Q21. `recount_page_counts`를 왜 쓰나요?

A. 수동 증감보다 안전하기 때문입니다. write와 GC는 여러 page 상태를 동시에 바꿉니다. 그래서 최종 기준인 `pba_state` 배열을 다시 스캔해 FREE와 INVALID 개수를 재계산합니다.

### Q22. GC trace의 freed page 수는 무엇을 의미하나요?

A. victim block에 있던 INVALID page 수입니다. VALID page는 migration하면서 밖의 FREE page를 하나 사용하므로 순수하게 새로 늘어나는 FREE page 수는 INVALID page 수와 같습니다.

### Q23. 실제 SSD와 다른 점은 무엇인가요?

A. 실제 SSD는 훨씬 복잡합니다. wear leveling, bad block 관리, erase count 기반 victim 선택, mapping table persistence, reserve block, NAND timing 등이 필요합니다. 이 프로젝트는 FTL 핵심 개념을 설명하기 위한 toy simulator입니다.

### Q24. 이전 page 단위 GC와 지금 GC의 차이는 무엇인가요?

A. 이전 방식은 INVALID page를 바로 FREE로 바꾸는 page 단위 회수였습니다. 지금은 PBA 2개를 block으로 묶고, block을 victim으로 선택한 뒤 VALID page를 migration하고 block 전체를 erase합니다. 실제 NAND가 block 단위 erase를 한다는 점을 더 잘 반영합니다.

### Q25. `BLOCK_SIZE`는 무엇인가요?

A. block 하나에 들어가는 page 수입니다. 현재는 `BLOCK_SIZE = 2`라서 PBA 2개가 한 block입니다.

### Q26. `BLOCK_COUNT`는 어떻게 정해지나요?

A. 전체 PBA 수를 block 크기로 나눈 값입니다. 현재는 `PBA_COUNT = 8`, `BLOCK_SIZE = 2`이므로 `BLOCK_COUNT = 4`입니다.

### Q27. trace log는 왜 만들었나요?

A. 프로그램이 어떤 순서로 동작했는지 확인하기 위해서입니다. WRITE, READ, GC, RESET, MIGRATE event를 기록하면 demo 결과를 검증하거나 면담에서 동작을 설명하기 쉽습니다.

### Q28. MIGRATE trace는 왜 추가했나요?

A. GC가 VALID page를 실제로 옮겼다는 사실을 trace에서 직접 확인하기 위해서입니다. 이전에는 GC freed count만 보여서 migration이 일어났는지 바로 알기 어려웠습니다.

### Q29. demo에서 왜 LBA 2를 먼저 쓰고 다시 쓰나요?

A. overwrite를 만들어서 INVALID page를 만들기 위해서입니다. LBA 2에 100을 쓰면 PBA 0이 VALID가 되고, LBA 2에 200을 다시 쓰면 PBA 0이 INVALID가 됩니다.

### Q30. demo에서 왜 LBA 1을 중간에 쓰나요?

A. block 0 안에 VALID page를 하나 남기기 위해서입니다. LBA 1의 data 50이 PBA 1에 저장되면 block 0은 `PBA 0 INVALID + PBA 1 VALID` 상태가 됩니다. 이 상태가 migration GC를 설명하기 좋습니다.

### Q31. demo에서 GC 후 LBA 1을 read하는 이유는 무엇인가요?

A. migration 후에도 data가 보존됐는지 확인하기 위해서입니다. PBA 1에 있던 data 50이 PBA 3으로 이동하고, `lba_map[1]`도 PBA 3으로 바뀌어야 합니다. 그래서 `Read LBA 1` 결과가 50이면 migration이 성공한 것입니다.

### Q32. 교수님이 `run_gc`를 설명해보라고 하면 어떻게 말하면 되나요?

A. 이렇게 말하면 됩니다.

```text
run_gc는 먼저 모든 block의 INVALID page 수를 세서 victim block을 고릅니다.
victim 안에 VALID page가 있으면 erase 전에 victim 밖 FREE PBA로 data를 복사합니다.
복사 후에는 lba_map을 새 PBA로 바꿉니다.
그 다음 victim block 전체를 erase해서 FREE 상태로 만들고,
page count를 다시 계산한 뒤 GC와 MIGRATE trace를 남깁니다.
```

### Q33. 교수님이 `ftl_write_core`를 설명해보라고 하면 어떻게 말하면 되나요?

A. 이렇게 말하면 됩니다.

```text
ftl_write_core는 LBA에 새 data를 쓰는 함수입니다.
먼저 기존 mapping과 새 FREE PBA를 찾습니다.
FREE PBA가 없으면 기존 data를 보존하고 실패합니다.
FREE PBA가 있으면 기존 PBA를 INVALID로 만들고,
새 PBA에 data를 저장한 뒤 lba_map을 새 PBA로 갱신합니다.
마지막으로 count를 재계산하고 WRITE trace를 남깁니다.
```

### Q34. 교수님이 `ftl_read_core`를 설명해보라고 하면 어떻게 말하면 되나요?

A. 이렇게 말하면 됩니다.

```text
ftl_read_core는 LBA를 받아 lba_map에서 PBA를 찾습니다.
mapping이 -1이면 data가 없다고 출력합니다.
PBA가 있으면 pba_data[PBA]를 읽어 출력하고 READ trace를 남깁니다.
```

### Q35. 교수님이 "직접 구현했는지 확인하겠다"며 특정 helper를 물어보면?

A. helper별로 이렇게 답하면 됩니다.

```text
find_free_pba:
PBA 0부터 7까지 pba_state를 확인해서 처음 만나는 FREE PBA를 반환합니다.

find_free_pba_excluding_block:
GC migration 목적지를 찾는 함수입니다.
victim block 안의 PBA는 곧 erase되므로 건너뛰고, victim 밖 FREE PBA만 반환합니다.

find_lba_by_pba:
GC가 old PBA를 보고 있을 때 그 PBA가 어떤 LBA의 최신 data인지 찾기 위해 lba_map을 순회합니다.

erase_block:
block_id를 받아 start PBA와 end PBA를 계산하고, 그 범위의 state를 FREE, data를 0으로 초기화합니다.

recount_page_counts:
pba_state 전체를 다시 스캔해서 FREE page 수와 INVALID page 수를 재계산합니다.
```

### Q36. MIPS assembly에서 배열 index는 어떻게 계산했나요?

A. `.word` 배열은 원소 하나가 4 byte입니다. 그래서 index에 4를 곱해야 합니다. assembly에서는 보통 `sll index, index, 2`로 `index * 4` offset을 만들고, 배열 시작 주소에 더해서 해당 원소 주소를 계산합니다.

### Q37. MIPS에서 함수 호출 시 register 보존은 어떻게 했나요?

A. 다른 함수를 `jal`로 호출하는 함수는 `$ra`를 stack에 저장했다가 복구합니다. 오래 유지해야 하는 값은 `$s0`, `$s1` 같은 saved register에 넣고, 함수 시작 때 stack에 저장했다가 끝날 때 복구합니다.

### Q38. `toy_ftl_readable.c`는 왜 있나요?

A. assembly는 한눈에 로직을 보기 어렵기 때문에, 같은 구조를 C 코드로 옮긴 설명용 파일입니다. 실제 구현 기준은 `src/*.asm`이고, C 파일은 면담에서 알고리즘을 설명하거나 디버깅할 때 참고하기 좋게 만든 파일입니다.

### Q39. `toy_ftl.asm`과 `src`의 관계는 무엇인가요?

A. `src`는 기능별로 분리된 원본 구조이고, `toy_ftl.asm`은 원래 단일 파일 실행이나 제출을 위해 합쳐 쓰는 통합본입니다. 다만 통합본을 사용할 때는 최신 `src` 변경이 반영되어 있는지 확인해야 합니다.

### Q40. 현재 구현의 한계는 무엇인가요?

A. 실제 SSD 수준의 wear leveling, bad block 관리, erase count 기반 victim 선택, reserve block, mapping table persistence는 없습니다. 또한 NAND command timing도 단순화했습니다. 목표는 FTL의 핵심 흐름인 mapping, out-of-place write, invalidation, migration GC를 이해하기 쉽게 보여주는 것입니다.

---

## 11. 바로 외울 수 있는 핵심 답변

### 프로젝트 설명

```text
이 프로젝트는 SSD의 FTL을 단순화한 MIPS assembly simulator입니다.
LBA를 PBA로 mapping하고, write는 기존 page를 덮어쓰지 않고 새 FREE PBA에 씁니다.
기존 PBA는 INVALID로 표시하고, read는 lba_map이 가리키는 최신 PBA에서 data를 읽습니다.
GC는 INVALID가 많은 block을 victim으로 고른 뒤 VALID page를 밖으로 옮기고 block 전체를 erase합니다.
```

### GC 설명

```text
GC는 모든 block의 INVALID page 수를 세서 victim block을 고릅니다.
victim 안의 VALID page는 erase 전에 victim 밖 FREE PBA로 migration합니다.
이때 find_lba_by_pba로 해당 PBA의 LBA를 찾고, lba_map을 새 PBA로 갱신합니다.
그 다음 victim block을 erase하고 page count를 다시 계산합니다.
```

### Write 설명

```text
write는 out-of-place 방식입니다.
먼저 새 FREE PBA를 찾고, 없으면 기존 data를 보존한 채 실패합니다.
FREE PBA가 있으면 기존 PBA를 INVALID로 만들고 새 PBA에 data를 저장합니다.
마지막으로 lba_map을 새 PBA로 바꿔 read가 최신 data를 찾게 합니다.
```

### Trace 설명

```text
trace는 실행 순서를 기록하기 위한 log입니다.
WRITE, READ, RESET, GC뿐 아니라 GC 중 VALID page가 이동한 MIGRATE event도 기록합니다.
MIGRATE trace는 LBA, old PBA, new PBA를 보여주기 때문에 GC migration이 실제로 일어났는지 확인할 수 있습니다.
```

---

## 12. 시연 추천 순서

1. 메뉴 8번 demo 실행
2. LBA 2에 100이 쓰이는지 확인
3. LBA 1에 50이 쓰이는지 확인
4. LBA 2를 다시 200으로 overwrite해서 PBA 0이 INVALID가 되는지 확인
5. GC 전 physical table에서 block 0이 `PBA 0 INVALID + PBA 1 VALID`인지 확인
6. GC 실행 중 `Move valid page PBA 1 -> PBA 3` 메시지 확인
7. GC 후 `Read LBA 1` 결과가 50인지 확인
8. mapping table에서 `LBA 1 -> PBA 3` 확인
9. physical table에서 PBA 0과 PBA 1이 FREE/data 0인지 확인
10. trace log에서 `MIGRATE`와 `GC` event 확인

---

## 13. 면담 때 조심할 부분

- 실제 SSD와 완전히 같다고 말하지 말기
- wear leveling과 bad block 관리는 구현하지 않았다고 정확히 말하기
- block erase 때문에 VALID page migration이 필요하다고 설명하기
- `free_page_count`와 `invalid_page_count`는 수동 증감보다 재계산 방식으로 안전하게 처리했다고 말하기
- `toy_ftl_readable.c`는 설명용이고, 핵심 구현 기준은 `src/*.asm`이라고 말하기
- 통합본 `toy_ftl.asm`을 실행 기준으로 쓸 경우 최신 `src`와 동기화됐는지 확인하기

