# AI Chat UI Structure

## Screen Hierarchy

```
ChatScreen
├── AppBar
│   ├── Title: "AI Assistant"
│   ├── History Button
│   └── Scope Filter Button
│
├── Scope Indicator (conditional)
│   └── ScopeChip (dismissible)
│
├── Message List (scrollable)
│   ├── MessageBubble (User)
│   │   ├── User Avatar (right)
│   │   ├── Message Content
│   │   └── Timestamp
│   │
│   └── MessageBubble (Assistant)
│       ├── AI Avatar (left)
│       ├── Message Content
│       ├── Source Citations
│       │   ├── Source 1
│       │   ├── Source 2
│       │   └── Source 3
│       └── Timestamp
│
├── Error Banner (conditional)
│   ├── Error Icon
│   ├── Error Message
│   └── Dismiss Button
│
├── QuickActionBar
│   ├── Summarize Chip
│   ├── Key Points Chip
│   └── Flashcards Chip
│
└── ChatInputField
    ├── Text Input (multi-line)
    └── Send Button (with loading state)
```

## Component Breakdown

### 1. ChatScreen (Main Container)
- **Purpose**: Orchestrates the entire chat interface
- **State Management**: Provider + ChatViewModel
- **Responsibilities**:
  - Initialize chat session
  - Handle scroll behavior
  - Coordinate UI updates
  - Show/hide conditional elements

### 2. MessageBubble (Message Display)
- **Purpose**: Display individual chat messages
- **Variants**: User (blue, right) / Assistant (white, left)
- **Features**:
  - Role-based styling
  - Source citations
  - Relative timestamps
  - Avatar icons

### 3. ChatInputField (User Input)
- **Purpose**: Text entry for questions
- **Features**:
  - Multi-line support
  - Send on Enter/button
  - Loading state
  - Disabled during processing

### 4. QuickActionBar (One-Tap Actions)
- **Purpose**: Quick access to common commands
- **Actions**:
  - Summarize notes
  - Extract key points
  - Generate flashcards
- **Features**:
  - Horizontal scroll
  - Disabled during loading
  - Icon + text labels

### 5. ScopeChip (Context Filter)
- **Purpose**: Show current query scope
- **States**:
  - All notes (default)
  - Specific folder
  - Selected notes
- **Features**:
  - Clear/dismiss action
  - Visual indicator

### 6. SourceCitationCard (Source Display)
- **Purpose**: Show where answers came from
- **Information**:
  - File/note name
  - Relevant excerpt
  - Relevance score
- **Features**:
  - Tap to navigate
  - Truncated text

## State Flow

```
User Action → ViewModel → Use Case → Repository → Database
                ↓
            notifyListeners()
                ↓
            UI Updates
```

### Example: Sending a Message

1. User types question in ChatInputField
2. User taps Send button
3. ChatInputField calls `onSend()` callback
4. ChatScreen calls `viewModel.sendQuestion(text)`
5. ChatViewModel:
   - Sets `isSending = true`
   - Calls `AskQuestionUseCase.execute()`
   - Reloads messages from repository
   - Sets `isSending = false`
   - Calls `notifyListeners()`
6. UI rebuilds:
   - Input field re-enabled
   - New messages appear
   - List auto-scrolls

## Data Flow

```
Database (SQLite + FTS5)
    ↓
ChatRepository
    ↓
ChatViewModel
    ↓
ChatScreen
    ↓
MessageBubble Widgets
```

### Message Structure
```dart
ChatMessage {
  id: 123,
  content: "What are the key concepts?",
  role: MessageRole.user,
  timestamp: DateTime(2026, 1, 12, 10, 30),
  sources: [
    CitedSource {
      fileName: "Introduction to AI.md",
      excerpt: "Machine learning is...",
      relevanceScore: 0.85
    }
  ],
  status: MessageStatus.sent
}
```

## Styling Patterns

### Color Scheme
```
User Messages:
  - Background: primaryColor (blue)
  - Text: white
  - Avatar: primaryColor with white icon

Assistant Messages:
  - Background: cardColor (white/surface)
  - Text: textPrimary (dark)
  - Avatar: primaryColor.withOpacity(0.1) with primary icon

Actions:
  - Background: primaryColor.withOpacity(0.1)
  - Border: primaryColor.withOpacity(0.3)
  - Icon/Text: primaryColor
```

### Spacing
```
Message Padding: 16px (md)
Message Margin: 8px (sm) vertical
Avatar Size: 32px radius
Input Padding: 16px (md)
Quick Action Padding: 8px (sm)
Gap Between Elements: 8px (sm)
```

### Typography
```
Message Content: bodyLarge
Timestamps: labelSmall + textSecondary
Source Citations: labelSmall + primary
Action Labels: labelMedium + bold
```

## Error Handling

### Error States
1. **Network Error**: (N/A - fully offline)
2. **Database Error**: Show error banner
3. **Generation Error**: Show error message
4. **Empty Context**: AI returns "no answer found"

### Error Display
```
Error Banner (red background)
├── Error Icon
├── Error Message
└── Dismiss Button
```

## Loading States

### 1. Initial Load
- Shows: `AppLoadingIndicator`
- Duration: ~100ms
- Triggers: On session initialization

### 2. Sending Message
- Shows: Circular progress in send button
- Duration: 300-1000ms
- Disables: Input field, quick actions

### 3. Background Operations
- Shows: Nothing (silent)
- Examples: Auto-refresh, session updates

## Responsive Design

### Mobile (< 600px)
- Full width messages
- Single column layout
- Bottom input field
- Horizontal scroll for quick actions

### Tablet (600-1024px)
- Constrained message width (max 800px)
- Centered layout
- Same bottom input field
- All quick actions visible

### Desktop (> 1024px)
- Fixed message width (800px)
- Centered chat area
- Side panels (future enhancement)
- Keyboard shortcuts (future enhancement)

## Accessibility

### Features
- **Screen Reader Support**: All interactive elements labeled
- **Touch Targets**: Minimum 48x48px
- **Contrast Ratios**: WCAG AA compliant
- **Keyboard Navigation**: Tab order logical
- **Focus Indicators**: Visible focus states

### ARIA Labels
- Send button: "Send message"
- Quick actions: "Summarize notes", etc.
- Scope chip: "Clear scope filter"
- Error dismiss: "Dismiss error"

## Performance Optimizations

### 1. ListView.builder
- Only renders visible messages
- Recycles widgets efficiently
- Handles large conversations

### 2. Provider Scope
- Minimal widget rebuilds
- Efficient state propagation
- Selective consumer usage

### 3. Database Indexing
- Indexed message timestamps
- Indexed session IDs
- Efficient JOIN queries

### 4. Lazy Loading (Future)
- Load messages in batches
- Infinite scroll support
- Pagination for history

## Integration Checklist

- [ ] Add ChatViewModel to app providers
- [ ] Add chat button to home screen
- [ ] Add chat action to note detail screen
- [ ] Implement folder selector
- [ ] Implement note selector
- [ ] Add navigation to sources
- [ ] Add chat history screen
- [ ] Add session title editing
- [ ] Test with real data
- [ ] Performance profiling
- [ ] Accessibility audit
- [ ] User testing feedback

## File Size Summary

```
File                              Lines   Purpose
-------------------------------------------------
chat_viewmodel.dart               253     State management
chat_screen.dart                  235     Main UI container
message_bubble.dart               199     Message display
quick_action_bar.dart             118     One-tap actions
source_citation_card.dart         117     Source display
chat_input_field.dart              89     Text input
scope_chip.dart                    33     Scope indicator
-------------------------------------------------
TOTAL                           1,058     Complete chat UI
```

## Git Commit

Branch: `feature/offline-ai`

New Files:
- AI_CHAT_UI_IMPLEMENTATION.md (documentation)
- lib/presentation/screens/chat_screen.dart
- lib/presentation/viewmodels/chat_viewmodel.dart
- lib/presentation/widgets/chat/ (5 widgets)

Modified Files:
- lib/domain/usecases/ask_question_usecase.dart (added scopedNoteIds)

Ready to commit and merge!
