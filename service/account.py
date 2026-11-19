"""계정 발급 폼 검사 — 브라우저(static/js/user_form.js)에서도 검사하지만 서버에서 한 번 더 확인"""
import re

ROLES = {'admin': '관리자', 'teacher': '교사', 'student': '학생'}
LOGIN_ID_RULE = re.compile(r'^[A-Za-z0-9_]{4,30}$')
PASSWORD_MIN = 8


def check_password(password):
    """비밀번호 규칙 — 맞으면 None, 틀리면 에러 메시지"""
    if len(password or '') < PASSWORD_MIN:
        return f'비밀번호는 {PASSWORD_MIN}자 이상이어야 합니다.'
    return None


def account_from_form(form):
    """request.form → (계정 dict, 에러 메시지). 에러가 없으면 메시지는 None"""
    login_id = (form.get('login_id') or '').strip()
    password = form.get('password') or ''
    name = (form.get('name') or '').strip()
    role = form.get('role') or ''
    schoolcode = (form.get('schoolcode') or '').strip() or None
    bunho = form.get('bunho') or None

    if not LOGIN_ID_RULE.match(login_id):
        return None, '아이디는 영문·숫자·_ 로 4~30자여야 합니다.'
    error = check_password(password)
    if error:
        return None, error
    if not name or len(name) > 20:
        return None, '이름은 1~20자로 입력하세요.'
    if role not in ROLES:
        return None, '역할을 선택하세요.'
    if role in ('teacher', 'student') and not schoolcode:
        return None, '소속 학교를 선택하세요.'
    if role == 'student':
        try:
            bunho = int(bunho)
        except (TypeError, ValueError):
            return None, '학생 계정은 연결할 학생을 선택하세요.'
    else:
        bunho = None
    if role == 'admin':
        schoolcode = None

    return dict(login_id=login_id, password=password, name=name,
                role=role, schoolcode=schoolcode, bunho=bunho), None
