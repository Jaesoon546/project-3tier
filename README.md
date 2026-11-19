# 학교별 성적관리 홈페이지 — 1차 팀 프로젝트

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
│   └── grade.py            # Student 클래스 — 총점·평균·학점, 점수 검사
├── templates/              # 모두 base.html 상속
├── static/js/              # form_check.js (폼 검사), search.js (AJAX 검색)
└── sql/                    # schema → procedures → school_data → student_data → user_data 순서로 실행
```

## 실행 방법 (WSL2 Ubuntu)

```bash
# 1) 패키지 설치
pip install -r requirements.txt

# 2) DB 만들기 — HeidiSQL에서 sql/ 파일을 아래 순서대로 실행
#    schema.sql → procedures.sql → school_data.sql → student_data.sql → user_data.sql

# 3) 접속 정보는 환경변수로 (코드·문서에 비밀번호를 적지 않음)
export DB_HOST=<DB 서버 IP>
export DB_USER=root
export DB_PASSWORD=<비밀번호>
export SECRET_KEY=<아무 긴 문자열>

# 4) 서버 실행
python flaskserver.py      # http://127.0.0.1:5000
```

## 테스트 계정 (비밀번호 모두 `test1234`)

| 아이디 | 역할 | 볼 수 있는 것 |
|---|---|---|
| admin | 관리자 | 학교 목록·등록, 모든 학교 성적표·통계·이력 (조회만) |
| teacher1 / teacher2 / teacher3 | 교사 | 자기 학교 성적표, 학생 등록·수정·삭제, 통계, 이력, 검색 |
| student1 / student6 / student11 | 학생 | 내 성적 |

## 라우트

| 라우트 | 방식 | 권한 | 내용 |
|---|---|---|---|
| `/login`, `/logout` | GET·POST | 모두 | 로그인 |
| `/school_list` | GET·POST | 관리자 | 학교 목록·등록 |
| `/sungjuk_call/<schoolcode>` | GET | 관리자·교사 | 학교별 성적표 (등수 순) |
| `/sungjuk_insert` | GET·POST | 교사 | 학생 등록 |
| `/sungjuk_update` | POST | 교사 | bunho만 → 수정 폼, mode=save → 저장 |
| `/sungjuk_delete` | POST | 교사 | 학생 삭제 |
| `/stats/<schoolcode>` | GET | 관리자·교사 | 과목별 합계·평균·최고·최저 |
| `/history/<schoolcode>` | GET | 관리자·교사 | 수정·삭제 이력 |
| `/my_sungjuk` | GET | 학생 | 내 성적 |
| `/_search?schoolcode=&name=` | GET (JSON) | 관리자·교사 | 이름 검색 (AJAX) |

## 정해 둔 규칙

- 총점·평균·학점: 저장할 때 Python `service/grade.py`가 계산 (성적 프로그램 코드 재사용)
- 등수: 학교마다 달라서 `student_rank` 뷰가 `RANK()`로 계산 (MySQL 8.0 이상)
- 프로시저 결과 코드: 1 = 성공, 2 = 대상 없음, -1 = 에러
- 모든 POST 폼에 `csrf_token`, 계정 비밀번호는 해시로 저장
