"""성적 계산 — 팀과제 성적 프로그램(20261111_team2_grade_program)의 Student 클래스를 옮겨 옴
DB에 저장하기 전에 총점·평균·학점을 여기서 계산합니다.
등수는 학교마다 달라서 DB의 student_rank 뷰가 계산합니다."""


class Student:

    def __init__(self, name='', kor=0, eng=0, mat=0):
        self.name = name
        self.kor = kor
        self.eng = eng
        self.mat = mat

    def total(self):
        return self.kor + self.eng + self.mat

    def avg(self):
        return self.total() / 3

    def grade(self):
        avg = self.avg()
        if avg >= 90: return 'A'
        elif avg >= 80: return 'B'
        elif avg >= 70: return 'C'
        elif avg >= 60: return 'D'
        else: return 'F'


def validate_score(value):
    """폼에서 받은 점수 문자열 → 0~100 정수, 잘못되면 None
    (성적 프로그램의 input_score와 같은 검사, 서버에서 한 번 더 확인)"""
    try:
        score = int(value)
    except (TypeError, ValueError):
        return None
    return score if 0 <= score <= 100 else None


def student_from_form(form):
    """request.form → (Student, 에러 메시지). 에러가 없으면 메시지는 None"""
    name = (form.get('name') or '').strip()
    if not name:
        return None, '이름을 입력하세요.'
    scores = {}
    for key, label in (('kor', '국어'), ('eng', '영어'), ('mat', '수학')):
        score = validate_score(form.get(key))
        if score is None:
            return None, f'{label} 점수는 0~100 사이 숫자로 입력하세요.'
        scores[key] = score
    return Student(name, scores['kor'], scores['eng'], scores['mat']), None
