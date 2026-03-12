-- 1. project_members 테이블에 누락된 quote와 drawing_url 컬럼을 추가합니다.
-- 이 컬럼들은 사용자가 티켓을 만들 때 남기는 인상깊은 구절과 그림(URL)을 저장합니다.

ALTER TABLE public.project_members
ADD COLUMN IF NOT EXISTS quote text,
ADD COLUMN IF NOT EXISTS drawing_url text;

-- (참고) 각 컬럼의 용도:
-- quote: 사용자가 남기는 한 줄 평 또는 인상 깊은 구절
-- drawing_url: 사용자가 그린 그림이 Storage에 저장된 URL 경로
