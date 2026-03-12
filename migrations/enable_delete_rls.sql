-- [프로젝트 나가기/삭제 기능 RLS 권한 부여]
-- 이 스크립트를 Supabase 대시보드의 SQL Editor에 복사해서 실행(Run)해 주세요!

-- 1. projects 테이블 삭제 권한 추가 (방장용)
CREATE POLICY "Enable delete for users" 
ON public.projects 
FOR DELETE 
TO authenticated 
USING ( true );

-- 2. project_members 테이블 삭제 권한 추가 (방장 및 참여자 나가기용)
CREATE POLICY "Enable delete for users" 
ON public.project_members 
FOR DELETE 
TO authenticated 
USING ( true );

-- 스크립트 실행 후 Success가 뜨면 정상적으로 적용된 것입니다.
