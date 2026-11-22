-- 학교 데이터 (DB 담당: 김현준) — studentcount는 0으로 시작, 학생이 등록될 때 트리거가 늘려줌
USE school_sungjuk;

INSERT INTO school_data(schoolcode, schoolname, address, studentcount) VALUES
('DJ001', '대전고등학교', '대전광역시 중구 대흥로 110', 0),
('DJ002', '충남고등학교', '대전광역시 서구 문정로 171', 0),
('DJ003', '유성고등학교', '대전광역시 유성구 유성대로654번길 130', 0);
