# Wowasi Ya Web Portal: Implementation Plan

> **Status:** Planning
> **Created:** 2025-12-30
> **Purpose:** Extend wowasi_ya from a document generator into a living project workspace

---

## Vision

Transform wowasi_ya from a document generation tool into a **living project workspace** where clients can view, iterate on, and take action on their foundational documents over time.

**Key Value Proposition:** "We don't just give you documents, we help you use them."

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Browser                           │
│                      (React Frontend)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FastAPI Backend                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Auth/Users  │  │  Documents  │  │  Next Steps Engine      │  │
│  │   Service   │  │   Service   │  │  (per document type)    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  Projects   │  │  Versions   │  │  Existing wowasi_ya     │  │
│  │   Service   │  │   Service   │  │  Generation Engine      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       PostgreSQL                                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │
│  │  users   │ │ projects │ │documents │ │ document_versions │   │
│  └──────────┘ └──────────┘ └──────────┘ └───────────────────┘   │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────────────────────┐ │
│  │  actions │ │next_steps│ │      action_completions         │ │
│  └──────────┘ └──────────┘ └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React |
| Backend | FastAPI (extends existing wowasi_ya) |
| Database | PostgreSQL |
| Auth | JWT tokens |

---

## Database Schema Design

### Core Tables

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    organization VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP
);

-- Projects table
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,  -- original input
    status VARCHAR(50) DEFAULT 'draft',  -- draft | active | completed | archived
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Documents table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id),
    document_type VARCHAR(50) NOT NULL,  -- enum: 15 types
    phase VARCHAR(50) NOT NULL,  -- overview | discovery | planning | execution | comms
    current_version_id UUID,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Document versions table
CREATE TABLE document_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id),
    version_number INTEGER NOT NULL,
    content TEXT,  -- markdown
    content_json JSONB,  -- structured data
    change_summary VARCHAR(255),
    created_by VARCHAR(50),  -- user | ai | system
    created_at TIMESTAMP DEFAULT NOW(),
    is_current BOOLEAN DEFAULT FALSE
);
```

### Next Steps Framework Tables

```sql
-- Next step templates (predefined per document type)
CREATE TABLE next_step_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_type VARCHAR(50) NOT NULL,
    step_order INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    action_type VARCHAR(50) NOT NULL,  -- guidance | checklist | form | export | integration
    action_config JSONB,  -- type-specific config
    is_required BOOLEAN DEFAULT FALSE
);

-- Project-specific next steps (instances)
CREATE TABLE project_next_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id),
    document_id UUID REFERENCES documents(id),
    template_id UUID REFERENCES next_step_templates(id),
    status VARCHAR(50) DEFAULT 'not_started',  -- not_started | in_progress | completed | skipped
    completed_at TIMESTAMP,
    completed_by UUID REFERENCES users(id),
    notes TEXT,
    output_data JSONB  -- form responses, exports, etc.
);
```

---

## Frontend Structure (React)

```
src/
├── components/
│   ├── layout/
│   │   ├── Sidebar.tsx           # Project navigation
│   │   ├── Header.tsx            # User menu, project selector
│   │   └── PhaseNav.tsx          # Overview → Discovery → Planning...
│   │
│   ├── documents/
│   │   ├── DocumentViewer.tsx    # Render markdown with styling
│   │   ├── DocumentEditor.tsx    # Edit mode with preview
│   │   ├── VersionHistory.tsx    # Compare versions, restore
│   │   └── DocumentCard.tsx      # Summary card for listings
│   │
│   ├── next-steps/
│   │   ├── NextStepsPanel.tsx    # Sidebar showing steps for current doc
│   │   ├── StepGuidance.tsx      # Read-only guidance content
│   │   ├── StepChecklist.tsx     # Interactive checklist
│   │   ├── StepForm.tsx          # Dynamic forms (assign owners, etc.)
│   │   └── StepExport.tsx        # Export options (PDF, Excel, etc.)
│   │
│   └── project/
│       ├── ProjectDashboard.tsx  # Overview of all 15 docs + progress
│       ├── ProjectSetup.tsx      # Initial project creation wizard
│       └── ProgressTracker.tsx   # Visual progress across phases
│
├── pages/
│   ├── Login.tsx
│   ├── Dashboard.tsx             # All projects
│   ├── Project.tsx               # Single project view
│   ├── Document.tsx              # Single document + next steps
│   └── Settings.tsx
│
└── hooks/
    ├── useDocument.ts
    ├── useNextSteps.ts
    └── useVersions.ts
```

---

## The Next Steps Framework

This is the key differentiator. Each document type has predefined "next steps" that guide users on what to do with the document.

### Next Steps by Document Type

| Document | Next Steps |
|----------|------------|
| **Project Brief** | Share with stakeholders for feedback, Identify gaps/questions, Schedule kickoff meeting, Export as PDF for distribution |
| **README** | Verify all links work, Share with new team members, Set reminder to update quarterly |
| **Glossary** | Review with domain experts, Add organization-specific terms, Distribute to all stakeholders |
| **Context & Background** | Validate assumptions with stakeholders, Identify additional research needs, Flag outdated information |
| **Stakeholder Notes** | Assign communication owners, Schedule introductory meetings, Set up stakeholder update cadence |
| **Goals & Success Criteria** | Assign metric owners, Set up tracking dashboard, Schedule quarterly reviews, Define baseline measurements |
| **Scope & Boundaries** | Get formal sign-off, Distribute to all team members, Set up change request process |
| **Timeline & Milestones** | Import to project management tool, Assign milestone owners, Set up milestone notifications |
| **Initial Budget** | Review with finance, Identify funding sources, Set up expense tracking, Flag items needing quotes |
| **Risks & Assumptions** | Assign risk owners, Schedule risk review meetings, Set up risk monitoring triggers, Prioritize mitigation work |
| **Process Workflow** | Walk through with team, Identify automation opportunities, Create training materials |
| **SOPs** | Assign procedure owners, Schedule training sessions, Set review/update schedule, Test procedures |
| **Task Backlog** | Import to task management tool, Assign initial tasks, Schedule sprint planning, Prioritize first sprint |
| **Status Updates** | Set reporting cadence, Identify report recipients, Create distribution list, Schedule first update |
| **Meeting Notes** | Schedule recurring meetings, Assign note-taker rotation, Set up shared meeting folder |

### Action Types

1. **Guidance** - Read-only instructions and best practices
2. **Checklist** - Interactive checkboxes that track completion
3. **Form** - Input fields (assign owner, set date, add notes)
4. **Export** - Download as PDF, DOCX, CSV, or import to external tools
5. **Integration** - Connect to calendars, task managers, etc. (future)

---

## Document Iteration Model

### How Users Update Documents

```
View Document → Click "Edit" → Opens Editor
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              Manual Edit    AI-Assisted      Regenerate
              (direct text   (highlight +     (new context →
               changes)      "improve this")   full regen)
                    │               │               │
                    └───────────────┴───────────────┘
                                    │
                                    ▼
                            Save New Version
                            (auto-increment,
                             change summary)
```

### Version Features

- **Version History** - See all changes over time
- **Diff View** - Compare any two versions
- **Restore** - Revert to previous version
- **Branch** (future) - Create alternate versions for different scenarios

---

## API Endpoints (FastAPI Extensions)

### Projects
```
POST   /api/v1/projects                    # Create new project
GET    /api/v1/projects                    # List user's projects
GET    /api/v1/projects/{id}               # Get project with docs
PATCH  /api/v1/projects/{id}               # Update project metadata
DELETE /api/v1/projects/{id}               # Archive project
```

### Documents
```
GET    /api/v1/projects/{id}/documents                    # All docs for project
GET    /api/v1/projects/{id}/documents/{type}             # Single document
PUT    /api/v1/projects/{id}/documents/{type}             # Update (new version)
POST   /api/v1/projects/{id}/documents/{type}/regenerate  # AI regenerate
GET    /api/v1/projects/{id}/documents/{type}/versions    # Version history
GET    /api/v1/projects/{id}/documents/{type}/versions/{v}# Specific version
POST   /api/v1/projects/{id}/documents/{type}/export      # Export (PDF, etc.)
```

### Next Steps
```
GET    /api/v1/projects/{id}/documents/{type}/next-steps  # Steps for doc
PATCH  /api/v1/projects/{id}/next-steps/{step_id}         # Update step status
POST   /api/v1/projects/{id}/next-steps/{step_id}/complete# Mark complete
```

### Progress
```
GET    /api/v1/projects/{id}/progress     # Overall progress metrics
```

---

## Implementation Phases

### Phase 1: Foundation (Core Infrastructure)
- PostgreSQL database setup with schema
- User authentication (JWT-based)
- Project CRUD operations
- Document storage with versioning
- Basic React app shell with routing

**Deliverable:** Users can create projects, view generated documents

---

### Phase 2: Document Management
- Document viewer with markdown rendering
- Document editor with live preview
- Version history and diff view
- Export to PDF/DOCX

**Deliverable:** Users can view, edit, and export documents

---

### Phase 3: Next Steps Engine
- Next step templates for all 15 document types
- Step tracking (status, completion)
- Guidance rendering
- Checklist interactions
- Basic forms (assign owner, set date)

**Deliverable:** Users see and complete next steps for each document

---

### Phase 4: Progress & Dashboard
- Project dashboard with phase visualization
- Progress tracking across all documents
- Document completion indicators
- Next steps completion metrics

**Deliverable:** Users can see overall project health at a glance

---

### Phase 5: AI-Assisted Iteration
- "Improve this section" AI assistance
- Context-aware regeneration
- Smart suggestions based on completed next steps

**Deliverable:** Users can iterate on documents with AI help

---

### Phase 6: Polish & Integrations (Future)
- Calendar integrations (schedule meetings)
- Task manager integrations (import backlog)
- Team collaboration features
- Notification system

---

## Technical Considerations

| Concern | Approach |
|---------|----------|
| **Auth** | JWT tokens, refresh tokens, secure httpOnly cookies |
| **Multi-tenancy** | User-scoped queries, row-level security in Postgres |
| **Document Storage** | Markdown in TEXT column, structured data in JSONB |
| **Large Documents** | Lazy loading, pagination for version history |
| **Concurrent Edits** | Optimistic locking with version checks |
| **AI Costs** | Cache generations, user-initiated regeneration only |
| **Privacy** | Existing wowasi_ya privacy checks before AI calls |

---

## Business Model Implications

1. **Recurring Revenue** - Clients pay for ongoing access, not one-time generation
2. **Higher Value** - "We don't just give you documents, we help you use them"
3. **Stickiness** - Once clients have version history and progress tracking, they don't want to leave
4. **Differentiation** - Nobody else offers guided next steps for project documentation

---

## Next Steps for This Plan

1. [ ] Review and refine with stakeholders
2. [ ] Prioritize MVP features for Phase 1
3. [ ] Create detailed technical specs for database schema
4. [ ] Design UI/UX mockups for key screens
5. [ ] Estimate effort for each phase
