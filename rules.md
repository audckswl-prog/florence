# AI Agent Rules for 피렌체

## 1. Core Directives
- **Language**: 앱의 모든 UI 텍스트, 프롬프트, AI 응답은 불가피한 경우를 제외하고 반드시 **한글(Korean)**로 작성한다.
- **Reference**: 상세한 기능 명세 및 화면 구성은 항상 `spec.md` 파일을 최우선으로 참고하여 구현한다. 임의로 기능을 생략하거나 축소하지 않는다.

## 2. Tech Stack Constraints
- **Frontend**: Flutter (Android, iOS, PWA 완전 대응 - 반응형 UI 필수)
- **Backend/DB**: Supabase (PostgreSQL 기반)
- **API**: 

  - 알라딘 Open API (도서 정보 파싱)
  - OCR (이미지 텍스트 추출 기능)

## 3. Design System: "Soft Modern Minimal"
본 앱은 '지적인 신뢰감'과 '아날로그적 물성'이 공존하는 소프트 미니멀리즘을 지향한다. 단순한 데이터가 아닌 '개인적 자산(수집품)'의 느낌을 주어야 한다.

- **Design Keywords**: #Ivory_Base #Soft_Minimalism #Super_Rounded #Sophisticated_Clean
- **Color Strategy**:
  - `Base` (Background): Ivory (눈이 편안한 미색, 종이의 질감 암시)
  - `Point` (Action): Burgundy Red (지적이고 강렬한 포인트 - 초대권, AI 질문, 완독 버튼 등)
  - `Contrast` (Text/Line): Deep Charcoal & Black (가독성), Pure White (포인트 하이라이트)
- **UI/UX Principles**:
  - **Border-less Design**: 불필요한 구분선(Border)을 제거하고 넓은 여백(White Space)을 활용.
  - **Physicality (물성)**: 깔끔한 플랫 디자인 위주로, 과한 3D 효과(뉴모피즘 등)는 배제한다. 대신 부드럽고 둥근 모서리와 은은한 계층형 뎁스(Depth Shadow)를 기본으로 활용한다.
  - **Typography**: 제목(Title)은 클래식한 세리프(명조) 계열, 본문(Body)은 가독성 높은 산세리프(Pretendard 등)를 적용하여 깔끔한 정보 계층화를 이룬다.

## 4. Coding Workflow
- UI 구성 시 한 번에 거대한 위젯을 만들지 말고, 재사용 가능한 작은 Component 단위로 분리하여 작업한다.
- 백엔드 연동이 필요한 UI 작업 전, 반드시 Supabase 테이블 스키마와 데이터 모델을 먼저 정의하고 확인을 받는다.
- **User Required Actions**: AI가 직접 수행할 수 없는 작업(예: SQL 실행, 콘솔 설정 등)이 필요한 경우, 단순히 요청만 하지 말고 **"사용자가 정확히 무엇을, 어떻게 해야 하는지 상세하고 친절하게 단계별로 설명"**한다. (예: 어떤 화면에서 어느 버튼을 눌러야 하는지, 복사할 코드는 무엇인지 정확히 명시)