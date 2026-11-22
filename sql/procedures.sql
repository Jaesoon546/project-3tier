-- 뷰 · 프로시저 · 트리거
-- 결과 코드는 수업 코드와 같은 규칙: 1 = 성공, 2 = 대상 없음, -1 = 에러
-- HeidiSQL에서는 이 파일 전체를 한 번에 실행하세요 (DELIMITER 사용).

USE school_sungjuk;

-- ===================== 뷰 =====================

-- 학교 안에서의 등수 (평균 높은 순)
CREATE OR REPLACE VIEW student_rank AS
SELECT s.*,
       RANK() OVER (PARTITION BY s.schoolcode ORDER BY s.average DESC) AS ranks
FROM student_data s;

DELIMITER $$

-- ===================== 학교 =====================

DROP PROCEDURE IF EXISTS school_select $$
CREATE PROCEDURE school_select()
BEGIN
    SELECT schoolcode, schoolname, address, homepage, studentcount
    FROM school_data
    ORDER BY schoolname;
END $$

DROP PROCEDURE IF EXISTS school_select_one $$
CREATE PROCEDURE school_select_one(IN p_schoolcode VARCHAR(10))
BEGIN
    SELECT schoolcode, schoolname, address, homepage, studentcount
    FROM school_data
    WHERE schoolcode = p_schoolcode;
END $$

DROP PROCEDURE IF EXISTS school_insert $$
CREATE PROCEDURE school_insert(
    IN p_schoolcode VARCHAR(10), IN p_schoolname VARCHAR(50), IN p_address VARCHAR(100),
    IN p_homepage VARCHAR(200),
    OUT p_result INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;   -- 학교코드 중복 등
    INSERT INTO school_data(schoolcode, schoolname, address, homepage)
    VALUES (p_schoolcode, p_schoolname, p_address, p_homepage);
    SET p_result = 1;
END $$

-- ===================== 학생·성적 =====================

-- 학교별 성적표 (등수 순)
DROP PROCEDURE IF EXISTS student_select $$
CREATE PROCEDURE student_select(IN p_schoolcode VARCHAR(10))
BEGIN
    SELECT bunho, name, kor, eng, mat, total, average, grade, ranks
    FROM student_rank
    WHERE schoolcode = p_schoolcode
    ORDER BY ranks, bunho;
END $$

-- 학생 한 명 (수정 폼, 내 성적)
DROP PROCEDURE IF EXISTS student_select_one $$
CREATE PROCEDURE student_select_one(IN p_bunho INT)
BEGIN
    SELECT bunho, name, kor, eng, mat, total, average, grade, ranks, schoolcode
    FROM student_rank
    WHERE bunho = p_bunho;
END $$

-- 이름 검색 (LIKE)
DROP PROCEDURE IF EXISTS student_search $$
CREATE PROCEDURE student_search(IN p_schoolcode VARCHAR(10), IN p_name VARCHAR(20))
BEGIN
    SELECT bunho, name, kor, eng, mat, total, average, grade, ranks
    FROM student_rank
    WHERE schoolcode = p_schoolcode
      AND name LIKE CONCAT('%', p_name, '%')
    ORDER BY ranks, bunho;
END $$

DROP PROCEDURE IF EXISTS student_insert $$
CREATE PROCEDURE student_insert(
    IN p_name VARCHAR(20), IN p_kor INT, IN p_mat INT, IN p_eng INT,
    IN p_total INT, IN p_average DECIMAL(5,2), IN p_grade CHAR(1),
    IN p_schoolcode VARCHAR(10), IN p_changed_by VARCHAR(30),
    OUT p_result INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;
    SET @changed_by = p_changed_by;   -- 트리거가 이력에 '누가'를 적을 때 읽음
    INSERT INTO student_data(name, kor, mat, eng, total, average, grade, schoolcode)
    VALUES (p_name, p_kor, p_mat, p_eng, p_total, p_average, p_grade, p_schoolcode);
    SET p_result = 1;
END $$

DROP PROCEDURE IF EXISTS student_update $$
CREATE PROCEDURE student_update(
    IN p_bunho INT, IN p_name VARCHAR(20), IN p_kor INT, IN p_mat INT, IN p_eng INT,
    IN p_total INT, IN p_average DECIMAL(5,2), IN p_grade CHAR(1), IN p_changed_by VARCHAR(30),
    OUT p_result INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;
    IF NOT EXISTS (SELECT 1 FROM student_data WHERE bunho = p_bunho) THEN
        SET p_result = 2;
    ELSE
        SET @changed_by = p_changed_by;
        UPDATE student_data
        SET name = p_name, kor = p_kor, mat = p_mat, eng = p_eng,
            total = p_total, average = p_average, grade = p_grade
        WHERE bunho = p_bunho;
        SET p_result = 1;
    END IF;
END $$

DROP PROCEDURE IF EXISTS student_delete $$
CREATE PROCEDURE student_delete(IN p_bunho INT, IN p_changed_by VARCHAR(30), OUT p_result INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;
    IF NOT EXISTS (SELECT 1 FROM student_data WHERE bunho = p_bunho) THEN
        SET p_result = 2;
    ELSE
        SET @changed_by = p_changed_by;
        DELETE FROM student_data WHERE bunho = p_bunho;
        SET p_result = 1;
    END IF;
END $$

-- 과목별 합계·평균·최고·최저 (수업의 UNION 통계 쿼리 + 학교 조건)
DROP PROCEDURE IF EXISTS student_stats $$
CREATE PROCEDURE student_stats(IN p_schoolcode VARCHAR(10))
BEGIN
    SELECT '국어' AS subject, SUM(kor) AS total, ROUND(AVG(kor), 2) AS average,
           MAX(kor) AS max_score, MIN(kor) AS min_score
    FROM student_data WHERE schoolcode = p_schoolcode
    UNION ALL
    SELECT '영어', SUM(eng), ROUND(AVG(eng), 2), MAX(eng), MIN(eng)
    FROM student_data WHERE schoolcode = p_schoolcode
    UNION ALL
    SELECT '수학', SUM(mat), ROUND(AVG(mat), 2), MAX(mat), MIN(mat)
    FROM student_data WHERE schoolcode = p_schoolcode;
END $$

-- 학생 등록·성적 수정·삭제 이력 (최근 순)
--   변경자: 계정이 있으면 계정 이름, 계정이 지워졌으면 login_id, DB에서 직접 바꿨으면 NULL
DROP PROCEDURE IF EXISTS history_select $$
CREATE PROCEDURE history_select(IN p_schoolcode VARCHAR(10))
BEGIN
    SELECT b.log_id, b.bunho, b.name, b.kor, b.eng, b.mat, b.total, b.average, b.grade,
           b.action_log, b.action_time, b.changed_by,
           COALESCE(u.name, b.changed_by) AS changer_name
    FROM student_data_backup b
    LEFT JOIN user_data u ON u.login_id = b.changed_by
    WHERE b.schoolcode = p_schoolcode
    ORDER BY b.action_time DESC, b.log_id DESC;
END $$

-- 학생 한 명의 등록·수정·삭제 이력 (아이디어: 박지희 getStudentHistory)
--   학생이 삭제된 뒤에도 이력은 남아 있으므로 student_data가 아니라 이력 테이블에서 찾음
DROP PROCEDURE IF EXISTS history_select_student $$
CREATE PROCEDURE history_select_student(IN p_bunho INT)
BEGIN
    SELECT b.log_id, b.bunho, b.name, b.kor, b.eng, b.mat, b.total, b.average, b.grade,
           b.schoolcode, b.action_log, b.action_time, b.changed_by,
           COALESCE(u.name, b.changed_by) AS changer_name
    FROM student_data_backup b
    LEFT JOIN user_data u ON u.login_id = b.changed_by
    WHERE b.bunho = p_bunho
    ORDER BY b.action_time DESC, b.log_id DESC;
END $$

-- ===================== 계정 =====================

DROP PROCEDURE IF EXISTS user_select $$
CREATE PROCEDURE user_select(IN p_login_id VARCHAR(30))
BEGIN
    SELECT id, login_id, password_hash, name, role, schoolcode, bunho
    FROM user_data
    WHERE login_id = p_login_id;
END $$

-- 계정 목록 (관리자 계정 관리 화면) — 비밀번호 해시는 보내지 않음
DROP PROCEDURE IF EXISTS user_select_all $$
CREATE PROCEDURE user_select_all()
BEGIN
    SELECT u.id, u.login_id, u.name, u.role, u.schoolcode, sc.schoolname, u.bunho
    FROM user_data u
    LEFT JOIN school_data sc ON sc.schoolcode = u.schoolcode
    ORDER BY FIELD(u.role, 'admin', 'teacher', 'student'), sc.schoolname, u.login_id;
END $$

-- 계정 발급
--   결과: 1 = 성공, 2 = 학교 또는 학생 번호가 맞지 않음, 3 = 이미 계정이 있는 학생, -1 = 에러(아이디 중복 등)
DROP PROCEDURE IF EXISTS user_insert $$
CREATE PROCEDURE user_insert(
    IN p_login_id VARCHAR(30), IN p_password_hash VARCHAR(255), IN p_name VARCHAR(20),
    IN p_role VARCHAR(10), IN p_schoolcode VARCHAR(10), IN p_bunho INT,
    OUT p_result INT)
proc: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;

    -- 교사·학생은 존재하는 학교가 있어야 함
    IF p_role IN ('teacher', 'student')
       AND NOT EXISTS (SELECT 1 FROM school_data WHERE schoolcode = p_schoolcode) THEN
        SET p_result = 2;
        LEAVE proc;
    END IF;

    -- 학생은 그 학교의 학생 번호여야 하고, 계정은 한 명에 하나
    IF p_role = 'student' THEN
        IF NOT EXISTS (SELECT 1 FROM student_data WHERE bunho = p_bunho AND schoolcode = p_schoolcode) THEN
            SET p_result = 2;
            LEAVE proc;
        END IF;
        IF EXISTS (SELECT 1 FROM user_data WHERE bunho = p_bunho) THEN
            SET p_result = 3;
            LEAVE proc;
        END IF;
    END IF;

    INSERT INTO user_data(login_id, password_hash, name, role, schoolcode, bunho)
    VALUES (p_login_id, p_password_hash, p_name, p_role,
            IF(p_role = 'admin', NULL, p_schoolcode),
            IF(p_role = 'student', p_bunho, NULL));
    SET p_result = 1;
END $$

-- 계정 삭제
DROP PROCEDURE IF EXISTS user_delete $$
CREATE PROCEDURE user_delete(IN p_id INT, OUT p_result INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;
    IF NOT EXISTS (SELECT 1 FROM user_data WHERE id = p_id) THEN
        SET p_result = 2;
    ELSE
        DELETE FROM user_data WHERE id = p_id;
        SET p_result = 1;
    END IF;
END $$

-- 비밀번호 초기화 (관리자가 새 비밀번호를 정해 줌)
DROP PROCEDURE IF EXISTS user_reset_password $$
CREATE PROCEDURE user_reset_password(IN p_id INT, IN p_password_hash VARCHAR(255), OUT p_result INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;
    IF NOT EXISTS (SELECT 1 FROM user_data WHERE id = p_id) THEN
        SET p_result = 2;
    ELSE
        UPDATE user_data SET password_hash = p_password_hash WHERE id = p_id;
        SET p_result = 1;
    END IF;
END $$

-- ===================== 트리거 =====================

-- 수정 전 성적을 이력에 남김 (@changed_by = 프로시저가 넣어 준 login_id)
DROP TRIGGER IF EXISTS student_data_after_update $$
CREATE TRIGGER student_data_after_update
AFTER UPDATE ON student_data
FOR EACH ROW
BEGIN
    INSERT INTO student_data_backup(bunho, name, kor, mat, eng, total, average, grade, schoolcode, action_log, changed_by)
    VALUES (OLD.bunho, OLD.name, OLD.kor, OLD.mat, OLD.eng, OLD.total, OLD.average, OLD.grade, OLD.schoolcode, 'UPDATE', @changed_by);
END $$

-- 삭제된 성적을 이력에 남기고 학교 학생 수 감소
DROP TRIGGER IF EXISTS student_data_after_delete $$
CREATE TRIGGER student_data_after_delete
AFTER DELETE ON student_data
FOR EACH ROW
BEGIN
    INSERT INTO student_data_backup(bunho, name, kor, mat, eng, total, average, grade, schoolcode, action_log, changed_by)
    VALUES (OLD.bunho, OLD.name, OLD.kor, OLD.mat, OLD.eng, OLD.total, OLD.average, OLD.grade, OLD.schoolcode, 'DELETE', @changed_by);
    UPDATE school_data SET studentcount = studentcount - 1 WHERE schoolcode = OLD.schoolcode;
END $$

-- 학생이 등록되면 등록한 값을 이력에 남기고 학교 학생 수 증가
DROP TRIGGER IF EXISTS student_data_after_insert $$
CREATE TRIGGER student_data_after_insert
AFTER INSERT ON student_data
FOR EACH ROW
BEGIN
    INSERT INTO student_data_backup(bunho, name, kor, mat, eng, total, average, grade, schoolcode, action_log, changed_by)
    VALUES (NEW.bunho, NEW.name, NEW.kor, NEW.mat, NEW.eng, NEW.total, NEW.average, NEW.grade, NEW.schoolcode, 'INSERT', @changed_by);
    UPDATE school_data SET studentcount = studentcount + 1 WHERE schoolcode = NEW.schoolcode;
END $$

DELIMITER ;
