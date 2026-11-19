-- 학교별 성적관리 홈페이지 — 테이블 생성
-- 실행 순서: schema.sql → procedures.sql → school_data.sql → student_data.sql → user_data.sql
-- MySQL 8.0 이상 (등수 계산에 RANK() 윈도우 함수 사용)

CREATE DATABASE IF NOT EXISTS school_sungjuk DEFAULT CHARACTER SET utf8mb4;
USE school_sungjuk;

DROP TABLE IF EXISTS user_data;
DROP TABLE IF EXISTS student_data_backup;
DROP TABLE IF EXISTS student_data;
DROP TABLE IF EXISTS school_data;

-- 학교
CREATE TABLE school_data (
    schoolcode   VARCHAR(10)  NOT NULL PRIMARY KEY,   -- 예: DJ00000001
    schoolname   VARCHAR(50)  NOT NULL,
    address      VARCHAR(100),
    studentcount INT          DEFAULT 0
);

-- 학생·성적 (총점·평균·학점은 저장할 때 Python service/grade.py가 계산해서 넣음)
-- 등수는 학교마다 달라서 컬럼으로 저장하지 않고 student_rank 뷰에서 계산
CREATE TABLE student_data (
    bunho      INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(20)  NOT NULL,
    kor        INT          NOT NULL CHECK (kor BETWEEN 0 AND 100),
    mat        INT          NOT NULL CHECK (mat BETWEEN 0 AND 100),
    eng        INT          NOT NULL CHECK (eng BETWEEN 0 AND 100),
    total      INT          NOT NULL DEFAULT 0,
    average    DECIMAL(5,2) NOT NULL DEFAULT 0,
    grade      CHAR(1)      NOT NULL DEFAULT 'F',
    schoolcode VARCHAR(10)  NOT NULL,
    FOREIGN KEY (schoolcode) REFERENCES school_data(schoolcode)
);

-- 성적 수정·삭제 이력 (트리거가 기록)
CREATE TABLE student_data_backup (
    log_id      INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    bunho       INT          NOT NULL,
    name        VARCHAR(20),
    kor         INT,
    mat         INT,
    eng         INT,
    total       INT,
    average     DECIMAL(5,2),
    grade       CHAR(1),
    schoolcode  VARCHAR(10),
    action_log  VARCHAR(10)  NOT NULL,                 -- 'UPDATE' 또는 'DELETE'
    action_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 로그인 계정 (관리자·교사·학생)
--   admin   : schoolcode, bunho 모두 NULL
--   teacher : schoolcode = 소속 학교
--   student : schoolcode = 소속 학교, bunho = student_data의 본인 번호
CREATE TABLE user_data (
    id            INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    login_id      VARCHAR(30)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,                -- 평문 비밀번호는 저장하지 않음
    name          VARCHAR(20)  NOT NULL,
    role          ENUM('admin', 'teacher', 'student') NOT NULL,
    schoolcode    VARCHAR(10),
    bunho         INT,
    FOREIGN KEY (schoolcode) REFERENCES school_data(schoolcode),
    FOREIGN KEY (bunho) REFERENCES student_data(bunho) ON DELETE CASCADE
);
