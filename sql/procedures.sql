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
    SELECT schoolcode, schoolname, address, studentcount
    FROM school_data
    ORDER BY schoolname;
END $$

DROP PROCEDURE IF EXISTS school_select_one $$
CREATE PROCEDURE school_select_one(IN p_schoolcode VARCHAR(10))
BEGIN
    SELECT schoolcode, schoolname, address, studentcount
    FROM school_data
    WHERE schoolcode = p_schoolcode;
END $$

DROP PROCEDURE IF EXISTS school_insert $$
CREATE PROCEDURE school_insert(
    IN p_schoolcode VARCHAR(10), IN p_schoolname VARCHAR(50), IN p_address VARCHAR(100),
    OUT p_result INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;   -- 학교코드 중복 등
    INSERT INTO school_data(schoolcode, schoolname, address)
    VALUES (p_schoolcode, p_schoolname, p_address);
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
    IN p_schoolcode VARCHAR(10),
    OUT p_result INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;
    INSERT INTO student_data(name, kor, mat, eng, total, average, grade, schoolcode)
    VALUES (p_name, p_kor, p_mat, p_eng, p_total, p_average, p_grade, p_schoolcode);
    SET p_result = 1;
END $$

DROP PROCEDURE IF EXISTS student_update $$
CREATE PROCEDURE student_update(
    IN p_bunho INT, IN p_name VARCHAR(20), IN p_kor INT, IN p_mat INT, IN p_eng INT,
    IN p_total INT, IN p_average DECIMAL(5,2), IN p_grade CHAR(1),
    OUT p_result INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;
    IF NOT EXISTS (SELECT 1 FROM student_data WHERE bunho = p_bunho) THEN
        SET p_result = 2;
    ELSE
        UPDATE student_data
        SET name = p_name, kor = p_kor, mat = p_mat, eng = p_eng,
            total = p_total, average = p_average, grade = p_grade
        WHERE bunho = p_bunho;
        SET p_result = 1;
    END IF;
END $$

DROP PROCEDURE IF EXISTS student_delete $$
CREATE PROCEDURE student_delete(IN p_bunho INT, OUT p_result INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION SET p_result = -1;
    IF NOT EXISTS (SELECT 1 FROM student_data WHERE bunho = p_bunho) THEN
        SET p_result = 2;
    ELSE
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

-- 성적 수정·삭제 이력 (최근 순)
DROP PROCEDURE IF EXISTS history_select $$
CREATE PROCEDURE history_select(IN p_schoolcode VARCHAR(10))
BEGIN
    SELECT log_id, bunho, name, kor, eng, mat, total, average, grade,
           action_log, action_time
    FROM student_data_backup
    WHERE schoolcode = p_schoolcode
    ORDER BY action_time DESC, log_id DESC;
END $$

-- ===================== 계정 =====================

DROP PROCEDURE IF EXISTS user_select $$
CREATE PROCEDURE user_select(IN p_login_id VARCHAR(30))
BEGIN
    SELECT id, login_id, password_hash, name, role, schoolcode, bunho
    FROM user_data
    WHERE login_id = p_login_id;
END $$

-- ===================== 트리거 =====================

-- 수정 전 성적을 이력에 남김
DROP TRIGGER IF EXISTS student_data_after_update $$
CREATE TRIGGER student_data_after_update
AFTER UPDATE ON student_data
FOR EACH ROW
BEGIN
    INSERT INTO student_data_backup(bunho, name, kor, mat, eng, total, average, grade, schoolcode, action_log)
    VALUES (OLD.bunho, OLD.name, OLD.kor, OLD.mat, OLD.eng, OLD.total, OLD.average, OLD.grade, OLD.schoolcode, 'UPDATE');
END $$

-- 삭제된 성적을 이력에 남기고 학교 학생 수 감소
DROP TRIGGER IF EXISTS student_data_after_delete $$
CREATE TRIGGER student_data_after_delete
AFTER DELETE ON student_data
FOR EACH ROW
BEGIN
    INSERT INTO student_data_backup(bunho, name, kor, mat, eng, total, average, grade, schoolcode, action_log)
    VALUES (OLD.bunho, OLD.name, OLD.kor, OLD.mat, OLD.eng, OLD.total, OLD.average, OLD.grade, OLD.schoolcode, 'DELETE');
    UPDATE school_data SET studentcount = studentcount - 1 WHERE schoolcode = OLD.schoolcode;
END $$

-- 학생이 등록되면 학교 학생 수 증가
DROP TRIGGER IF EXISTS student_data_after_insert $$
CREATE TRIGGER student_data_after_insert
AFTER INSERT ON student_data
FOR EACH ROW
BEGIN
    UPDATE school_data SET studentcount = studentcount + 1 WHERE schoolcode = NEW.schoolcode;
END $$

DELIMITER ;
