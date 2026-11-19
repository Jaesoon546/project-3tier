from werkzeug.security import check_password_hash
from dao.db import select_proc_one


def login(login_id, password):
    """아이디·비밀번호가 맞으면 계정 정보(dict), 틀리면 None"""
    user = select_proc_one("user_select", (login_id,))
    if user and check_password_hash(user['password_hash'], password):
        user.pop('password_hash')   # 세션에는 해시도 넣지 않음
        return user
    return None
