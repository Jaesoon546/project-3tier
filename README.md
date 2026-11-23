# NIKE 성적관리시스템 — 1차 팀 프로젝트 (학교별 성적관리 홈페이지)

![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?logo=flask&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL_8.0-4479A1?logo=mysql&logoColor=white)
![Bootstrap](https://img.shields.io/badge/Bootstrap_5-7952B3?logo=bootstrap&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?logo=javascript&logoColor=black)
![Status](https://img.shields.io/badge/상태-완료_(결과발표_2026.11.23)-success)

여러 학교의 학생 성적을 웹에서 관리하는 **3tier 홈페이지**입니다.
**브라우저(HTML·JavaScript) → Flask 애플리케이션 서버 → MySQL DB** 로 나뉘어 동작합니다.

건양대학교병원 바이오메디컬 인공지능 과정(대전바이오융합)의 1차 팀 프로젝트로, 지금까지 배운
Python · SQL · HTML · JavaScript · Flask를 한 프로젝트에 모두 쓰는 것을 목표로 했습니다.
2026년 11월 23일 결과발표를 마치고 완료했습니다.

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [주요 기능](#2-주요-기능)
3. [처음 실행해 보기 (따라 하기)](#3-처음-실행해-보기-따라-하기)
4. [테스트 계정](#4-테스트-계정)
5. [3tier 구조와 폴더 설명](#5-3tier-구조와-폴더-설명)
6. [라우트 목록](#6-라우트-목록)
7. [정해 둔 규칙](#7-정해-둔-규칙)
8. [자주 생기는 문제](#8-자주-생기는-문제)
9. [회고 — 잘된 점과 한계](#9-회고--잘된-점과-한계)

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|---|---|
| 기간 | 2026.11 — 기획 발표 → 구현 → 결과발표(11/23) |
| 목표 | 수업 내용 정리 · 3tier 개념과 다루는 방법 익히기 · 다음 프로젝트의 기반 만들기 |
| 출발점 | 수업 Flask 실습(`flaskserver.py` + `dao/` + `templates/`) 구조와, 앞서 만든 성적 프로그램의 `Student` 클래스 |
| 개발 환경 | WSL2 Ubuntu 24.04, Python 3, MySQL 8.0, HeidiSQL |

### 팀 구성

| 이름 | 담당 |
|---|---|
| 박재순 | 통합 · 발표 (Git 관리, 등수 처리 방식) |
| 김현준 | DB — 테이블 설계, 테스트 데이터(`data/*.csv`), 계정 아이디 체계 |
| 박지희 | 백엔드 — Flask 라우트, 프로시저 연동 |
| 김상민 | 프론트엔드 — 화면 구성, 학교 사진·캐릭터 yuni |

각자 약한 분야를 맡아 배우는 방식으로 역할을 나눴습니다.

---

## 2. 주요 기능

**역할별 로그인** — 관리자 / 교사 / 학생이 보는 화면과 할 수 있는 일이 다릅니다.

| 역할 | 할 수 있는 일 |
|---|---|
| 관리자 | 학교 목록·등록, 계정 발급·비밀번호 초기화·삭제, 모든 학교의 성적표·통계·변경이력 조회 |
| 교사 | 자기 학교 학생 등록·수정·삭제, 성적표(등수 순), 과목별 성적조회, 통계, 변경이력, 이름 검색 |
| 학생 | 내 성적 보기 |

- **성적 계산** — 점수를 저장할 때 Python(`service/grade.py`)이 총점·평균·학점을 계산
- **학교별 등수** — DB 뷰(`student_rank`)가 `RANK()`로 학교마다 따로 계산
- **변경이력** — 등록·수정·삭제할 때 트리거가 이전 값과 변경자를 자동으로 기록 (삭제된 학생도 조회 가능)
- **AJAX 이름 검색** — 페이지를 새로 읽지 않고 JSON으로 검색 결과를 받아 표시
- **보안 기본기** — 비밀번호는 해시로 저장, 모든 POST 폼에 CSRF 토큰, DB 접속 정보는 환경변수로

---

## 3. 처음 실행해 보기 (따라 하기)

> 처음 해 보는 사람도 따라 할 수 있도록, **새 컴퓨터(WSL2 Ubuntu 24.04)에 MySQL까지 설치하는 순서**로 적었습니다.
> 수업용 GCP 서버의 MySQL을 쓰는 경우에는 3-2를 건너뛰고, 3-3·3-4의 SQL 파일을 HeidiSQL로 실행하면 됩니다.

### 3-1. 준비물

- Windows라면 **WSL2 + Ubuntu 24.04** (Mac·Linux는 터미널 그대로)
- **Python 3.10 이상**, **MySQL 8.0 이상** (등수에 `RANK()` 함수를 써서 5.7에서는 동작하지 않습니다)

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git mysql-server
```

### 3-2. 코드 받기

```bash
git clone https://github.com/Jaesoon546/project-3tier.git
cd project-3tier
```

### 3-3. DB 만들기 (테이블 → 프로시저 순서)

Ubuntu에 설치한 MySQL은 `sudo mysql`로 root 접속이 됩니다.

```bash
sudo service mysql start              # WSL에서는 MySQL을 직접 켜야 합니다
sudo mysql < sql/schema.sql           # DB(school_sungjuk)와 테이블 생성
sudo mysql < sql/procedures.sql       # 뷰·프로시저·트리거 생성
```

> HeidiSQL을 쓸 때도 순서는 같습니다: `schema.sql` → `procedures.sql`.
> `procedures.sql`은 `DELIMITER`를 쓰므로 **파일 전체를 한 번에 실행**하세요.

### 3-4. 웹 서버가 쓸 DB 계정 만들기

Flask는 비밀번호로 접속해야 하므로 전용 계정을 하나 만듭니다. (`비밀번호`는 원하는 값으로 바꾸세요.)

```bash
sudo mysql -e "CREATE USER 'sungjuk'@'localhost' IDENTIFIED BY '비밀번호';
               GRANT ALL PRIVILEGES ON school_sungjuk.* TO 'sungjuk'@'localhost';
               FLUSH PRIVILEGES;"
```

### 3-5. 파이썬 가상환경과 패키지

```bash
python3 -m venv .venv
source .venv/bin/activate             # 새 터미널을 열 때마다 다시 실행
pip install -r requirements.txt
```

### 3-6. 접속 정보 적기 (`.env`)

접속 정보는 코드에 적지 않고 환경변수로 넘깁니다. 예시 파일을 복사해서 값을 채우세요.
`.env`는 `.gitignore`에 들어 있어 깃허브에 올라가지 않습니다.

```bash
cp .env.example .env
nano .env                             # DB_USER=sungjuk, DB_PASSWORD=3-4에서 정한 비밀번호
source .env
```

### 3-7. 테스트 데이터 넣기 (처음 한 번)

```bash
python seed_data.py
# 완료: 학교 3개, 학생 30명, 계정 34개 (비밀번호 test1234)
```

`data/*.csv`에는 점수만 있고, 총점·평균·학점은 웹에서 등록할 때와 똑같이 `service/grade.py`가 계산해서 넣습니다.

### 3-8. 서버 실행

```bash
python flaskserver.py
```

브라우저에서 **http://127.0.0.1:5000** 을 열고 아래 [테스트 계정](#4-테스트-계정)으로 로그인하세요.
서버를 끌 때는 터미널에서 `Ctrl + C`.

### 다음에 다시 실행할 때

```bash
cd project-3tier
sudo service mysql start
source .venv/bin/activate && source .env
python flaskserver.py
```

### 데이터를 처음 상태로 되돌리고 싶을 때

```bash
sudo mysql < sql/reset_data.sql       # 데이터만 비움 (테이블·프로시저는 그대로)
python seed_data.py
```

> ⚠️ `schema.sql`은 테이블을 **지우고 다시 만들기** 때문에 다시 실행하면 데이터가 모두 사라집니다.
> 프로시저만 바뀌었을 때는 `procedures.sql`만 다시 실행하면 되고, 이 파일은 데이터를 지우지 않습니다.

---

## 4. 테스트 계정

비밀번호는 모두 **`test1234`** 입니다.

| 아이디 | 역할 | 들어가서 볼 것 |
|---|---|---|
| `admin01` | 관리자 | 학교 목록·등록, 계정 관리, 모든 학교 성적표·통계·이력 (성적 수정은 불가) |
| `tea_dj001` / `tea_dj002` / `tea_dj003` | 교사 (대전고 / 충남고 / 유성고) | 학생 등록·수정·삭제 → 변경이력에 기록되는 것 확인 |
| `stu_01` ~ `stu_30` | 학생 (01~10 대전고, 11~20 충남고, 21~30 유성고) | 내 성적 |

추천 체험 순서: `tea_dj001`로 학생 한 명 점수 수정 → 성적표 등수 변화 확인 → 변경이력에서 이전 값·변경자 확인 → 해당 학생 계정(`stu_NN`)으로 로그인해 내 성적 확인.

학생 계정 `stu_NN`의 NN은 DB가 매긴 학생 번호(bunho)입니다.

---

## 5. 3tier 구조와 폴더 설명

```
 [1 tier] 브라우저            [2 tier] Flask 서버                  [3 tier] MySQL
 templates/*.html  ──요청──▶  flaskserver.py (라우트·권한)
 static/js/*.js    ◀─HTML──   service/  (점수 검사·계산)
   (AJAX: JSON)               dao/      (프로시저 호출)  ──SQL──▶  테이블 · 뷰 · 프로시저 · 트리거
```

```
project-3tier/
├── flaskserver.py          # 라우트 · 로그인/권한
├── seed_data.py            # 테스트 데이터 넣기 (data/*.csv → 프로시저)
├── make_password.py        # SQL로 직접 계정을 넣을 때 비밀번호 해시 만들기
├── requirements.txt
├── .env.example            # 접속 정보 예시 (복사해서 .env로)
├── dao/                    # DB 접근 — 모든 조회·저장을 프로시저로
│   ├── db.py               # getConnection(), 프로시저 호출 공통 함수
│   ├── school.py · student.py · user.py
├── service/                # 업무 규칙
│   ├── grade.py            # Student 클래스 — 총점·평균·학점, 점수 검사
│   ├── account.py          # 계정 발급 폼 검사
│   └── school.py           # 학교 홈페이지 주소 검사
├── templates/              # Jinja 템플릿 (모두 base.html 상속, 공통 조각은 _parts.html)
├── static/
│   ├── js/                 # form_check.js(폼 검사), search.js(AJAX 검색),
│   │                       # user_form.js(계정 발급), subject_rank.js(정렬·검색)
│   └── images/             # 메인 배경, 학교 사진(schools/<학교코드>.jpg), 캐릭터 yuni
├── data/                   # schools.csv, students.csv (테스트 데이터 원본)
└── sql/
    ├── schema.sql          # DB·테이블 생성 (처음 한 번)
    ├── procedures.sql      # 뷰·프로시저·트리거 (다시 실행해도 데이터 유지)
    ├── reset_data.sql      # 데이터만 비우기
    └── migrations/         # 이미 만든 DB에 구조 변경을 반영할 때만
```

**테이블**: `school_data`(학교) · `student_data`(학생·성적) · `student_data_backup`(변경이력) · `user_data`(계정)

---

## 6. 라우트 목록

| 라우트 | 방식 | 권한 | 내용 |
|---|---|---|---|
| `/` | GET | 모두 | 로그인 전: 첫 화면 / 로그인 후: 역할별 첫 화면으로 이동 |
| `/login` | GET·POST | 모두 | 로그인 (아이디 저장, 빈칸 검사, 로그인 시 세션 새로 시작) |
| `/logout` | POST | 모두 | 로그아웃 (csrf_token 포함 폼) |
| `/school_list` | GET | 관리자 | 학교 목록 |
| `/school_insert` | GET·POST | 관리자 | 학교 등록 |
| `/user_list` | GET | 관리자 | 계정 목록 + 계정 발급 폼 |
| `/user_insert` | POST | 관리자 | 계정 발급 (교사·학생·관리자) |
| `/user_reset`, `/user_delete` | POST | 관리자 | 비밀번호 초기화, 계정 삭제 |
| `/school_rank` | GET | 관리자·교사 | 메뉴 '학교별 성적조회' → 성적표로 이동 |
| `/sungjuk_call/<schoolcode>` | GET | 관리자·교사 | 학교별 성적표 (등수 순) |
| `/sungjuk_insert` | GET·POST | 교사 | 학생 등록 |
| `/sungjuk_update` | GET·POST | 교사 | 수정할 학생 목록 → 수정 폼 → 저장 |
| `/sungjuk_delete` | GET·POST | 교사 | 삭제할 학생 목록 → 삭제 |
| `/subject_rank`, `/subject_rank/<schoolcode>` | GET | 관리자·교사 | 과목별 성적조회 (제목 클릭 정렬, 이름 검색) |
| `/stats/<schoolcode>` | GET | 관리자·교사 | 과목별 합계·평균·최고·최저 |
| `/history`, `/history/<schoolcode>` | GET | 관리자·교사 | 변경이력 (등록·수정·삭제와 변경자) |
| `/history/student/<bunho>` | GET | 관리자·교사 | 학생 한 명의 이력 (삭제된 학생 포함) |
| `/my_sungjuk` | GET | 학생 | 내 성적 |
| `/_search?schoolcode=&name=` | GET (JSON) | 관리자·교사 | 이름 검색 (AJAX) |

---

## 7. 정해 둔 규칙

- **계산 위치**: 총점·평균·학점은 Python `service/grade.py`, 등수는 DB `student_rank` 뷰
- **DB 접근은 프로시저로만**: 결과 코드 `1` = 성공, `2` = 대상 없음, `-1` = 에러 (수업 코드와 같은 규칙)
- **보안**: 비밀번호 해시 저장(werkzeug), 모든 POST 폼에 `csrf_token`, 접속 정보·`SECRET_KEY`는 환경변수
- **계정 발급**: 관리자 화면 **계정 관리**에서 역할·학교·(학생이면) 연결할 학생을 고르고 발급 — 비밀번호는 서버에서 해시로 바꿔 저장
- **화면 자료**: 학교 사진 `static/images/schools/<학교코드>.jpg`가 있으면 학교 화면 배너·학교목록에 표시되고, 누르면 학교 홈페이지가 새 탭으로 열림 (사진·캐릭터: 김상민, 1200px 이하로 줄여 저장)

### 이미 만든 DB에 구조 변경을 반영할 때

처음 설치하는 경우에는 필요 없습니다. 예전 버전으로 DB를 만들어 둔 경우에만
`sql/migrations/`의 파일을 번호 순서대로 **한 번씩** 실행한 뒤 `procedures.sql`을 다시 실행하세요.

| 파일 | 내용 |
|---|---|
| `001_history_changed_by.sql` | 변경이력에 '변경자'와 '학생 등록' 기록 추가 |
| `002_school_homepage.sql` | 학교 홈페이지 주소 추가 |

---

## 8. 자주 생기는 문제

| 증상 | 해결 |
|---|---|
| `Can't connect to MySQL server` | `sudo service mysql start`로 MySQL을 켰는지, `.env`의 `DB_HOST`가 맞는지 확인 |
| `Access denied for user` | `source .env`를 했는지, 3-4에서 만든 계정·비밀번호와 `.env`가 같은지 확인 |
| `Unknown database 'school_sungjuk'` | `sql/schema.sql`을 먼저 실행 |
| `PROCEDURE ... does not exist` | `sql/procedures.sql`을 실행 (HeidiSQL에서는 파일 전체를 한 번에) |
| `ModuleNotFoundError: flask` 등 | `source .venv/bin/activate` 후 `pip install -r requirements.txt` |
| `seed_data.py`가 "이미 학교가 있습니다"로 멈춤 | `sql/reset_data.sql` 실행 후 다시 |
| `RANK` 관련 문법 오류 | MySQL 버전 확인 (`mysql --version`) — 8.0 이상 필요 |

---

## 9. 회고 — 잘된 점과 한계

**잘된 점**
- 수업에서 배운 Python 성적 프로그램 → SQL 프로시저 → HTML/JS → Flask를 한 흐름으로 연결해 3tier 구조를 직접 구현
- 계산(Python)·저장(프로시저)·등수(뷰)·이력(트리거)처럼 **어느 계층이 무엇을 맡는지** 규칙을 정하고 지킴
- 역할별 권한, 비밀번호 해시, CSRF, 환경변수 등 실제 서비스에 필요한 기본 보안 요소를 적용

**한계와 다음 프로젝트에서 개선할 점**
- 팀원들이 Git을 쓰지 못해, 각자 코드를 노션으로 받아 통합 담당이 뼈대에 이어 붙이는 방식으로 진행 → 다음 프로젝트에서는 팀원 모두 브랜치·PR로 협업
- 서버를 직접 실행해야 볼 수 있음 (배포는 하지 않음)
- 과목이 국어·영어·수학 3개로 고정되어 있어 과목 추가에는 테이블 구조 변경이 필요

> 처음 만든 뼈대(단계별로 살을 붙인 과정을 보여 주기 위한 버전)는 별도 비공개 저장소에 보관했습니다.
