-- 로그인 계정 (테스트용) — 모든 계정의 비밀번호: test1234
-- password_hash는 werkzeug generate_password_hash('test1234')로 만든 값입니다.
-- 새 계정은 python make_password.py <비밀번호> 로 해시를 만들어 넣으세요.
-- 학생 계정의 bunho는 student_data.sql을 순서대로 넣었을 때의 번호입니다.
USE school_sungjuk;

INSERT INTO user_data(login_id, password_hash, name, role, schoolcode, bunho) VALUES ('admin', 'scrypt:32768:8:1$IYdJDdtAmRNPfTt3$00b64890d67093314dde93871a023e61291206088fc18c8e33090373160cb1f82a5374f7a01911603a3fe6a4146b4a31d5d86d21d7d6359c009dfd2e0fc0f1c0', '관리자', 'admin', NULL, NULL);
INSERT INTO user_data(login_id, password_hash, name, role, schoolcode, bunho) VALUES ('teacher1', 'scrypt:32768:8:1$IYdJDdtAmRNPfTt3$00b64890d67093314dde93871a023e61291206088fc18c8e33090373160cb1f82a5374f7a01911603a3fe6a4146b4a31d5d86d21d7d6359c009dfd2e0fc0f1c0', '대전가상고 교사', 'teacher', 'DJ00000001', NULL);
INSERT INTO user_data(login_id, password_hash, name, role, schoolcode, bunho) VALUES ('teacher2', 'scrypt:32768:8:1$IYdJDdtAmRNPfTt3$00b64890d67093314dde93871a023e61291206088fc18c8e33090373160cb1f82a5374f7a01911603a3fe6a4146b4a31d5d86d21d7d6359c009dfd2e0fc0f1c0', '한밭가상고 교사', 'teacher', 'DJ00000002', NULL);
INSERT INTO user_data(login_id, password_hash, name, role, schoolcode, bunho) VALUES ('teacher3', 'scrypt:32768:8:1$IYdJDdtAmRNPfTt3$00b64890d67093314dde93871a023e61291206088fc18c8e33090373160cb1f82a5374f7a01911603a3fe6a4146b4a31d5d86d21d7d6359c009dfd2e0fc0f1c0', '서울가상고 교사', 'teacher', 'SE00000001', NULL);
INSERT INTO user_data(login_id, password_hash, name, role, schoolcode, bunho) VALUES ('student1', 'scrypt:32768:8:1$IYdJDdtAmRNPfTt3$00b64890d67093314dde93871a023e61291206088fc18c8e33090373160cb1f82a5374f7a01911603a3fe6a4146b4a31d5d86d21d7d6359c009dfd2e0fc0f1c0', '김민준', 'student', 'DJ00000001', 1);
INSERT INTO user_data(login_id, password_hash, name, role, schoolcode, bunho) VALUES ('student6', 'scrypt:32768:8:1$IYdJDdtAmRNPfTt3$00b64890d67093314dde93871a023e61291206088fc18c8e33090373160cb1f82a5374f7a01911603a3fe6a4146b4a31d5d86d21d7d6359c009dfd2e0fc0f1c0', '강서윤', 'student', 'DJ00000002', 6);
INSERT INTO user_data(login_id, password_hash, name, role, schoolcode, bunho) VALUES ('student11', 'scrypt:32768:8:1$IYdJDdtAmRNPfTt3$00b64890d67093314dde93871a023e61291206088fc18c8e33090373160cb1f82a5374f7a01911603a3fe6a4146b4a31d5d86d21d7d6359c009dfd2e0fc0f1c0', '한주원', 'student', 'SE00000001', 11);
