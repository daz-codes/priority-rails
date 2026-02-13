# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Priority is a Rails 8 real-time collaborative task management app deployed at priority-list.app. Users create lists, add tasks, reorder via drag-drop, snooze tasks, and share lists via email invitations.

## Commands

```bash
bin/rails server              # Run dev server (port 3000)
bin/rails test                # Run all tests
bin/rails test test/models/task_test.rb           # Run a single test file
bin/rails test test/models/task_test.rb:10        # Run a single test by line
bin/rails test:system         # Run system tests (Capybara + Selenium)
bin/rubocop                   # Lint (RuboCop Omakase style)
bin/brakeman --no-pager       # Security scan
bin/importmap audit           # JS dependency audit
bin/kamal deploy              # Deploy via Kamal (Docker to priority-list.app)
```

## Architecture

**Stack:** Rails 8.0.1, Ruby 3.4.1, SQLite3, Propshaft, Import Maps (no JS build step), Hotwire (Turbo + Stimulus), bcrypt auth, Kamal deployment.

**Core domain models:**
- `User` has_and_belongs_to_many `List` (via `lists_users` join table)
- `List` has_many `Task` (dependent: destroy) and has_many `Category` (via `list_categories`)
- `Task` belongs_to `List`, uses `positioning` gem for drag-drop ordering. Key scopes: `completed`, `incomplete`, `snoozed`, `active`, `priority` (top 3).
- `PendingInvitation` stores email invites; auto-accepted when the invited user registers.

**Authentication:** Session-based via `Authentication` concern (`app/controllers/concerns/authentication.rb`). Uses `has_secure_password`, signed cookies, and `Current` (ActiveSupport::CurrentAttributes). All controllers require auth by default; use `allow_unauthenticated_access` to skip.

**Real-time updates:** Turbo Streams broadcasts from models (List broadcasts refreshes, Task broadcasts on destroy/update).

**Frontend JS:** Stimulus controllers in `app/javascript/controllers/` handle task completion toggle, drag-drop sorting (SortableJS), snoozing, notes editing, category selection, and list picking. A custom `yozu()` helper in `application.js` provides declarative AJAX via data attributes.

**Routing pattern:** Tasks are nested under lists for creation (`lists/:id/tasks`) but top-level for update/destroy/sort. Lists have member routes for `snoozed` view and `add_user` (invitations).

**CI:** GitHub Actions runs brakeman, importmap audit, rubocop, and full test suite on PRs and pushes to main.
