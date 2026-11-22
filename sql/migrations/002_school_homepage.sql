-- 2026-11-22 학교 홈페이지 주소 추가 (학교 사진을 누르면 홈페이지로 이동)
-- 이미 만들어 둔 DB에서 한 번만 실행 → 그다음 procedures.sql 전체를 다시 실행
-- (처음 만드는 DB는 schema.sql에 이미 들어 있으므로 실행하지 않음)
USE school_sungjuk;

ALTER TABLE school_data
    ADD COLUMN homepage VARCHAR(200) NULL COMMENT '학교 홈페이지' AFTER address;

-- 테스트 데이터 학교의 홈페이지 (학교알리미에 등록된 주소)
UPDATE school_data SET homepage = 'http://djhs.djsch.kr'       WHERE schoolcode = 'DJ001';
UPDATE school_data SET homepage = 'http://chungnamhs.djsch.kr' WHERE schoolcode = 'DJ002';
UPDATE school_data SET homepage = 'http://yshs.djsch.kr'       WHERE schoolcode = 'DJ003';
