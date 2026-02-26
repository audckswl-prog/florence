# Task Checklist

## Phase 1: Foundation Setup
- [x] **Project Scaffolding**
- [x] **State Management Setup**

## Phase 2: Authentication Feature
- [x] **UI Implementation**
- [x] **Logic & Integration**

## Phase 3: Home & Navigation
- [x] **Layout Implementation**
- [x] **Search Feature**

## Phase 4: Library Management (Core)
- [x] **Book Stacking System**
- [x] **CRUD Operations**

## Phase 5: Memo System (Contextual)
- [x] **Memo Feature**

## Phase 6: Core Features & Polish
- [x] **Social Features** (Initial Setup)
- [x] **Receipt UI**

## Phase 7: Optimization & Final Polish
- [x] **Design Consistency Check**
- [x] **Performance Optimization** (Image caching, Lazy loading)
- [x] **Code Cleanup & Documentation**

## Phase 8: UI/UX Refinement (User Request)
- [x] **Redesign Loading Animation**
- [x] **Refine Book Spine Visuals**
- [x] **Refine Book Spine Geometry**
- [x] **Fix Web Build Error**
- [x] **Redesign Library Header**
- [x] **Redesign Book Count**
- [x] **Redesign Memo Screen List**
- [x] **Add Quick Actions**

## Phase 9: UI/UX Refinement (Memo Screen)
- [x] **Refine Memo Book Covers Design**
- [x] **Refine Memo Preview Gallery UI**

## Phase 10: Social Shared Reading (Project Teams)
- [x] **Database Expansion (Supabase)**
    - [x] Update `schema.sql` with new tables (`project_books`, `project_invites`, `ai_qna_logs`) and modify `project_members`.
    - [x] Apply schema changes to Supabase project.
    - [x] Update Flutter Data Models (`Project`, `ProjectMember`, `ProjectBook`, `ProjectInvite`, `AiQnaLog`).
- [x] **Data Layer (Providers & Repositories)**
    - [x] Create/Update SocialRepository for CRUD operations.
    - [x] Implement Gemini AI Chat Provider for Q&A logging.
- [x] **UI Implementation: Onboarding**
    - [x] Book Selection UI for new projects.
- [x] **UI Implementation: Project Dashboard**
    - [x] 'Shared Reading' Main Tab (Mate profiles, Active Projects).
    - [x] Project Details Screen (Member progress, Q&A Feed).
- [x] **Action Integration**
    - [x] Gemini Chat Floating button/screen linked to project.
    - [x] Increment `ai_question_count` on message send.
- [x] **Result & Receipt Generation**
    - [x] Save to 'My Storage' & Project Gallery.

## Phase 11: Library Physicality & Status Management
- [x] **Database Schema Update** (`read_pages`, `total_pages`, `read_count`)
- [x] **Data Models Update**
- [x] **Reading List UI Improvement** (Replace Memo button with Status toggles)
- [x] **Reading Record Dialog Implementation**
- [x] **Book Spine Painter Update** (Partial thickness rendering & N-th reading markers)

## Phase 12: Reading Ticket
- [x] **Data & Logic Implementation**
  - [x] Create `ai_ticket_repository.dart` for Gemini API (Nationality/Year extraction).
  - [x] Add `readBooksThisYearProvider` to count completed books in the current year.
- [x] **UI Implementation: Dialogs**
  - [x] Implement `ReadingCompletionDialog`.
  - [x] Implement `TicketQuoteInputDialog`.
- [x] **UI Implementation: Ticket Screen**
  - [x] Develop `ReadingTicketScreen` matching the provided design.
- [x] **Screen & Modal Integration**
  - [x] Update `BookDetailModal` to show the Completion Dialog.
  - [x] Update `ReadingListScreen` to show the Completion Dialog post-record.

## Phase 13: Shared Reading Revamp (1:1 Collaborative Reading)
- [x] **Database Schema Updates** (Profiles, Friendships, Notifications, Project Updates)
- [x] **Model & Repository Layer** (New models and API requests)
- [x] **UI Implementation: Shared Reading Home Tab**
  - [x] Search Bar & Friend Profile modals
  - [x] Friendship & Notification Handling
  - [x] Project List View
- [x] **UI Implementation: Project Details**
  - [x] Book Selection Phase
  - [x] In-Progress Phase (Scrubber/Slider interface)
- [x] **Progress Sync & Completion Logic**
  - [x] Reading progress sync & milestone notifications
  - [x] Completion condition check & Ticket generation

## Phase 14: Shared Reading UI Fine-tuning (User Request)
- [x] **Refine Header UI**
  - [x] Remove sub-title text from AppBar in Shared Reading tab
  - [x] Remove friend count badge from header icon
  - [x] Display friend count inside friends list modal title

## Phase 15: UI/UX Refinement (Toast Overlay)
- [x] **Adjust Toast Position**
  - [x] Move FlorenceToast to top of screen to avoid modal overlap

## Phase 16: UI/UX Refinement (Memo Screen)
- [x] **Adjust Top Spacing**
  - [x] Reduce excessive top margin above the informational banner
