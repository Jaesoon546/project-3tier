-- 로그인 계정 (아이디 체계: DB 담당 김현준) — 모든 계정의 비밀번호: test1234
-- password_hash는 werkzeug generate_password_hash('test1234')로 만든 값입니다.
-- 비밀번호를 바꾸려면 python make_password.py <비밀번호> 로 해시를 만들어 @pw_hash를 바꾸세요.
-- 학생 계정 stu_NN 의 bunho = NN (student_data.sql의 bunho)
USE school_sungjuk;

SET @pw_hash = 'scrypt:32768:8:1$IYdJDdtAmRNPfTt3$00b64890d67093314dde93871a023e61291206088fc18c8e33090373160cb1f82a5374f7a01911603a3fe6a4146b4a31d5d86d21d7d6359c009dfd2e0fc0f1c0';

INSERT INTO user_data(login_id, password_hash, name, role, schoolcode, bunho) VALUES
-- 관리자 1명
('admin01', @pw_hash, '관리자', 'admin', NULL, NULL),
-- 학교별 교사 1명
('tea_dj001', @pw_hash, '대전고 교사', 'teacher', 'DJ001', NULL),
('tea_dj002', @pw_hash, '충남고 교사', 'teacher', 'DJ002', NULL),
('tea_dj003', @pw_hash, '유성고 교사', 'teacher', 'DJ003', NULL),
-- 학생 DJ001
('stu_01', @pw_hash, '홍만우', 'student', 'DJ001', 1),
('stu_02', @pw_hash, '김종수', 'student', 'DJ001', 2),
('stu_03', @pw_hash, '곽신석', 'student', 'DJ001', 3),
('stu_04', @pw_hash, '장한별', 'student', 'DJ001', 4),
('stu_05', @pw_hash, '박서준', 'student', 'DJ001', 5),
('stu_06', @pw_hash, '이도윤', 'student', 'DJ001', 6),
('stu_07', @pw_hash, '최민준', 'student', 'DJ001', 7),
('stu_08', @pw_hash, '정하윤', 'student', 'DJ001', 8),
('stu_09', @pw_hash, '윤지호', 'student', 'DJ001', 9),
('stu_10', @pw_hash, '강서연', 'student', 'DJ001', 10),
-- 학생 DJ002
('stu_11', @pw_hash, '김현준', 'student', 'DJ002', 11),
('stu_12', @pw_hash, '박재순', 'student', 'DJ002', 12),
('stu_13', @pw_hash, '김상민', 'student', 'DJ002', 13),
('stu_14', @pw_hash, '박지희', 'student', 'DJ002', 14),
('stu_15', @pw_hash, '이민수', 'student', 'DJ002', 15),
('stu_16', @pw_hash, '최서연', 'student', 'DJ002', 16),
('stu_17', @pw_hash, '정우진', 'student', 'DJ002', 17),
('stu_18', @pw_hash, '한지민', 'student', 'DJ002', 18),
('stu_19', @pw_hash, '오세훈', 'student', 'DJ002', 19),
('stu_20', @pw_hash, '윤서준', 'student', 'DJ002', 20),
-- 학생 DJ003
('stu_21', @pw_hash, '이희도', 'student', 'DJ003', 21),
('stu_22', @pw_hash, '윤유미', 'student', 'DJ003', 22),
('stu_23', @pw_hash, '서창수', 'student', 'DJ003', 23),
('stu_24', @pw_hash, '정다솔', 'student', 'DJ003', 24),
('stu_25', @pw_hash, '김채현', 'student', 'DJ003', 25),
('stu_26', @pw_hash, '박민준', 'student', 'DJ003', 26),
('stu_27', @pw_hash, '최유진', 'student', 'DJ003', 27),
('stu_28', @pw_hash, '강현우', 'student', 'DJ003', 28),
('stu_29', @pw_hash, '한서연', 'student', 'DJ003', 29),
('stu_30', @pw_hash, '오지훈', 'student', 'DJ003', 30);
