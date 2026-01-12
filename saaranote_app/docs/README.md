# SaaraNote Architecture Documentation

This directory contains comprehensive architecture and implementation documentation for SaaraNote features.

## 📚 Documentation Index

### Core Architecture
- **[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)** - Design tokens, typography, spacing, colors, and component patterns

### Feature Documentation

#### Advanced Note Creation
- **[ADVANCED_NOTE_FOUNDATION.md](ADVANCED_NOTE_FOUNDATION.md)** - Backend foundation for rich text and drawing support
- **[RICH_TEXT_DRAWING_UI.md](RICH_TEXT_DRAWING_UI.md)** - UI implementation for rich text editing and drawing canvas

#### AI Chat System
- **[OFFLINE_AI_CHAT_ARCHITECTURE.md](OFFLINE_AI_CHAT_ARCHITECTURE.md)** - Complete offline AI chat architecture (1700+ lines)
- **[AI_CHAT_UI_STRUCTURE.md](AI_CHAT_UI_STRUCTURE.md)** - Chat UI component structure
- **[AI_CHAT_UI_IMPLEMENTATION.md](AI_CHAT_UI_IMPLEMENTATION.md)** - Chat UI implementation details

#### File Organization
- **[FILE_ORGANIZATION_SYSTEM.md](FILE_ORGANIZATION_SYSTEM.md)** - Automated file organization system architecture

---

## 🏗️ Architecture Overview

SaaraNote follows **Clean Architecture** principles with clear layer separation:

```
lib/
├── core/          # Infrastructure (services, design system, utilities)
├── domain/        # Business logic (entities, repositories, use cases)
├── data/          # Data layer (models, data sources, repository implementations)
└── presentation/  # UI layer (screens, viewmodels, widgets)
```

### Key Architectural Patterns

- **MVVM** - Separation of UI and business logic
- **Repository Pattern** - Abstract data access
- **Use Case Pattern** - Single-responsibility business operations
- **Dependency Injection** - Provider-based DI
- **Immutable Entities** - Value objects with const constructors

### Technology Stack

- **Flutter 3.38.5** / Dart 3.10.4
- **SQLite** (sqflite) - Local database
- **Google ML Kit** - On-device OCR
- **Syncfusion PDF** - PDF text extraction
- **pdf package** - PDF generation
- **Provider** - State management

---

## 🧪 Testing

Comprehensive test suite in `/test` directory:
- 334 tests across 8 phases
- 100% pass rate
- Unit tests, integration tests, and stability tests

---

## 📖 Reading Guide

**For new developers:**
1. Start with [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) to understand UI patterns
2. Read main [README.md](../README.md) for setup instructions
3. Review [ADVANCED_NOTE_FOUNDATION.md](ADVANCED_NOTE_FOUNDATION.md) for core features

**For AI Chat implementation:**
- [OFFLINE_AI_CHAT_ARCHITECTURE.md](OFFLINE_AI_CHAT_ARCHITECTURE.md) - Complete specification

**For File Organization:**
- [FILE_ORGANIZATION_SYSTEM.md](FILE_ORGANIZATION_SYSTEM.md) - System design and usage

---

*Last updated: January 12, 2026*
