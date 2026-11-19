import os
import pymysql

# 접속 정보는 코드에 직접 쓰지 않고 환경변수로 받습니다 (공개 저장소 보호용).
#   export DB_HOST=<서버 IP>  DB_USER=<계정>  DB_PASSWORD=<비밀번호>
DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
DB_PORT = int(os.environ.get("DB_PORT", "3306"))
DB_USER = os.environ.get("DB_USER", "root")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")
DB_NAME = os.environ.get("DB_NAME", "school_sungjuk")


def getConnection():
    # DictCursor : 결과를 dict로 받아서 템플릿에서 row['name'] 처럼 이름으로 꺼냄
    return pymysql.connect(host=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASSWORD,
                           database=DB_NAME, charset='utf8mb4', autocommit=True,
                           cursorclass=pymysql.cursors.DictCursor)


def select_proc(proc_name, args=()):
    """조회 프로시저 호출 → 결과 행 목록(list of dict)"""
    conn = getConnection()
    try:
        with conn.cursor() as cur:
            cur.callproc(proc_name, args)
            return list(cur.fetchall())
    finally:
        conn.close()


def select_proc_one(proc_name, args=()):
    """조회 프로시저 호출 → 한 행(dict) 또는 None"""
    rows = select_proc(proc_name, args)
    return rows[0] if rows else None


def result_proc(proc_name, args):
    """OUT 파라미터가 마지막에 있는 프로시저 호출 → 결과 코드
    1 = 성공, 2 = 대상 없음, -1 = 에러 (수업 코드와 같은 규칙)
    args에는 OUT 자리에 0을 넣어서 보냄"""
    conn = getConnection()
    try:
        with conn.cursor() as cur:
            cur.callproc(proc_name, args)
            out_index = len(args) - 1
            cur.execute(f"SELECT @_{proc_name}_{out_index} AS result")
            row = cur.fetchone()
            return row['result'] if row else -1
    finally:
        conn.close()
