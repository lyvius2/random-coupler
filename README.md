# Random Coupler

[![Ruby Version](https://img.shields.io/badge/ruby-2.6.10-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-CLI-lightgrey?logo=gnometerminal&logoColor=white)](https://github.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/)

> 한국어 문서는 [README_KR.md](README_KR.md)를 참고하세요.

A Ruby CLI tool that randomly pairs people into 1-on-1 couples while enforcing workspace and history-based constraints. Designed to work with **Ruby 2.6.10**.

---

## Features

- Register people through an interactive step-by-step prompt
- View all registered people as a JSON array with `/list`
- Randomly generate 1-on-1 pairings with constraint enforcement
- Persist data across sessions using a local `data` file
- Constraint rules:
  - **C1** – Members of a 2-person workspace cannot be paired with each other
  - **C2** – Members sharing the same workspace *and* gender (group ≤ 3) cannot be paired with each other
  - **C3** – People who were coupled within the last **14 days** cannot be paired again

---

## Requirements

| Requirement | Version |
|---|---|
| Ruby | 2.6.10 |
| Standard Library | `json`, `time` (bundled with Ruby) |

No external gems are required.

---

## Installation

```bash
git clone <repository-url>
cd random_coupler
```

That's it. No `bundle install` needed.

---

## Usage

### macOS / Linux — Recommended (auto-installs Ruby 2.6 if needed)

```bash
bash run.sh
```

### Windows

```bat
run.bat
```

> Ruby 2.6.x must be installed in advance on Windows.  
> If Ruby is not found, `run.bat` will display the download URL ([rubyinstaller.org](https://rubyinstaller.org/downloads/)) and exit.  
> If a different Ruby version is detected, you will be asked whether to continue.

### Manual (any platform)

```bash
ruby coupler.rb
```

### Available Commands

| Command | Description |
|---|---|
| `/add` | Register people through interactive prompts |
| `/list` | Print all registered people, couple records, and group records |
| `/couple` | Randomly pair 2 eligible people |
| `/group_N` | Divide all eligible people into groups of N (e.g. `/group_3`) |
| `/clear` | Delete couple and group records older than 14 days |
| `/init_people` | Reset all registered people (with confirmation) |
| `/init_couples` or `/init_couple` | Reset all couple records (with confirmation) |
| `/init_groups` or `/init_group` | Reset all group records (with confirmation) |
| `/quit` | Save data to file and exit |

---

## Registering People (`/add`)

Running `/add` starts an interactive prompt that asks for each field one at a time.

### Fields

| Field | Input | Notes |
|---|---|---|
| `name` | Free text | Cannot be empty |
| `gender` | `m` or `f` | Case-insensitive. `m` → `male`, `f` → `female`. Any other value triggers an error and re-prompt. |
| `workspace` | Free text | Case-insensitive. `Team-A` and `team-a` are treated as the same workspace (stored lowercase). |

After each person is registered, you are asked whether to add another:

- **`y`** (or `Y`) — continue to register the next person
- **`n`** (or `N`) — finish and return to the main prompt

### Example Session

```
> /add
  Name: Alice
  Gender (m/f): f
  Workspace: Team-A
Registered: Alice | female | team-a
Total people: 1
  Add another person? (y/n): y
  Name: Bob
  Gender (m/f): x
Error: Invalid gender 'x'. Please enter 'm' (male) or 'f' (female).
  Gender (m/f): m
  Workspace: TEAM-A
Registered: Bob | male | team-a
Total people: 2
  Add another person? (y/n): n
```

---

## Listing Data (`/list`)

Displays all registered people, couple records, and group records in JSON format.

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
  { "person1": "Alice", "person2": "Dave", "coupled_at": "2026-05-08T14:00:00+09:00" }
]

========================================
  Group Records (1)
========================================
[
  { "members": ["Bob", "Carol", "Eve"], "grouped_at": "2026-05-08T15:00:00+09:00" }
]
```

---

## Running Pairings (`/couple`)

Each `/couple` call produces **exactly one pair**, chosen randomly from all eligible people.

```
> /couple
========================================
          Matching Result
========================================
  Alice (team-a/female) <-> Dave (team-b/male)
========================================
```

If no valid pair can be found, an error message is displayed and **no changes are made**.

---

## Grouping People (`/group_N`)

Divides **all eligible people** into groups of N. Replace `N` with any integer ≥ 2.

```
> /group_3
========================================
   Group Results (size: 3)
========================================
  Group 1 [3]: Alice, Dave, Frank
  Group 2 [3]: Bob, Carol, Eve
  Group 3 [2]: Grace, Hank
========================================
```

### Group Size Rules

| Remaining people | Behaviour |
|---|---|
| Exactly `N` | Forms a normal group of N |
| Between 2 and N−1 | Forms a smaller final group as-is |
| Exactly 1 | Merged into the last group (group becomes N+1) |

People blocked by the 14-day rule (C3) are skipped and noted in the output.

If no valid grouping is possible under the constraints, an error message is displayed and **no changes are made**.

---

## Constraint Rules

### C1 — Two-person Workspace

If a workspace has **exactly 2 members**, those two people must be paired with someone from a **different workspace**.

### C2 — Small Same-gender Group

If a workspace has **3 or fewer members of the same gender**, those members cannot be paired with each other. They must be paired with:
- Someone from a **different workspace**, or
- Someone of a **different gender** in the same workspace

### C3 — 14-day Cooldown

Anyone who appears in a **couple or group record** within the last 14 days **cannot participate in any new pairing or grouping** until the cooldown expires.

The blocked list is recomputed from all records every time `/couple` or `/group_N` is run.

If no valid pairing or grouping is possible after applying all constraints, the command outputs an error and does nothing.

---

## Algorithm

1. Generate all possible combinations of 2 people from the registered list.
2. Filter out combinations that violate any active constraint (C1, C2, C3).
3. Pick one combination at random from the remaining valid pairs.
4. If no valid pair exists, report failure without making any changes.

---

## Clearing Expired Records (`/clear`)

```
> /clear
Cleared 2 couple record(s) and 1 group record(s) (total: 3).
Remaining: 1 couple record(s), 0 group record(s).
```

Removes all couple **and** group records whose timestamp is **older than 14 days**.

- If no records have expired, a message is displayed and nothing is changed.
- Changes take effect in memory immediately and are saved to `data` on `/quit`.

---

## Data Persistence

### Saving

When you type `/quit`, all people and couple history are saved to a file named `data` in the working directory (JSON format).

### Loading

When the program starts, it checks for a `data` file. If the file exists and its structure is valid, the data is loaded into memory automatically.

### Data File Format

```json
{
  "people": [
    { "name": "Alice", "gender": "female", "workspace": "team-a" }
  ],
  "couples": [
    {
      "person1": "Alice",
      "person2": "Bob",
      "coupled_at": "2026-05-08T11:30:00+09:00"
    }
  ]
}
```

> The `data` file is listed in `.gitignore` and will not be committed to version control.

---

## Project Structure

```
random_coupler/
├── coupler.rb      # Main program
├── run.sh          # Launcher for macOS/Linux (auto-installs Ruby 2.6 if missing)
├── run.bat         # Launcher for Windows (Ruby must be pre-installed)
├── .gitignore      # Git ignore rules
├── README.md       # This file (English)
└── README_KR.md    # Korean version
```

---

## License

This project is released under the [MIT License](LICENSE).
