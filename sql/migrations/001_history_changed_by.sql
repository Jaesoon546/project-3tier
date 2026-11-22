-- 2026-11-22 변경이력에 '변경자'와 '학생 등록' 기록 추가
-- 이미 만들어 둔 DB에서 한 번만 실행 → 그다음 procedures.sql 전체를 다시 실행
-- (처음 만드는 DB는 schema.sql에 이미 들어 있으므로 실행하지 않음)
USE school_sungjuk;

ALTER TABLE student_data_backup
    ADD COLUMN changed_by VARCHAR(30) NULL COMMENT '바꾼 사람의 login_id' AFTER action_time;
