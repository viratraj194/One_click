# One Click Project Context

## Project Overview
This is a Flutter project with a Django backend (`lifeline_project`). It appears to be an emergency response or safety application (SOS dashboard, emergency contacts, etc.).

## Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Django (Python)
- **Database:** SQLite (`db.sqlite3`)

## Directory Structure
- `lib/`: Flutter application code.
- `accounts/`: Django app for user management.
- `lifeline_project/`: Django project configuration.
- `design/`: UI design screenshots.

## Architecture & Conventions

### Frontend (Flutter)
- **State Management:** Standard StatefulWidget / setState (uses `http` for data fetching).
- **Navigation:** Standard Navigator or named routes.
- **Key Screens:**
    - `dashboard_screen.dart`: Main SOS activation and emergency info.
    - `profile_dashboard.dart`: Comprehensive user profile view.
    - `emergency_contacts_screen.dart`: List of contacts.
    - `registration_screen.dart`: Multi-step or detailed user registration.
- **Widgets:** Reusable components located in `lib/widgets/`.

### Backend (Django)
- **App Structure:** Main logic resides in the `accounts/` app.
- **Models:**
    - `UserProfile`: Extends `User` with medical info, Aadhaar, and preferences.
    - `EmergencyContact`: Related contacts with sync logic to `UserProfile`.
    - `SOSAlert`: Logs location-based emergency alerts.
- **API Design:** RESTful endpoints under `api/accounts/` and `api/emergency/`.
- **Validation:** Strict regex-based validation for Aadhaar and Phone numbers.

## Mandates & Workflow
1. **No Deletions:** Do not delete any function, feature, page, or design unless explicitly instructed.
2. **Code Integrity:** Ensure existing code and features do not break during updates.
3. **Additive Development:** Adding new features must not break or delete old code, functions, files, or designs.
4. **Design Consistency:** Always follow the project's specific design colors. Do not introduce random colors.
5. **Strict Adherence:** DO NOT modify anything extra. Do not perform any task by choice unless explicitly told. Fix or add only what is requested—no more, no less.
6. **Strategic Delegation:** The project uses a hierarchical sub-agent system for efficiency and quality.
    - `architect`: The lead orchestrator who decomposes tasks and manages other sub-agents.
    - `frontend_expert`: Flutter/Dart specialist for UI and client-side logic.
    - `backend_expert`: Django/Python specialist for APIs and database.
    - `design_expert`: UI/UX and visual consistency specialist.
    - `security_expert`: Cybersecurity and QA specialist for auditing and bug-hunting.
6. **Task-Specific Models:** The `architect` will decide which sub-agent handles which task based on complexity and domain.

## Active Tasks
- Initial setup and context preservation.
- [x] Defined core specialized sub-agents (`frontend_expert`, `backend_expert`, `design_expert`).
- [x] Added `architect` and `security_expert` to the project hierarchy.
- [x] Implemented "True One-Click Emergency Actions" (GPS -> SMS -> Direct Call).
- [x] Polished Registration Screen UI to match high-fidelity designs.
- [x] Refined Profile Dashboard UI with modern dark card and stats.
- [x] Created full-screen SOS Activation UI ("HELP IS ON THE WAY").
- [x] Audited new emergency features for security and reliability.
- [x] Optimized Dashboard grid layout to fit on a single screen.
- [x] Implemented multi-contact, multi-service SOS SMS logic with dynamic message body.
