# Random Coupler

[![Ruby Version](https://img.shields.io/badge/ruby-2.6.10-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-CLI-lightgrey?logo=gnometerminal&logoColor=white)](https://github.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/)

워크스페이스 및 이력 기반 제약 조건을 준수하면서 사람들을 1:1로 무작위 매칭하는 Ruby CLI 도구입니다. **Ruby 2.6.10** 기준으로 동작합니다.

---

## 주요 기능

- 대화형 순차 프롬프트로 사람 데이터 등록
- `/list` 명령어로 등록된 전체 인원을 JSON 배열 형식으로 출력
- 제약 조건을 준수하는 무작위 1:1 매칭 생성
- 로컬 `data` 파일을 통한 세션 간 데이터 유지
- 적용 제약 조건:
  - **C1** – 워크스페이스 인원이 정확히 2명이면 그 둘은 서로 매칭 불가
  - **C2** – 같은 워크스페이스에서 동일 gender가 3명 이하이면 해당 그룹끼리 매칭 불가
  - **C3** – 최근 **14일** 이내에 매칭된 쌍은 재매칭 불가

---

## 요구 사항

| 항목 | 버전 |
|---|---|
| Ruby | 2.6.10 |
| 표준 라이브러리 | `json`, `time` (Ruby 기본 내장) |

외부 gem은 필요하지 않습니다.

---

## 설치

```bash
git clone <repository-url>
cd random_coupler
```

별도의 `bundle install` 없이 바로 실행할 수 있습니다.

---

## 실행 방법

### macOS / Linux — 권장 (Ruby 2.6 없으면 자동 설치)

```bash
bash run.sh
```

### Windows

```bat
run.bat
```

> Windows에서는 Ruby 2.6.x를 사전에 설치해야 합니다.  
> Ruby가 없으면 `run.bat`이 다운로드 URL([rubyinstaller.org](https://rubyinstaller.org/downloads/))을 안내하고 종료합니다.  
> 다른 버전의 Ruby가 감지되면 계속 진행할지 여부를 묻습니다.

### 직접 실행 (공통)

```bash
ruby coupler.rb
```

### 사용 가능한 명령어

| 명령어 | 설명 |
|---|---|
| `/add` | 순차 프롬프트로 사람 데이터 등록 |
| `/list` | 전체 인원, 커플 기록, 그룹 기록을 JSON으로 출력 |
| `/couple` | 조건을 만족하는 2인 무작위 매칭 |
| `/group_N` | 전체 인원을 N명 단위로 그룹 편성 (예: `/group_3`) |
| `/clear` | 14일이 지난 커플·그룹 기록 삭제 |
| `/init_people` | 사람 데이터 전체 초기화 (확인 후 실행) |
| `/init_couples` 또는 `/init_couple` | 커플 기록 전체 초기화 (확인 후 실행) |
| `/init_groups` 또는 `/init_group` | 그룹 기록 전체 초기화 (확인 후 실행) |
| `/quit` | 데이터를 파일에 저장하고 종료 |

---

## 사람 등록 (`/add`)

`/add` 실행 시 각 필드를 순서대로 묻는 대화형 프롬프트가 시작됩니다.

### 입력 필드

| 필드 | 입력 | 비고 |
|---|---|---|
| `name` | 자유 텍스트 | 빈 값 불가 |
| `gender` | `m` 또는 `f` | 대소문자 무관. `m` → `male`, `f` → `female`. 그 외 값 입력 시 오류 메시지 후 재입력 요청. |
| `workspace` | 자유 텍스트 | 대소문자 무관. `Team-A`와 `team-a`는 동일한 워크스페이스로 처리 (소문자로 저장). |

한 명 등록 후 추가 등록 여부를 묻습니다:

- **`y`** (또는 `Y`) — 다음 사람 등록 계속
- **`n`** (또는 `N`) — 입력 종료 후 메인 프롬프트로 복귀

### 입력 예시

```
> /add
  Name: 홍길동
  Gender (m/f): m
  Workspace: A팀
Registered: 홍길동 | male | a팀
Total people: 1
  Add another person? (y/n): y
  Name: 김영희
  Gender (m/f): x
Error: Invalid gender 'x'. Please enter 'm' (male) or 'f' (female).
  Gender (m/f): f
  Workspace: A팀
Registered: 김영희 | female | a팀
Total people: 2
  Add another person? (y/n): n
```

---

## 데이터 목록 확인 (`/list`)

전체 인원, 커플 기록, 그룹 기록을 JSON 형식으로 출력합니다.

```
> /list
========================================
  People (4)
========================================
[ ... ]

========================================
  Couple Records (1)
========================================
[
  { "person1": "홍길동", "person2": "이수진", "coupled_at": "2026-05-08T14:00:00+09:00" }
]

========================================
  Group Records (1)
========================================
[
  { "members": ["김영희", "박민준", "최지우"], "grouped_at": "2026-05-08T15:00:00+09:00" }
]
```

---

## 2인 매칭 (`/couple`)

조건을 만족하는 2인 쌍을 **무작위로 1쌍** 생성합니다.

```
> /couple
========================================
          Matching Result
========================================
  홍길동 (a팀/male) <-> 이수진 (b팀/female)
========================================
```

유효한 쌍이 없으면 오류 메시지를 출력하고 **아무런 변경도 수행하지 않습니다.**

---

## 그룹 편성 (`/group_N`)

**전체 인원**을 N명 단위로 그룹으로 나눕니다. `N`에 2 이상의 정수를 입력합니다.

```
> /group_3
========================================
   Group Results (size: 3)
========================================
  Group 1 [3]: 홍길동, 이수진, 박민준
  Group 2 [3]: 김영희, 최지우, 강다은
  Group 3 [2]: 윤성호, 서예린
========================================
```

### 나머지 인원 처리 규칙

| 남은 인원 | 처리 방식 |
|---|---|
| 정확히 N명 | 정상 그룹 편성 |
| 2명 이상 N−1명 이하 | 그대로 마지막 그룹으로 편성 |
| 정확히 1명 | 마지막 그룹에 정원 초과로 편입 (N+1명) |

14일 규칙(C3)으로 차단된 사람은 제외되며 출력에 명시됩니다.

유효한 그룹 편성이 불가능하면 오류 메시지를 출력하고 **아무런 변경도 수행하지 않습니다.**

---

## 제약 조건 상세

### C1 — 2인 워크스페이스

워크스페이스 인원이 **정확히 2명**인 경우, 그 두 사람은 반드시 **다른 워크스페이스**의 사람과 매칭되어야 합니다.

### C2 — 소규모 동일 gender 그룹

같은 워크스페이스 내 동일 gender 인원이 **3명 이하**인 경우, 해당 그룹 구성원끼리는 매칭될 수 없습니다. 반드시 다음 중 하나와 매칭되어야 합니다:
- **다른 워크스페이스**의 사람, 또는
- 같은 워크스페이스의 **다른 gender** 사람

### C3 — 14일 재참여 금지

최근 **14일 이내**의 커플 또는 그룹 기록에 등장한 사람은 **누구와도 새로운 매칭·그룹 편성에 참여할 수 없습니다.** 쿨다운이 끝난 후에야 다시 대상이 됩니다.

제외 대상 목록은 `/couple` 및 `/group_N` 실행 시마다 모든 기록을 참조하여 새로 계산됩니다.

세 가지 제약 조건을 동시에 만족할 수 없는 경우, 해당 명령어는 오류를 출력하고 아무런 동작을 하지 않습니다.

---

## 알고리즘

1. 등록된 인원에서 가능한 모든 2인 조합을 생성합니다.
2. C1·C2·C3 제약 조건을 위반하는 조합을 걸러냅니다.
3. 남은 유효한 조합 중 하나를 무작위로 선택합니다.
4. 유효한 쌍이 없으면 아무런 변경 없이 실패를 알립니다.

---

## 만료 기록 삭제 (`/clear`)

```
> /clear
Cleared 2 couple record(s) and 1 group record(s) (total: 3).
Remaining: 1 couple record(s), 0 group record(s).
```

커플 기록과 그룹 기록 모두에서 **14일을 초과**한 항목을 삭제합니다. 14일 이내의 기록은 유지됩니다.

- 만료된 기록이 없으면 안내 메시지를 출력하고 아무런 동작을 하지 않습니다.
- 삭제된 기록은 즉시 메모리에서 제거되며, `/quit` 시 `data` 파일에 반영됩니다.

---

## 데이터 저장 및 불러오기

### 저장

`/quit` 명령어로 종료할 때, 모든 사람 정보와 매칭 이력이 현재 디렉터리의 `data` 파일(JSON 형식)에 저장됩니다.

### 불러오기

프로그램 시작 시 `data` 파일의 존재 여부를 확인합니다. 파일이 존재하고 구조가 올바르면 자동으로 메모리에 로드합니다.

### 데이터 파일 형식

```json
{
  "people": [
    { "name": "홍길동", "gender": "male", "workspace": "a팀" }
  ],
  "couples": [
    {
      "person1": "홍길동",
      "person2": "김영희",
      "coupled_at": "2026-05-08T11:30:00+09:00"
    }
  ]
}
```

> `data` 파일은 `.gitignore`에 등록되어 있어 버전 관리에 포함되지 않습니다.

---

## 개발 및 테스트

애플리케이션 자체는 런타임에 외부 gem이 필요 없지만, 이 저장소에는 자동화 테스트용 **RSpec**이 포함되어 있습니다.

```bash
bundle install
bundle exec rspec
```

환경에 따라 `rspec` 실행 파일을 찾지 못하는 경우에는 다음처럼 Ruby로 직접 테스트를 실행할 수 있습니다.

```bash
ruby -rrspec/core -e 'exit RSpec::Core::Runner.run(["spec"])'
```

현재 테스트는 다음 범위를 다룹니다.

- 대화형 사람 등록 흐름
- 목록 출력
- 커플 생성
- 그룹 생성
- 제약 조건 로직
- 만료 기록 정리
- 초기화 명령어

---

## 프로젝트 구조

```text
random-coupler/
├── coupler.rb      # 메인 프로그램
├── run.sh          # macOS/Linux 실행 스크립트 (Ruby 2.6 없으면 자동 설치)
├── run.bat         # Windows 실행 스크립트 (Ruby 사전 설치 필요)
├── Gemfile         # 개발/테스트 의존성 정의
├── .gitignore      # Git 제외 목록
├── README.md       # 영문 문서
├── README_KR.md    # 한국어 문서 (현재 파일)
├── functions/
│   ├── fn_add.rb
│   ├── fn_clear.rb
│   ├── fn_constraints.rb
│   ├── fn_couple.rb
│   ├── fn_group.rb
│   ├── fn_init_couples.rb
│   ├── fn_init_groups.rb
│   ├── fn_init_people.rb
│   └── fn_list.rb
└── spec/
    ├── spec_helper.rb
    └── functions/
        ├── fn_add_spec.rb
        ├── fn_clear_spec.rb
        ├── fn_constraints_spec.rb
        ├── fn_couple_spec.rb
        ├── fn_group_spec.rb
        ├── fn_init_couples_spec.rb
        ├── fn_init_groups_spec.rb
        ├── fn_init_people_spec.rb
        └── fn_list_spec.rb
```

---

## 라이선스

이 프로젝트는 [MIT 라이선스](LICENSE) 하에 배포됩니다.
