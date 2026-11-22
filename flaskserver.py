"""학교별 성적관리 홈페이지 — Flask 서버 (3tier: 브라우저 → Flask → MySQL)
실행: python flaskserver.py  →  http://127.0.0.1:5000
"""
import os
from functools import wraps

from flask import Flask, request, render_template, redirect, url_for, session, flash, jsonify, abort
from flask_wtf.csrf import CSRFProtect

from dao import school, student, user
from service.grade import student_from_form
from service.account import account_from_form, check_password, ROLES

app = Flask(__name__)
# 세션 암호화 키 — 실제로는 환경변수로 넣으세요 (export SECRET_KEY=...)
# os.urandom을 쓰면 서버가 재시작될 때마다 로그인이 풀려서 개발용 기본값을 둠
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-only-change-me')
CSRFProtect(app)   # 모든 POST 폼에 csrf_token 필요

RESULT_MESSAGE = {1: '완료되었습니다.', 2: '대상을 찾을 수 없습니다.', -1: '에러가 발생했습니다.'}


# ===================== 로그인·권한 =====================

def login_required(*roles):
    """로그인 + 권한 검사. @login_required('admin', 'teacher') 처럼 사용"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if 'user' not in session:
                flash('로그인이 필요합니다.')
                return redirect(url_for('login'))
            if roles and session['user']['role'] not in roles:
                flash('권한이 없습니다.')
                return redirect(url_for('home'))
            return func(*args, **kwargs)
        return wrapper
    return decorator


def check_school(schoolcode):
    """교사는 자기 학교만 볼 수 있음 (관리자는 전부)"""
    me = session['user']
    if me['role'] == 'teacher' and me['schoolcode'] != schoolcode:
        abort(403)


@app.route('/')
def home():
    """역할별 첫 화면으로 보냄"""
    me = session.get('user')
    if not me:
        return render_template('index.html')   # 로그인 전: 메인 배경 첫 화면
    if me['role'] == 'admin':
        return redirect(url_for('school_list'))
    if me['role'] == 'teacher':
        return redirect(url_for('sungjuk_call', schoolcode=me['schoolcode']))
    return redirect(url_for('my_sungjuk'))


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        login_id = request.form.get('login_id', '').strip()
        password = request.form.get('password', '')
        # 빈칸이면 DB까지 가지 않음 (아이디어: 박지희)
        if not login_id or not password:
            flash('아이디와 비밀번호를 입력하세요.')
            return render_template('login.html')
        found = user.login(login_id, password)
        if found:
            # 로그인 전 세션을 비우고 새로 저장 — 이전 사용자의 값이 남지 않게 (아이디어: 박지희)
            session.clear()
            session['user'] = found
            flash(f"{found['name']}님 환영합니다.")
            return redirect(url_for('home'))
        flash('아이디 또는 비밀번호가 틀렸습니다.')
    return render_template('login.html')


@app.route('/logout', methods=['POST'])
def logout():
    """POST만 받음 — 다른 사이트의 링크나 이미지로 몰래 로그아웃시키지 못하게 (CSRF 토큰 검사, 아이디어: 박지희)"""
    session.clear()
    return redirect(url_for('home'))


# ===================== 학교 (관리자) =====================

@app.route('/school_list')
@login_required('admin')
def school_list():
    return render_template('school_list.html', object_list=school.getSchoolList())


@app.route('/school_insert', methods=['GET', 'POST'])
@login_required('admin')
def school_insert():
    """학교 등록 화면 (디자인: 김상민 school_insert.html)"""
    if request.method == 'POST':
        code = request.form.get('schoolcode', '').strip()
        name = request.form.get('schoolname', '').strip()
        address = request.form.get('address', '').strip()
        if not code or not name:
            flash('학교코드와 학교명을 입력하세요.')
            return render_template('school_insert.html', form=request.form)
        result = school.insertSchool(code, name, address)
        if result != 1:
            flash('등록 실패 (학교코드 중복 등)')
            return render_template('school_insert.html', form=request.form)
        flash(f'{name}을(를) 등록했습니다.')
        return redirect(url_for('school_list'))
    return render_template('school_insert.html', form={})


# ===================== 계정 발급 (관리자) =====================

USER_RESULT_MESSAGE = {
    1: '완료되었습니다.',
    2: '학교 또는 학생 번호가 맞지 않습니다.',
    3: '이미 계정이 있는 학생입니다.',
    -1: '에러가 발생했습니다. (아이디 중복 등)',
}


@app.route('/user_list')
@login_required('admin')
def user_list():
    return render_template('user_list.html', object_list=user.getUserList(),
                           school_list=school.getSchoolList(), roles=ROLES, form={})


@app.route('/user_insert', methods=['POST'])
@login_required('admin')
def user_insert():
    account, error = account_from_form(request.form)
    if error:
        flash(error)
        # 입력한 값은 다시 채워서 보여줌 (비밀번호 제외)
        return render_template('user_list.html', object_list=user.getUserList(),
                               school_list=school.getSchoolList(), roles=ROLES, form=request.form)
    result = user.insertUser(**account)
    if result == 1:
        flash(f"{account['login_id']} 계정을 발급했습니다.")
        return redirect(url_for('user_list'))
    flash(USER_RESULT_MESSAGE.get(result, '알 수 없음'))
    return render_template('user_list.html', object_list=user.getUserList(),
                           school_list=school.getSchoolList(), roles=ROLES, form=request.form)


@app.route('/user_delete', methods=['POST'])
@login_required('admin')
def user_delete():
    user_id = request.form.get('id', type=int)
    if user_id == session['user']['id']:
        flash('지금 로그인한 계정은 삭제할 수 없습니다.')
    else:
        flash(USER_RESULT_MESSAGE.get(user.deleteUser(user_id), '알 수 없음'))
    return redirect(url_for('user_list'))


@app.route('/user_reset', methods=['POST'])
@login_required('admin')
def user_reset():
    """비밀번호 초기화 — 관리자가 정한 새 비밀번호로 바꿈"""
    new_password = request.form.get('password', '')
    error = check_password(new_password)
    if error:
        flash(error)
    else:
        result = user.resetPassword(request.form.get('id', type=int), new_password)
        flash('비밀번호를 바꿨습니다.' if result == 1 else USER_RESULT_MESSAGE.get(result, '알 수 없음'))
    return redirect(url_for('user_list'))


# ===================== 성적 (관리자·교사) =====================

@app.route('/sungjuk_call/<schoolcode>')
@login_required('admin', 'teacher')
def sungjuk_call(schoolcode):
    check_school(schoolcode)
    info = school.getSchool(schoolcode)
    if info is None:
        abort(404)
    # 관리자는 학교 선택 드롭다운으로 다른 학교 성적표로 이동할 수 있음
    school_list = school.getSchoolList() if session['user']['role'] == 'admin' else []
    return render_template('sungjuk.html', school=info, school_list=school_list,
                           object_list=student.getSungjuk(schoolcode))


def default_schoolcode():
    """메뉴에서 학교를 고르지 않고 들어올 때: 교사는 자기 학교, 관리자는 목록의 첫 학교"""
    me = session['user']
    if me['role'] == 'teacher':
        return me['schoolcode']
    schools = school.getSchoolList()
    return schools[0]['schoolcode'] if schools else None


@app.route('/school_rank')
@login_required('admin', 'teacher')
def school_rank():
    """메뉴 '학교별 성적조회' → 학교별 성적표로 이동"""
    code = default_schoolcode()
    if code is None:
        flash('등록된 학교가 없습니다.')
        return redirect(url_for('home'))
    return redirect(url_for('sungjuk_call', schoolcode=code))


@app.route('/subject_rank')
@login_required('admin', 'teacher')
def subject_rank_first():
    """메뉴 '과목별 성적조회' → 과목별 성적조회로 이동"""
    code = default_schoolcode()
    if code is None:
        flash('등록된 학교가 없습니다.')
        return redirect(url_for('home'))
    return redirect(url_for('subject_rank', schoolcode=code))


@app.route('/subject_rank/<schoolcode>')
@login_required('admin', 'teacher')
def subject_rank(schoolcode):
    """과목별 성적조회 — 과목 제목을 누르면 그 과목 순으로 정렬, 이름 검색 (디자인: 김상민, 정렬은 브라우저 JS)"""
    check_school(schoolcode)
    info = school.getSchool(schoolcode)
    if info is None:
        abort(404)
    school_list = school.getSchoolList() if session['user']['role'] == 'admin' else []
    return render_template('subject_rank.html', school=info, school_list=school_list,
                           object_list=student.getSungjuk(schoolcode))


@app.route('/sungjuk_insert', methods=['GET', 'POST'])
@login_required('teacher')
def sungjuk_insert():
    schoolcode = session['user']['schoolcode']
    if request.method == 'POST':
        new_student, error = student_from_form(request.form)
        if error:
            flash(error)
            return render_template('sungjuk_form.html', mode='insert', sungjuk=request.form)
        result = student.insertStudent(new_student, schoolcode)
        flash(RESULT_MESSAGE.get(result, '알 수 없음'))
        return redirect(url_for('sungjuk_call', schoolcode=schoolcode))
    return render_template('sungjuk_form.html', mode='insert', sungjuk={})


@app.route('/sungjuk_update', methods=['GET', 'POST'])
@login_required('teacher')
def sungjuk_update():
    """GET: 수정할 학생 목록 (디자인: 김상민 sungjuk_update.html)
    POST: 목록의 [수정] → 폼 보여주기, 폼의 [저장] (mode=save) → DB 수정"""
    if request.method == 'GET':
        return render_template('sungjuk_update.html',
                               object_list=student.getSungjuk(session['user']['schoolcode']))
    bunho = request.form.get('bunho', type=int)
    target = student.getStudent(bunho)
    if target is None:
        flash(RESULT_MESSAGE[2])
        return redirect(url_for('home'))
    check_school(target['schoolcode'])

    if request.form.get('mode') != 'save':
        return render_template('sungjuk_form.html', mode='update', sungjuk=target)

    new_student, error = student_from_form(request.form)
    if error:
        flash(error)
        return render_template('sungjuk_form.html', mode='update', sungjuk=request.form)
    result = student.updateStudent(bunho, new_student)
    flash(RESULT_MESSAGE.get(result, '알 수 없음'))
    return redirect(url_for('sungjuk_update'))


@app.route('/sungjuk_delete', methods=['GET', 'POST'])
@login_required('teacher')
def sungjuk_delete():
    """GET: 삭제할 학생 목록 (디자인: 김상민 sungjuk_delete.html), POST: 삭제"""
    if request.method == 'GET':
        return render_template('sungjuk_delete.html',
                               object_list=student.getSungjuk(session['user']['schoolcode']))
    bunho = request.form.get('bunho', type=int)
    target = student.getStudent(bunho)
    if target is None:
        flash(RESULT_MESSAGE[2])
        return redirect(url_for('home'))
    check_school(target['schoolcode'])
    result = student.deleteStudent(bunho)
    flash(RESULT_MESSAGE.get(result, '알 수 없음'))
    return redirect(url_for('sungjuk_delete'))


@app.route('/stats/<schoolcode>')
@login_required('admin', 'teacher')
def stats(schoolcode):
    check_school(schoolcode)
    info = school.getSchool(schoolcode)
    if info is None:   # 없는 학교 코드 (아이디어: 박지희)
        abort(404)
    return render_template('stats.html', school=info,
                           object_list=student.getStats(schoolcode))


@app.route('/history/<schoolcode>')
@login_required('admin', 'teacher')
def history(schoolcode):
    check_school(schoolcode)
    info = school.getSchool(schoolcode)
    if info is None:   # 없는 학교 코드 (아이디어: 박지희)
        abort(404)
    return render_template('history.html', school=info,
                           object_list=student.getHistory(schoolcode))


# ===================== 학생 =====================

@app.route('/my_sungjuk')
@login_required('student')
def my_sungjuk():
    me = student.getStudent(session['user']['bunho'])
    return render_template('my_sungjuk.html', sungjuk=me)


# ===================== JSON (AJAX) =====================

@app.route('/_search')
@login_required('admin', 'teacher')
def search():
    """이름 검색 — AJAX 실습(/_add_numbers)처럼 JSON으로 돌려줌"""
    schoolcode = request.args.get('schoolcode', '').strip()
    name = request.args.get('name', '').strip()
    # 학교 코드 확인 — 화면이 아닌 JS가 받으므로 JSON 에러로 돌려줌 (아이디어: 박지희)
    if not schoolcode:
        return jsonify(error='학교 코드가 필요합니다.'), 400
    check_school(schoolcode)
    if school.getSchool(schoolcode) is None:
        return jsonify(error='존재하지 않는 학교입니다.'), 404
    rows = student.searchStudent(schoolcode, name)
    for row in rows:   # Decimal은 JSON으로 못 바꿔서 float로 변환
        row['average'] = float(row['average'])
    return jsonify(result=rows)


@app.errorhandler(403)
def forbidden(e):
    flash('다른 학교의 정보는 볼 수 없습니다.')
    return redirect(url_for('home'))


if __name__ == '__main__':
    app.run('0.0.0.0', port=5000, debug=True, use_reloader=True)
