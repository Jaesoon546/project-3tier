-- 이미 만들어 둔 DB의 데이터만 비우기 (테이블·프로시저·트리거는 그대로)
-- 데이터를 새로 넣을 때: reset_data.sql → school_data.sql → student_data.sql → user_data.sql
-- 주의: 계정·성적·이력이 모두 지워집니다. schema.sql은 다시 실행하지 마세요.
USE school_sungjuk;

DELETE FROM user_data;            -- 계정 (학생 FK 때문에 먼저)
DELETE FROM student_data;         -- 학생 (삭제 트리거가 이력·학생 수를 건드림)
DELETE FROM student_data_backup;  -- 위에서 생긴 이력까지 비움
DELETE FROM school_data;

ALTER TABLE user_data AUTO_INCREMENT = 1;
ALTER TABLE student_data AUTO_INCREMENT = 1;
ALTER TABLE student_data_backup AUTO_INCREMENT = 1;
