from werkzeug.security import check_password_hash, generate_password_hash
from dao.db import select_proc, select_proc_one, result_proc


def login(login_id, password):
    """아이디·비밀번호가 맞으면 계정 정보(dict), 틀리면 None"""
    user = select_proc_one("user_select", (login_id,))
    if user and check_password_hash(user['password_hash'], password):
        user.pop('password_hash')   # 세션에는 해시도 넣지 않음
        return user
    return None


def getUserList():
    """계정 목록 (비밀번호 해시 없음)"""
    return select_proc("user_select_all")


def insertUser(login_id, password, name, role, schoolcode=None, bunho=None):
    """계정 발급 — 비밀번호는 여기서 해시로 바꿔서 저장
    결과: 1 = 성공, 2 = 학교/학생 번호 불일치, 3 = 이미 계정이 있는 학생, -1 = 에러(아이디 중복 등)"""
    return result_proc("user_insert", (
        login_id, generate_password_hash(password), name, role, schoolcode, bunho, 0))


def deleteUser(user_id):
    return result_proc("user_delete", (user_id, 0))


def resetPassword(user_id, new_password):
    return result_proc("user_reset_password", (user_id, generate_password_hash(new_password), 0))
