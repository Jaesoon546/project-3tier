"""테스트 데이터 넣기 — 학교 · 학생 · 계정
데이터 파일에는 점수만 적고, 총점·평균·학점은 웹에서 등록할 때와 똑같이
service/grade.py가 계산해서 프로시저로 저장합니다. (계산값을 손으로 적지 않음)

사용법 (DB가 비어 있을 때):
    source .venv/bin/activate && source .env
    python seed_data.py

이미 데이터가 있으면 HeidiSQL에서 sql/reset_data.sql을 먼저 실행하세요.
데이터 원본: data/schools.csv, data/students.csv (DB 담당: 김현준)
"""
import csv
import os
import sys

from dao import school, student, user
from service.grade import student_from_form

TEST_PASSWORD = 'test1234'   # 테스트 계정 공용 비밀번호 (DB에는 해시로 저장됨)
HERE = os.path.dirname(os.path.abspath(__file__))


def read_csv(name):
    with open(os.path.join(HERE, 'data', name), encoding='utf-8') as f:
        return list(csv.DictReader(f))


def check(result, what):
    """프로시저 결과 코드 확인 — 1이 아니면 멈춤"""
    if result != 1:
        sys.exit(f'실패: {what} (결과 코드 {result})')


def main():
    if school.getSchoolList():
        sys.exit('DB에 이미 학교가 있습니다. sql/reset_data.sql을 먼저 실행하세요.')

    # 1) 학교
    schools = read_csv('schools.csv')
    for row in schools:
        check(school.insertSchool(row['schoolcode'], row['schoolname'], row['address']),
              f"학교 {row['schoolname']}")

    # 2) 학생 — 웹의 학생 등록과 같은 검사·계산을 거침
    students = read_csv('students.csv')
    for row in students:
        new_student, error = student_from_form(row)
        if error:
            sys.exit(f"데이터 오류: {row['name']} — {error}")
        check(student.insertStudent(new_student, row['schoolcode']), f"학생 {row['name']}")

    # 3) 계정 — 관리자 1, 학교별 교사 1, 학생마다 1 (stu_번호)
    check(user.insertUser('admin01', TEST_PASSWORD, '관리자', 'admin'), '관리자 계정')
    for row in schools:
        short = row['schoolname'].replace('등학교', '')   # 대전고등학교 → 대전고
        check(user.insertUser(f"tea_{row['schoolcode'].lower()}", TEST_PASSWORD, f'{short} 교사',
                              'teacher', row['schoolcode']), f"교사 계정 {row['schoolcode']}")
    for row in students:
        # DB가 매긴 번호를 이름으로 찾아서 연결 (같은 학교에 같은 이름이 있으면 멈춤)
        found = [s for s in student.searchStudent(row['schoolcode'], row['name']) if s['name'] == row['name']]
        if len(found) != 1:
            sys.exit(f"학생 번호를 하나로 찾을 수 없음: {row['schoolcode']} {row['name']}")
        bunho = found[0]['bunho']
        check(user.insertUser(f'stu_{bunho:02d}', TEST_PASSWORD, row['name'], 'student',
                              row['schoolcode'], bunho), f"학생 계정 {row['name']}")

    print(f'완료: 학교 {len(schools)}개, 학생 {len(students)}명, '
          f'계정 {1 + len(schools) + len(students)}개 (비밀번호 {TEST_PASSWORD})')


if __name__ == '__main__':
    main()
