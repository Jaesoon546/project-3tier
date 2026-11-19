"""새 계정의 비밀번호 해시 만들기
사용법: python make_password.py 내비밀번호
출력된 값을 user_data.sql의 password_hash 자리에 넣으세요."""
import sys
from werkzeug.security import generate_password_hash

if len(sys.argv) != 2:
    print("사용법: python make_password.py <비밀번호>")
else:
    print(generate_password_hash(sys.argv[1]))
