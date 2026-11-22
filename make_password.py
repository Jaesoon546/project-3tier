"""새 계정의 비밀번호 해시 만들기
사용법: python make_password.py 내비밀번호
HeidiSQL에서 계정을 직접 넣거나 비밀번호 해시를 바꿀 때 password_hash 자리에 넣으세요.
(보통은 관리자 화면의 계정 발급·비밀번호 초기화를 쓰면 됩니다.)"""
import sys
from werkzeug.security import generate_password_hash

if len(sys.argv) != 2:
    print("사용법: python make_password.py <비밀번호>")
else:
    print(generate_password_hash(sys.argv[1]))
