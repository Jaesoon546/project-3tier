"""학교별 성적관리 홈페이지 — Flask 서버 (3tier: 브라우저 → Flask → MySQL)
실행: python flaskserver.py  →  http://127.0.0.1:5000
"""
import os
from functools import wraps

from flask import Flask, request, render_template, redirect, url_for, session, flash, jsonify, abort
from flask_wtf.csrf import CSRFProtect

from dao import school, student, user
from service.grade import student_from_form

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
        return redirect(url_for('login'))
    if me['role'] == 'admin':
        return redirect(url_for('school_list'))
    if me['role'] == 'teacher':
        return redirect(url_for('sungjuk_call', schoolcode=me['schoolcode']))
    return redirect(url_for('my_sungjuk'))


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        found = user.login(request.form.get('login_id', ''), request.form.get('password', ''))
        if found:
            session['user'] = found
            flash(f"{found['name']}님 환영합니다.")
            return redirect(url_for('home'))
        flash('아이디 또는 비밀번호가 틀렸습니다.')
    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


# ===================== 학교 (관리자) =====================

@app.route('/school_list', methods=['GET', 'POST'])
@login_required('admin')
def school_list():
    if request.method == 'POST':   # 학교 등록
        code = request.form.get('schoolcode', '').strip()
        name = request.form.get('schoolname', '').strip()
        address = request.form.get('address', '').strip()
        if not code or not name:
            flash('학교코드와 학교명을 입력하세요.')
        else:
            result = school.insertSchool(code, name, address)
            flash('학교가 등록되었습니다.' if result == 1 else '등록 실패 (학교코드 중복 등)')
        return redirect(url_for('school_list'))
    return render_template('school_list.html', object_list=school.getSchoolList())


# ===================== 성적 (관리자·교사) =====================

@app.route('/sungjuk_call/<schoolcode>')
@login_required('admin', 'teacher')
def sungjuk_call(schoolcode):
    check_school(schoolcode)
    info = school.getSchool(schoolcode)
    if info is None:
        abort(404)
    return render_template('sungjuk.html', school=info, object_list=student.getSungjuk(schoolcode))


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


@app.route('/sungjuk_update', methods=['POST'])
@login_required('teacher')
def sungjuk_update():
    """성적표의 [수정] → 폼 보여주기, 폼의 [저장] (mode=save) → DB 수정"""
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
    return redirect(url_for('sungjuk_call', schoolcode=target['schoolcode']))


@app.route('/sungjuk_delete', methods=['POST'])
@login_required('teacher')
def sungjuk_delete():
    bunho = request.form.get('bunho', type=int)
    target = student.getStudent(bunho)
    if target is None:
        flash(RESULT_MESSAGE[2])
        return redirect(url_for('home'))
    check_school(target['schoolcode'])
    result = student.deleteStudent(bunho)
    flash(RESULT_MESSAGE.get(result, '알 수 없음'))
    return redirect(url_for('sungjuk_call', schoolcode=target['schoolcode']))


@app.route('/stats/<schoolcode>')
@login_required('admin', 'teacher')
def stats(schoolcode):
    check_school(schoolcode)
    return render_template('stats.html', school=school.getSchool(schoolcode),
                           object_list=student.getStats(schoolcode))


@app.route('/history/<schoolcode>')
@login_required('admin', 'teacher')
def history(schoolcode):
    check_school(schoolcode)
    return render_template('history.html', school=school.getSchool(schoolcode),
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
    schoolcode = request.args.get('schoolcode', '')
    name = request.args.get('name', '')
    check_school(schoolcode)
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
