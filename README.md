# NIKE 성적관리시스템 — 1차 팀 프로젝트 (학교별 성적관리 홈페이지)

여러 학교의 학생 성적을 웹에서 관리하는 3tier 홈페이지입니다 (브라우저 → Flask → MySQL).
수업 Flask 실습(`flaskserver.py` + `dao/` + `templates/`) 구조를 뼈대로 사용했습니다.

## 폴더 구조

```
school_sungjuk/
├── flaskserver.py          # 라우트 · 로그인/권한
├── make_password.py        # 새 계정 비밀번호 해시 만들기
├── requirements.txt
├── dao/                    # DB 접근 (프로시저 호출)
│   ├── db.py               # getConnection(), 프로시저 호출 함수
│   ├── school.py
│   ├── student.py
│   └── user.py
├── service/
│   ├── grade.py            # Student 클래스 — 총점·평균·학점, 점수 검사
│   └── account.py          # 계정 발급 폼 검사
├── templates/              # 모두 base.html 상속
├── static/js/              # form_check.js (폼 검사), search.js (AJAX 검색), user_form.js (계정 발급), subject_rank.js (정렬·검색)
└── sql/                    # schema → procedures → school_data → student_data → user_data 순서로 실행
```

## 실행 방법 (WSL2 Ubuntu)

```bash
# 1) 패키지 설치
pip install -r requirements.txt

# 2) DB 만들기 — HeidiSQL에서 sql/ 파일을 아래 순서대로 실행
#    처음 만들 때: schema.sql → procedures.sql
#    이미 만든 DB의 데이터를 비울 때: reset_data.sql
#    (schema.sql은 테이블을 지우고 다시 만들므로 다시 실행하지 않음)

# 3) 접속 정보는 환경변수로 (코드·문서에 비밀번호를 적지 않음)
export DB_HOST=<DB 서버 IP>
export DB_USER=root
export DB_PASSWORD=<비밀번호>
export SECRET_KEY=<아무 긴 문자열>

# 4) 테스트 데이터 넣기 (DB가 비어 있을 때 한 번)
#    data/*.csv의 점수만 읽고, 총점·평균·학점은 service/grade.py가 계산해서 저장
python seed_data.py

# 5) 서버 실행
python flaskserver.py      # http://127.0.0.1:5000
```

## 테스트 계정 (비밀번호 모두 `test1234`)

| 아이디 | 역할 | 볼 수 있는 것 |
|---|---|---|
| admin01 | 관리자 | 학교 목록·등록, 계정 발급·관리, 모든 학교 성적표·통계·이력 (조회만) |
| tea_dj001 / tea_dj002 / tea_dj003 | 교사 (대전고 / 충남고 / 유성고) | 자기 학교 성적표, 학생 등록·수정·삭제, 통계, 이력, 검색 |
| stu_01 ~ stu_30 | 학생 (01~10 대전고, 11~20 충남고, 21~30 유성고) | 내 성적 |

데이터(`data/schools.csv`, `data/students.csv`)·아이디 체계: DB 담당 김현준. 학교 3개 × 학생 10명.
학생 계정 `stu_NN`의 NN은 DB가 매긴 학생 번호(bunho)입니다.

## 라우트

| 라우트 | 방식 | 권한 | 내용 |
|---|---|---|---|
| `/` | GET | 모두 | 로그인 전: 첫 화면(메인 배경) / 로그인 후: 역할별 첫 화면으로 이동 |
| `/login` | GET·POST | 모두 | 로그인 (아이디 저장하기, 빈칸 검사, 로그인 시 세션 새로 시작) |
| `/logout` | POST | 모두 | 로그아웃 (메뉴의 버튼 폼, csrf_token 포함) |
| `/school_list` | GET | 관리자 | 학교목록조회 |
| `/school_insert` | GET·POST | 관리자 | 학교 등록 |
| `/user_list` | GET | 관리자 | 계정 목록 + 계정 발급 폼 |
| `/user_insert` | POST | 관리자 | 계정 발급 (교사·학생·관리자) |
| `/user_reset`, `/user_delete` | POST | 관리자 | 비밀번호 초기화, 계정 삭제 |
| `/school_rank` | GET | 관리자·교사 | 메뉴 '학교별 성적조회' → 성적표로 이동 |
| `/sungjuk_call/<schoolcode>` | GET | 관리자·교사 | 학교별 성적표 (등수 순, 조회 전용) |
| `/sungjuk_insert` | GET·POST | 교사 | 학생 등록 |
| `/sungjuk_update` | GET·POST | 교사 | GET: 수정할 학생 목록 / bunho만 → 수정 폼 / mode=save → 저장 |
| `/sungjuk_delete` | GET·POST | 교사 | GET: 삭제할 학생 목록 / POST: 삭제 |
| `/subject_rank`, `/subject_rank/<schoolcode>` | GET | 관리자·교사 | 과목별 성적조회 (과목 제목 클릭 정렬, 이름 검색) |
| `/stats/<schoolcode>` | GET | 관리자·교사 | 과목별 합계·평균·최고·최저 |
| `/history/<schoolcode>` | GET | 관리자·교사 | 수정·삭제 이력 |
| `/my_sungjuk` | GET | 학생 | 내 성적 |
| `/_search?schoolcode=&name=` | GET (JSON) | 관리자·교사 | 이름 검색 (AJAX) |

## 정해 둔 규칙

- 총점·평균·학점: 저장할 때 Python `service/grade.py`가 계산 (성적 프로그램 코드 재사용)
- 등수: 학교마다 달라서 `student_rank` 뷰가 `RANK()`로 계산 (MySQL 8.0 이상)
- 프로시저 결과 코드: 1 = 성공, 2 = 대상 없음, -1 = 에러
- 모든 POST 폼에 `csrf_token`, 계정 비밀번호는 해시로 저장

## DB 변경 반영하기

- `procedures.sql`은 `DROP PROCEDURE IF EXISTS` 후 다시 만드는 방식이라 **다시 실행해도 데이터가 지워지지 않습니다.** 프로시저가 추가·변경되면 이 파일만 다시 실행하세요.
- `schema.sql`은 테이블을 지우고(DROP) 새로 만들므로 **다시 실행하면 데이터가 모두 사라집니다.** 구조 변경은 `ALTER TABLE`로 하세요.

## 계정 발급

관리자로 로그인 → **계정 관리**에서 역할·학교·(학생이면) 연결할 학생을 고르고 아이디·초기 비밀번호를 입력합니다.
비밀번호는 서버에서 해시로 바꿔 저장하므로 `make_password.py`는 SQL로 직접 넣을 때만 필요합니다.
