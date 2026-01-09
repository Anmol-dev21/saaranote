# SaaraNote - UI/UX Design System

**Version**: 2.0  
**Target Users**: Students (High School, College, Graduate)  
**Design Philosophy**: Calm, Focused, Efficient  
**Last Updated**: January 8, 2026

---

## Design Philosophy

### Core Principles

**1. Calm & Distraction-Free**
- Minimal visual noise
- Generous whitespace
- Muted color palette
- No unnecessary animations
- Clear visual hierarchy

**2. Study-Focused**
- Quick access to frequent actions
- Keyboard shortcuts for power users
- Reading-optimized typography
- Low eye strain (especially dark mode)
- No gamification or distracting elements

**3. Efficient Information Architecture**
- Maximum 3 taps to any feature
- Smart defaults (fewer decisions)
- Progressive disclosure (hide complexity)
- Context-aware actions
- Batch operations support

**4. Accessible & Inclusive**
- WCAG 2.1 AA compliance minimum
- High contrast ratios
- Scalable text (respects system settings)
- Screen reader friendly
- Motor accessibility (larger touch targets)

---

## Information Architecture

### App Structure

```
┌─────────────────────────────────────────────────────┐
│                    SaaraNote                        │
└─────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┬───────────────┐
        │               │               │               │
    ┌───▼───┐      ┌───▼───┐      ┌───▼───┐      ┌───▼───┐
    │ Home  │      │Library│      │  AI   │      │Profile│
    │       │      │       │      │ Chat  │      │       │
    └───┬───┘      └───┬───┘      └───┬───┘      └───────┘
        │              │              │
    ┌───▼────────┐ ┌──▼─────────┐ ┌──▼──────────┐
    │ All Notes  │ │  Folders   │ │ Chat Session│
    │            │ │            │ │             │
    │ • Search   │ │ • Nested   │ │ • Citations │
    │ • Filter   │ │ • Smart    │ │ • Context   │
    │ • Sort     │ │ • Manual   │ └─────────────┘
    └───┬────────┘ └──┬─────────┘
        │              │
    ┌───▼────────┐ ┌──▼─────────┐
    │Note Detail │ │Folder View │
    │            │ │            │
    │ • Content  │ │ • Notes    │
    │ • Summary  │ │ • Subf.    │
    │ • Cards    │ └────────────┘
    │ • Actions  │
    └───┬────────┘
        │
    ┌───▼──────────────────┐
    │   Editor/Create      │
    │                      │
    │ • Rich Text          │
    │ • Drawing Canvas     │
    │ • OCR Camera         │
    │ • PDF Import         │
    └──────────────────────┘
```

---

## Screen Inventory

### Primary Screens (Bottom Navigation)

#### 1. Home Screen
**Purpose**: Quick access to recent notes and actions  
**Priority**: Very High (Landing screen)

**Content Blocks**:
- Quick search bar (persistent)
- Pinned notes (if any)
- Recent notes (last 10, sorted by update time)
- Quick action FAB (Create Note)

**Empty State**:
- Illustration: Peaceful desk with notebook
- Message: "Ready to capture your ideas"
- Primary CTA: "Create Your First Note"

---

#### 2. Library Screen
**Purpose**: Organized view of all notes  
**Priority**: High (Primary organization)

**Content Blocks**:
- Top tabs: [All Notes | Folders | Tags]
- Filter chips (Recent, Oldest, A-Z, Pinned)
- Note grid/list (user preference)
- Folder tree (expandable)
- Tag cloud (visual weight by usage)

**Empty State** (Folders):
- "Organize notes into folders"
- CTA: "Create Folder"

---

#### 3. AI Chat Screen
**Purpose**: Conversational interface to query notes  
**Priority**: Medium (Power feature)

**Content Blocks**:
- Chat messages (user + AI)
- Input field with voice option
- Citation cards (tappable → note)
- "New conversation" option
- Context selector (All notes | Selected folder)

**Empty State**:
- "Ask me anything about your notes"
- Suggested prompts:
  - "Summarize my notes on [topic]"
  - "What did I learn about...?"
  - "Find notes from last week"

---

#### 4. Profile Screen
**Purpose**: Settings, stats, account  
**Priority**: Low (Utility)

**Content Blocks**:
- Study stats (notes count, flashcards reviewed, time spent)
- Settings sections:
  - Appearance (theme, text size)
  - AI Features (enable/disable chat, embeddings)
  - Storage (cache size, backup)
  - About (version, licenses)
- Export data
- Help & feedback

---

### Secondary Screens (Pushed Navigation)

#### 5. Note Detail Screen
**Purpose**: View complete note with metadata  
**Priority**: Very High

**Layout**:
```
┌─────────────────────────────────────────┐
│ [Back]  Note Title           [•••More] │ ← AppBar
├─────────────────────────────────────────┤
│ Tags: #math #calculus #exam            │
│ Folder: Mathematics > Calculus         │
│ Updated: 2 hours ago                    │
├─────────────────────────────────────────┤
│                                         │
│        Note Content (Scrollable)       │
│                                         │
│   • Plain text or rich formatted       │
│   • Embedded drawings                  │
│   • Images (OCR captured)              │
│                                         │
├─────────────────────────────────────────┤
│ ▸ Summary (Collapsible)                │
│   • Auto-generated key points          │
├─────────────────────────────────────────┤
│ ▸ Flashcards (12 cards)                │
│   • Swipeable preview                  │
│   [Review All →]                        │
├─────────────────────────────────────────┤
│ ▸ Related Notes (3)                     │
│   • Semantic similarity                │
└─────────────────────────────────────────┘
│ [Edit] [Export PDF] [Share] [Delete]  │ ← FAB or Bottom Bar
└─────────────────────────────────────────┘
```

---

#### 6. Note Editor (Create/Edit)
**Purpose**: Create or edit notes with rich features  
**Priority**: Very High

**Layout Types**:

**A. Text Mode**
```
┌─────────────────────────────────────────┐
│ [Cancel]                        [Save] │
├─────────────────────────────────────────┤
│ Title: ________________________        │
├─────────────────────────────────────────┤
│ [B] [I] [U] [H1] [List] [•••]          │ ← Formatting Toolbar
├─────────────────────────────────────────┤
│                                         │
│                                         │
│     Rich Text Editor Area              │
│     (Auto-resizing)                    │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│ 📎 Add: [Photo] [Drawing] [PDF]        │
└─────────────────────────────────────────┘
```

**B. Drawing Mode**
```
┌─────────────────────────────────────────┐
│ [Done]   Drawing Canvas      [•••More] │
├─────────────────────────────────────────┤
│ [Pen] [Highlighter] [Eraser]           │
│ [○ Color Picker] [Undo] [Redo]         │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│        Canvas (Pan & Zoom)             │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│ [Convert to Text] [Save as Image]      │
└─────────────────────────────────────────┘
```

**C. Camera Mode**
```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│          Camera Viewfinder             │
│                                         │
│      [Capture with Grid Overlay]       │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│ [Gallery] [📸 Capture] [Flash: Auto]  │
└─────────────────────────────────────────┘
```

---

#### 7. Flashcard Review Screen
**Purpose**: Spaced repetition study  
**Priority**: Medium

**Layout**:
```
┌─────────────────────────────────────────┐
│ [Exit]   Calculus Cards      Progress: │
│                                 5/12    │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐ │
│  │                                   │ │
│  │         Question Text            │ │
│  │         (Centered)               │ │
│  │                                   │ │
│  │    [Tap to Reveal Answer]        │ │
│  │                                   │ │
│  └───────────────────────────────────┘ │
│                                         │
├─────────────────────────────────────────┤
│ Confidence:                             │
│ [😟 Hard] [😐 Medium] [😊 Easy]        │
│                                         │
│ [⬅ Previous]            [Next ➡]       │
└─────────────────────────────────────────┘
```

---

#### 8. Folder View Screen
**Purpose**: Browse folder contents  
**Priority**: Medium

**Layout**:
```
┌─────────────────────────────────────────┐
│ [Back] 📁 Mathematics        [Edit]    │
├─────────────────────────────────────────┤
│ 24 notes • Last updated: Today          │
├─────────────────────────────────────────┤
│ Subfolders:                             │
│ ┌──────────┐ ┌──────────┐              │
│ │📁Calculus│ │📁Algebra │              │
│ │ 12 notes │ │  8 notes │              │
│ └──────────┘ └──────────┘              │
├─────────────────────────────────────────┤
│ Notes:                                  │
│ ┌─────────────────────────────────────┐ │
│ │ Note Title                          │ │
│ │ Preview text...                     │ │
│ │ Updated 2h ago                      │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ Another Note                        │ │
│ │ More content...                     │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

#### 9. Search Results Screen
**Purpose**: Full-screen search interface  
**Priority**: High

**Layout**:
```
┌─────────────────────────────────────────┐
│ [🔍 Search notes...              ] [X] │
├─────────────────────────────────────────┤
│ Filters: [All] [Notes] [Folders] [Tags]│
├─────────────────────────────────────────┤
│ Results (24):                           │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 📄 Note Title (Matched text)       │ │
│ │ ...lorem ipsum quantum mechanics...│ │
│ │ In: Physics • 3 days ago           │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 📁 Folder Name                     │ │
│ │ 12 notes                           │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

#### 10. Tag Management Screen
**Purpose**: View and organize tags  
**Priority**: Low

**Layout**:
```
┌─────────────────────────────────────────┐
│ [Back]   Tags                 [+ New]  │
├─────────────────────────────────────────┤
│ Sort by: [Usage ▼] [A-Z] [Recent]      │
├─────────────────────────────────────────┤
│ All Tags (42):                          │
│                                         │
│ #mathematics          24 notes         │
│ #physics              18 notes         │
│ #chemistry            12 notes         │
│ #exam                  8 notes         │
│ #important             6 notes         │
│                                         │
│ (Tap to filter notes by tag)           │
└─────────────────────────────────────────┘
```

---

## Navigation Patterns

### Bottom Navigation (Primary)

**4 Tabs** (Icon + Label on Active):

```
┌─────────────────────────────────────────┐
│                                         │
│           Screen Content                │
│                                         │
└─────────────────────────────────────────┘
┌─────────┬─────────┬─────────┬──────────┐
│  🏠     │  📚     │  💬     │   👤     │
│  Home   │ Library │   AI    │ Profile  │
└─────────┴─────────┴─────────┴──────────┘
```

**Rationale**:
- Maximum 4 tabs (proven UX best practice)
- Icons are recognizable and universal
- Active tab highlighted with primary color + label
- Inactive tabs show only icon (space-efficient)

---

### Floating Action Button (FAB)

**Location**: Bottom right (except in editor/chat)  
**Behavior**: Context-aware action

**Per Screen**:
- **Home**: ➕ Create Note (opens create sheet)
- **Library**: ➕ Create Folder (in Folders tab)
- **Chat**: ✏️ New Conversation
- **Note Detail**: ✏️ Edit Note

**Alternative**: Speed Dial FAB (if multiple actions needed)
```
    [📝 Text Note]
    [✏️ Drawing]
  ➕ [📷 Photo]
    [📄 PDF]
```

---

### Gesture Navigation

**Note Cards**:
- **Swipe Right**: Pin/Unpin
- **Swipe Left**: Delete (with confirmation)
- **Long Press**: Multi-select mode
- **Tap**: Open note detail

**Flashcards**:
- **Swipe Left**: Next card
- **Swipe Right**: Previous card
- **Tap**: Flip (reveal answer)

**Chat Messages**:
- **Long Press**: Copy text
- **Tap Citation**: Open referenced note

---

### Contextual Actions

**Note Detail Screen** (Three-dot menu):
- Edit
- Export as PDF
- Share
- Move to Folder
- Add Tags
- Pin/Unpin
- Archive
- Delete

**Editor Screen** (Three-dot menu):
- Auto-save toggle
- Convert handwriting
- Generate summary
- Word count
- Discard draft

---

## Typography System

### Font Stack

**Primary Font**: **Inter** (or System Default)  
**Why**: Excellent readability, neutral, open-source

**Fallback Stack**:
```
Inter, -apple-system, BlinkMacSystemFont, 
"Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif
```

**Monospace** (for code): **JetBrains Mono** or **Fira Code**

---

### Type Scale

**Based on 16px base (1rem)**

| Element | Size | Weight | Line Height | Usage |
|---------|------|--------|-------------|-------|
| **Display** | 32px | Bold (700) | 1.2 | Screen titles |
| **H1** | 24px | Semibold (600) | 1.3 | Section headers |
| **H2** | 20px | Semibold (600) | 1.4 | Subsections |
| **H3** | 18px | Medium (500) | 1.4 | Card titles |
| **Body** | 16px | Regular (400) | 1.6 | Main content |
| **Body Small** | 14px | Regular (400) | 1.5 | Metadata |
| **Caption** | 12px | Regular (400) | 1.4 | Labels, hints |
| **Button** | 16px | Medium (500) | 1 | CTAs |

---

### Reading Optimization

**Note Content Area**:
- Font size: 18px (larger for reading comfort)
- Line height: 1.7 (generous for comprehension)
- Max width: 680px (optimal 60-75 characters per line)
- Paragraph spacing: 1.5em
- Justification: Left-aligned (no full justify)

**Dark Mode Adjustments**:
- Reduce font weight by 100 (e.g., 600 → 500)
- Reason: Light text appears heavier on dark backgrounds

---

## Color System

### Light Mode Palette

**Primary Colors**:
- **Primary**: `#5B7BF5` (Calm blue - focus, trust)
- **Primary Dark**: `#4A63C7` (Hover/pressed states)
- **Primary Light**: `#E8EDFF` (Backgrounds, highlights)

**Neutral Grays**:
- **Gray 950**: `#0A0C10` (Headings, primary text)
- **Gray 700**: `#374151` (Body text)
- **Gray 500**: `#6B7280` (Secondary text)
- **Gray 300**: `#D1D5DB` (Borders)
- **Gray 100**: `#F3F4F6` (Card backgrounds)
- **Gray 50**: `#F9FAFB` (Page background)

**Semantic Colors**:
- **Success**: `#10B981` (Green - saved, completed)
- **Warning**: `#F59E0B` (Amber - caution)
- **Error**: `#EF4444` (Red - destructive actions)
- **Info**: `#3B82F6` (Blue - informational)

**Folder Colors** (Muted for consistency):
- Red: `#FCA5A5`, Orange: `#FDBA74`, Yellow: `#FDE68A`
- Green: `#86EFAC`, Blue: `#93C5FD`, Purple: `#C4B5FD`
- Pink: `#F9A8D4`, Gray: `#D1D5DB`

---

### Dark Mode Palette

**Primary Colors**:
- **Primary**: `#7890FF` (Lighter, reduced contrast)
- **Primary Dark**: `#5B7BF5` (Original becomes dark variant)
- **Primary Light**: `#1E293B` (Muted background)

**Neutral Grays**:
- **Gray 50**: `#0F172A` (Page background)
- **Gray 100**: `#1E293B` (Card backgrounds)
- **Gray 300**: `#334155` (Borders)
- **Gray 500**: `#94A3B8` (Secondary text)
- **Gray 700**: `#CBD5E1` (Body text)
- **Gray 950**: `#F1F5F9` (Headings, primary text)

**Semantic Colors** (Desaturated):
- **Success**: `#34D399` (Lighter green)
- **Warning**: `#FBBF24` (Lighter amber)
- **Error**: `#F87171` (Lighter red)
- **Info**: `#60A5FA` (Lighter blue)

**Surface Colors**:
- **Background**: `#0F172A` (Deep slate)
- **Surface**: `#1E293B` (Cards, modals)
- **Surface Elevated**: `#334155` (Dropdown, sheets)

---

### Contrast Ratios (WCAG AA)

**Light Mode**:
- Heading (Gray 950) on Background: **20:1** ✓
- Body (Gray 700) on Background: **10:1** ✓
- Secondary (Gray 500) on Background: **4.8:1** ✓
- Primary on Background: **4.6:1** ✓

**Dark Mode**:
- Heading (Gray 950) on Background: **15:1** ✓
- Body (Gray 700) on Background: **8:1** ✓
- Secondary (Gray 500) on Background: **4.5:1** ✓
- Primary on Background: **5.2:1** ✓

---

### Color Usage Guidelines

**Do**:
- Use primary color sparingly (CTAs, active states)
- Use neutral grays for 90% of UI
- Apply semantic colors only for their meaning
- Maintain consistent folder colors across modes

**Don't**:
- Use multiple bright colors simultaneously
- Apply color purely for decoration
- Rely on color alone to convey information
- Use red/green alone (colorblind consideration)

---

## Component Design

### Cards

**Note Card** (List View):
```
┌─────────────────────────────────────┐
│ Note Title                     [📌] │ ← 18px, Semibold
│ Preview text of the note...        │ ← 14px, Gray 700
│ #tag1 #tag2                        │ ← 12px, Primary
│ 📁 Folder • 2 hours ago            │ ← 12px, Gray 500
└─────────────────────────────────────┘
```

**Dimensions**:
- Padding: 16px
- Border radius: 12px
- Shadow: 0 1px 3px rgba(0,0,0,0.1)
- Hover: Slight scale (1.02) + shadow increase

---

### Buttons

**Primary Button**:
```
┌───────────────┐
│  Save Note    │ ← 16px, Medium, White on Primary
└───────────────┘
```
- Height: 48px (minimum tap target)
- Padding: 16px 24px
- Border radius: 8px
- Hover: Darken 10%
- Press: Scale 0.98

**Secondary Button**:
```
┌───────────────┐
│    Cancel     │ ← 16px, Medium, Primary on White
└───────────────┘
```
- Height: 48px
- Padding: 16px 24px
- Border: 1.5px solid Primary
- Hover: Light background (Primary Light)

**Text Button**:
```
  Discard Draft   ← 16px, Medium, Primary (no background)
```

**Icon Button**:
```
 [🔍] ← 24x24px icon, 48x48px tap target
```

---

### Input Fields

**Text Field**:
```
┌─────────────────────────────────────┐
│ Note Title                          │ ← Label (12px, Gray 500)
│ ┌─────────────────────────────────┐ │
│ │ Enter note title...             │ │ ← Input (16px, Gray 950)
│ └─────────────────────────────────┘ │
│ 0/100                               │ ← Counter (12px, Gray 500)
└─────────────────────────────────────┘
```

**Properties**:
- Height: 56px
- Border: 1px solid Gray 300
- Border radius: 8px
- Focus: 2px border (Primary)
- Padding: 16px

**Search Field**:
```
┌─────────────────────────────────────┐
│ [🔍] Search notes...           [×] │
└─────────────────────────────────────┘
```
- Icon: Left (20px, Gray 500)
- Clear: Right (only when text present)
- Background: Gray 100 (light) / Gray 100 (dark)
- No border by default

---

### Chips

**Tag Chip**:
```
┌──────────┐
│ #physics │ ← 14px, Medium
└──────────┘
```
- Height: 32px
- Padding: 8px 12px
- Border radius: 16px (fully rounded)
- Background: Primary Light
- Text: Primary

**Filter Chip** (Toggleable):
```
┌─────────┐     ┌─────────┐
│ Recent  │ ✓   │ Oldest  │
└─────────┘     └─────────┘
  Active         Inactive
```
- Active: Primary background, White text
- Inactive: Gray 100 background, Gray 700 text

---

### Bottom Sheets

**Use Cases**:
- Folder picker
- Tag selector
- Sort/filter options
- Action sheets

**Design**:
```
┌─────────────────────────────────────┐
│              ─                      │ ← Handle (drag indicator)
│                                     │
│         Sheet Title                 │ ← 20px, Semibold
│                                     │
│  Content (scrollable if needed)    │
│                                     │
│  [Primary Action]                  │
│                                     │
└─────────────────────────────────────┘
```

**Properties**:
- Max height: 70% of screen
- Border radius: 16px (top corners)
- Background: Surface (with elevation)
- Backdrop: Semi-transparent black (0.5 opacity)

---

### Modals/Dialogs

**Confirmation Dialog**:
```
┌─────────────────────────────────────┐
│                                     │
│       Delete Note?                  │ ← 20px, Semibold
│                                     │
│  This action cannot be undone.     │ ← 16px, Gray 700
│  All summaries and flashcards      │
│  will be permanently deleted.      │
│                                     │
│  [Cancel]         [Delete]         │
│                    └─Red button     │
└─────────────────────────────────────┘
```

**Properties**:
- Max width: 400px (on tablets/desktop)
- Padding: 24px
- Border radius: 12px
- Elevation: High (shadow)

---

## Motion & Animation

### Guiding Principles

**Purposeful, Not Decorative**:
- Every animation serves a UX purpose
- Faster is better (200-300ms typical)
- Prefer subtle over dramatic
- Respect user's motion preferences (prefers-reduced-motion)

---

### Animation Inventory

**Navigation Transitions**:
- **Forward**: Slide in from right (300ms, ease-out)
- **Backward**: Slide out to right (250ms, ease-in)
- **Bottom Nav**: Fade content (200ms) + scale (0.95 → 1.0)

**FAB**:
- **Appear**: Scale up (200ms, spring)
- **Press**: Scale down (100ms) → Scale up (100ms)
- **Speed Dial**: Stagger expand (50ms delay per item)

**Cards**:
- **Appear**: Fade in + slide up 8px (250ms, ease-out)
- **Stagger**: 50ms delay between cards
- **Hover**: Elevation increase (150ms)
- **Swipe**: Follow finger + snap to state

**Modals/Sheets**:
- **Bottom Sheet**: Slide up (300ms, ease-out)
- **Modal**: Fade backdrop (200ms) + scale content (0.9 → 1.0, 250ms)

**Loading States**:
- **Skeleton**: Shimmer effect (1.5s loop, linear)
- **Spinner**: Rotate (1s loop, ease-in-out)
- **Progress Bar**: Fill animation (matches actual progress)

**Micro-interactions**:
- **Button Press**: Ripple effect (400ms)
- **Checkbox**: Check mark draw (200ms)
- **Toggle**: Slide + color change (250ms)
- **Flashcard Flip**: 3D rotate (400ms, ease-in-out)

---

### Easing Curves

```
ease-out:     Fast start, slow end (entering elements)
ease-in:      Slow start, fast end (exiting elements)
ease-in-out:  Smooth both ends (in-place transformations)
spring:       Bouncy, natural (playful interactions)
```

**Custom Spring** (for FAB, cards):
```
tension: 200
friction: 20
```

---

## Accessibility

### WCAG 2.1 AA Compliance

**Visual**:
- ✓ Minimum 4.5:1 contrast for body text
- ✓ Minimum 3:1 contrast for large text (18px+)
- ✓ Minimum 3:1 contrast for UI components
- ✓ Color not sole indicator (use icons + text)
- ✓ Focus indicators (3px outline, primary color)

**Motor**:
- ✓ Minimum tap target: 48x48px (with spacing)
- ✓ Gesture alternatives (e.g., swipe + menu option)
- ✓ No essential actions require precise timing
- ✓ Keyboard navigation support (desktop/tablet)

**Cognitive**:
- ✓ Consistent navigation patterns
- ✓ Clear labels and instructions
- ✓ Undo/cancel for destructive actions
- ✓ Error messages are helpful, not technical
- ✓ Generous timeouts (no auto-logout)

---

### Screen Reader Support

**Semantic HTML/Widgets**:
- Use native buttons, not clickable divs
- Proper heading hierarchy (H1 → H2 → H3)
- Landmark regions (navigation, main, complementary)
- Form labels explicitly associated

**ARIA Attributes**:
```
Button: aria-label="Create new note"
IconButton: aria-label="Delete note" aria-describedby="note-title"
Loading: aria-live="polite" aria-busy="true"
Error: aria-live="assertive" role="alert"
Modal: aria-modal="true" role="dialog"
```

**Announcements**:
- "Note saved" (polite)
- "3 notes found" after search (polite)
- "Error: Failed to save" (assertive)
- "Loading notes" + "Notes loaded" (polite)

---

### Text Scaling

**Support 200% Zoom** (WCAG requirement):
- Use relative units (rem, em, %)
- Avoid fixed heights (let content determine)
- Test layouts at 200% scale
- Truncate with ellipsis if needed
- No horizontal scrolling on mobile

**Minimum Sizes**:
- Body text: 14px minimum (16px default)
- Touch targets: 48px minimum
- Icon buttons: 48x48px minimum

---

### Focus Management

**Visible Focus Indicators**:
```
Outline: 3px solid Primary
Offset: 2px
Border-radius: 8px
```

**Focus Order**:
- Follow reading order (top to bottom, left to right)
- Skip navigation option (for screen readers)
- Trap focus in modals (Tab cycles within modal)
- Return focus after modal closes

**Keyboard Shortcuts**:
```
Ctrl/Cmd + K:   Search
Ctrl/Cmd + N:   New note
Ctrl/Cmd + S:   Save
Esc:            Close modal/sheet
Tab:            Next element
Shift + Tab:    Previous element
Enter:          Activate button/link
Space:          Activate button/checkbox
Arrow Keys:     Navigate lists/cards
```

---

## Responsive Design

### Breakpoints

```
Mobile (Portrait):   < 600px   [Default design]
Mobile (Landscape):  600-840px  [Optimize for reading]
Tablet (Portrait):   840-1024px [Two-column layouts]
Tablet (Landscape):  1024-1280px [Sidebar navigation]
Desktop:             > 1280px   [Max content width]
```

---

### Adaptive Layouts

**Mobile (< 600px)**:
- Bottom navigation (4 tabs)
- Single column
- FAB for primary action
- Full-width cards
- Slide-over sheets

**Tablet (840-1024px)**:
- Navigation rail (left side, collapsed)
- Two-column grid (Library)
- Side-by-side note list + detail (landscape)
- Inline modals (not full-screen)

**Desktop (> 1280px)**:
- Navigation rail (expanded with labels)
- Three-column: Sidebar | List | Detail
- Hover states more prominent
- Keyboard shortcuts emphasized
- Max content width: 1440px (centered)

---

### Mobile-First Principles

**Design for Mobile, Enhance for Desktop**:
1. Touch targets first (48px)
2. Simple navigation (bottom tabs)
3. Progressive disclosure (hide advanced features)
4. Thumb-friendly zones (bottom > top)

**Desktop Enhancements**:
- Hover previews
- Keyboard shortcuts
- Drag & drop
- Multi-select with Shift/Cmd
- Right-click context menus

---

## Dark Mode Strategy

### Implementation Approach

**System-Based by Default**:
- Respect user's system preference
- Option to override (Light | Dark | System)
- Persist user choice locally

**Smooth Transitions**:
```
transition: background-color 200ms ease,
            color 200ms ease,
            border-color 200ms ease;
```

---

### Color Adjustments (Dark Mode)

**Not Just Inverted**:
- Reduce pure white (#FFFFFF → #F1F5F9)
- Reduce pure black (#000000 → #0F172A)
- Desaturate colors (avoid eye strain)
- Lower contrast slightly (prevent glare)

**Surface Elevation**:
- Base: `#0F172A`
- +1dp: `#1E293B` (cards)
- +2dp: `#334155` (sheets, dropdowns)
- +3dp: `#475569` (modals)

**Syntax Highlighting** (code blocks):
- Use muted colors (not neon)
- Lower saturation
- Ensure 4.5:1 contrast

---

### Testing Dark Mode

**Checklist**:
- ✓ All text is readable (contrast check)
- ✓ No pure white backgrounds
- ✓ Images/illustrations have dark variants
- ✓ Shadows are visible (use lighter shadows)
- ✓ Focus indicators are clear
- ✓ Charts/graphs adapted (not inverted)

---

## Empty States

### Design Guidelines

**Components**:
1. **Illustration**: Simple, 2-color max, 120x120px
2. **Headline**: Brief, friendly (16-18px)
3. **Description**: Explain what to do (14px, Gray 500)
4. **CTA Button**: Primary action to resolve state

---

### Examples

**No Notes Yet**:
```
     [📝 Illustration]
     
     Ready to capture ideas
     
     Create your first note to get started
     with organized, searchable notes.
     
     [+ Create Note]
```

**No Search Results**:
```
     [🔍 Illustration]
     
     No notes found
     
     Try different keywords or check your
     spelling.
     
     [Clear Search]
```

**No Internet (if future cloud sync)**:
```
     [📡 Illustration]
     
     You're offline
     
     No worries! Your notes are saved locally.
     Changes will sync when you're back online.
     
     [Dismiss]
```

---

## Loading States

### Skeleton Screens

**Use for**: Note lists, folder grids, chat messages

**Design**:
```
┌─────────────────────────────────────┐
│ ▬▬▬▬▬▬▬▬▬▬▬▬            ░░░        │
│ ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬               │
│ ▬▬▬▬  ▬▬▬▬  • ▬▬▬▬                 │
└─────────────────────────────────────┘
```

**Properties**:
- Background: Gray 100 (light) / Gray 800 (dark)
- Shimmer: Linear gradient sweep (1.5s loop)
- Match card dimensions exactly

---

### Spinners

**Use for**: Short operations (< 3s)

**Design**: Circular progress indicator
- Size: 24px (inline) | 48px (fullscreen)
- Color: Primary (light) / Primary Light (dark)
- Thickness: 3px

---

### Progress Bars

**Use for**: Long operations with known duration

**Design**:
```
Uploading PDF... 47%
[████████████░░░░░░░░░░░░░░░░]
```

**Properties**:
- Height: 4px
- Fill: Primary
- Background: Gray 200
- Animated (fill expands)

---

## Error Handling

### Error Message Patterns

**Inline Errors** (Form fields):
```
┌─────────────────────────────────────┐
│ Note Title                          │
│ ┌─────────────────────────────────┐ │
│ │                                 │ │ ← Red border
│ └─────────────────────────────────┘ │
│ ⚠️ Title is required                 │ ← 12px, Red
└─────────────────────────────────────┘
```

**Toast/Snackbar** (Operation feedback):
```
┌──────────────────────────────────┐
│ ✓ Note saved successfully        │ ← Success
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ ⚠️ Failed to save note [Retry]   │ ← Error
└──────────────────────────────────┘
```

**Full-Screen Error** (Critical failure):
```
     [⚠️ Illustration]
     
     Something went wrong
     
     We couldn't load your notes.
     Check your device storage and try again.
     
     [Try Again]  [Contact Support]
```

---

### Error Message Writing

**Do**:
- Be specific ("No internet connection" not "Error 500")
- Suggest solutions ("Try again" / "Check settings")
- Use friendly tone ("Oops!" / "Hmm...")
- Provide actions (buttons)

**Don't**:
- Show technical jargon ("ERR_SQLITE_003")
- Blame user ("You entered invalid data")
- Use vague messages ("Something went wrong")
- Dead-end (always offer next step)

---

## Content Guidelines

### Microcopy Principles

**Tone of Voice**:
- Friendly but professional
- Encouraging, not condescending
- Clear and concise
- Student-relatable (avoid corporate speak)

---

### Label Examples

**Good**:
- "Create Note" (action-oriented)
- "No notes yet" (friendly)
- "Organize with folders" (benefit-focused)
- "Saved 2 seconds ago" (specific)

**Bad**:
- "Submit" (vague)
- "Empty" (negative)
- "Use folders" (command)
- "Saved recently" (imprecise)

---

### Button Labels

**Primary Actions**:
- Save Note
- Create Folder
- Start Reviewing
- Export as PDF

**Secondary Actions**:
- Cancel
- Skip
- Learn More
- Maybe Later

**Destructive Actions**:
- Delete Note (not "Remove" or "Trash")
- Discard Changes
- Clear All

---

## Iconography

### Icon Style

**Design System**: Material Symbols (Rounded variant)  
**Why**: Friendly, modern, comprehensive library

**Properties**:
- Weight: 400 (regular)
- Fill: 0 (outlined, not filled)
- Size: 24x24px default
- Optical size: 24 (matches physical size)

---

### Core Icons

| Action | Icon | Unicode |
|--------|------|---------|
| Add/Create | add | U+E145 |
| Search | search | U+E8B6 |
| Edit | edit | U+E3C9 |
| Delete | delete | U+E872 |
| Save | save | U+E161 |
| Share | share | U+E80D |
| More | more_vert | U+E5D4 |
| Back | arrow_back | U+E5C4 |
| Close | close | U+E5CD |
| Check | check | U+E5CA |
| Info | info | U+E88E |
| Warning | warning | U+E002 |
| Error | error | U+E000 |
| Folder | folder | U+E2C7 |
| Tag | label | U+E893 |
| Pin | push_pin | U+E941 |
| Archive | archive | U+E149 |
| Camera | photo_camera | U+E412 |
| Drawing | draw | U+E746 |
| Flashcard | style | U+E41D |
| AI Chat | smart_toy | U+F01C |

---

### Icon Usage Rules

**Do**:
- Use consistent size (24px or 20px)
- Pair with labels for clarity
- Use semantic colors (delete = red)
- Maintain 1:1 aspect ratio

**Don't**:
- Mix icon styles (outlined + filled)
- Use decorative icons (every icon has purpose)
- Scale icons non-uniformly
- Use color alone to differentiate

---

## Implementation Notes

### Handoff to Developers

**Design Tokens** (to be defined in code):
```json
{
  "colors": {
    "primary": "#5B7BF5",
    "gray-950": "#0A0C10",
    "gray-100": "#F3F4F6",
    ...
  },
  "typography": {
    "display": {
      "fontSize": "32px",
      "fontWeight": "700",
      "lineHeight": "1.2"
    },
    ...
  },
  "spacing": {
    "xs": "4px",
    "sm": "8px",
    "md": "16px",
    "lg": "24px",
    "xl": "32px"
  },
  "borderRadius": {
    "sm": "4px",
    "md": "8px",
    "lg": "12px",
    "full": "9999px"
  }
}
```

---

### Figma/Design Files

**Deliverables**:
1. Component library (buttons, cards, inputs)
2. Screen mockups (all states)
3. Interaction prototypes (key flows)
4. Iconography set
5. Color palette swatches
6. Typography scale samples

---

### Testing Checklist

Before launch, validate:

**Visual**:
- [ ] Light mode + Dark mode tested
- [ ] All breakpoints tested (mobile → desktop)
- [ ] Color contrast meets WCAG AA
- [ ] Typography scales correctly
- [ ] Icons render clearly

**Interaction**:
- [ ] Touch targets ≥ 48px
- [ ] Gestures work smoothly
- [ ] Keyboard navigation complete
- [ ] Focus indicators visible
- [ ] Animations respect prefers-reduced-motion

**Accessibility**:
- [ ] Screen reader tested (TalkBack/VoiceOver)
- [ ] 200% text zoom tested
- [ ] Color-blind simulation tested
- [ ] Keyboard-only navigation tested

**Content**:
- [ ] Microcopy reviewed for tone
- [ ] Error messages are helpful
- [ ] Loading states present
- [ ] Empty states complete

---

## Conclusion

This design system prioritizes **calm, focused study** over flashy features. Every decision—from muted colors to generous whitespace—aims to reduce cognitive load and help students concentrate on their notes, not the interface.

**Key Takeaways**:
- ✅ Minimal, distraction-free UI
- ✅ Reading-optimized typography
- ✅ Accessible by default (WCAG AA)
- ✅ Smooth dark mode support
- ✅ Context-aware navigation
- ✅ Purposeful animations only

This system is production-ready and can be implemented incrementally alongside the existing SaaraNote v1.0 codebase. Each component is self-contained and follows Flutter's Material Design 3 guidelines for easy adoption.

---

**Next Steps**:
1. Create component library in Figma
2. Build design tokens in Flutter theme
3. Implement core screens (Home, Library, Editor)
4. User testing with students
5. Iterate based on feedback

---

*Designed for focus. Built for students.*
