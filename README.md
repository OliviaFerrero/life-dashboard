# Life Dashboard

Life Dashboard (`life_hub`) is a local-first Android application built with Flutter and Dart for organizing daily activities.

The current implementation focuses on task management, scheduling and calendar views. Task data is stored locally with SQLite and Drift, while application settings that do not belong to the task database are stored separately on the device.

## Current features

### Tasks

Tasks can include:

- date
- start time
- duration
- all-day state
- priority
- category
- notes
- subtasks
- recurrence
- completion state

Tasks without a date are kept in the Inbox.

Categories are reusable and editable, with their own color and icon.

Subtasks can be added, renamed, reordered and removed. Their completion state is tracked independently from the parent task, including for recurring occurrences.

### Recurrence

The current recurrence model supports:

- daily recurrence
- weekly recurrence on selected weekdays
- completion state for individual occurrences
- editing or deleting a single occurrence
- editing or deleting the whole series
- per-occurrence overrides without duplicating the recurring series

Cross-midnight tasks are handled as a single task or occurrence while being displayed across the civil days they overlap.

### Today

The **Oggi** page uses a configurable personal-day window instead of a fixed midnight-to-midnight view.

It includes:

- a continuous daily timeline
- timed and untimed tasks
- compressed free-time intervals
- duration-based task visualization
- current-time indication
- overlapping-task handling
- subtask progress
- shortcuts to scheduled activities and Inbox

The start and end of the personal day can be configured in the app settings.

### Calendar

The calendar provides both Month and Week views.

The Month view includes:

- monthly navigation
- task markers
- selected-day agenda
- task creation from the selected date

The Week view includes:

- Monday-to-Sunday hourly grid
- timed task blocks
- overlapping-event layout
- vertical and horizontal scrolling
- independent vertical and horizontal zoom
- drag-to-reschedule
- duration resize
- cross-midnight rendering
- all-day and no-time task overlay
- contextual task actions
- copy and paste inside the calendar

Recurring tasks preserve occurrence or series scope when edited from calendar interactions.

### Task detail and editing

The task form supports creation and editing of task scheduling, recurrence, category, priority, notes and subtasks.

The task detail view provides task information, timing, subtask progress, notes, completion and edit/delete actions.

Custom date and time controls are used throughout the task workflow.

## Interface

Life Dashboard supports light and dark mode.

Task categories provide the main visual identity through their color and icon, while priority is shown separately.

The interface uses a shared visual language across Today, Tasks, Calendar, Task Detail and Task Form.

## Technical stack

- Flutter
- Dart
- SQLite
- Drift
- Material 3
- `table_calendar`
- `path_provider`
- `path`

The application is currently Android-first.

## Application structure

The project is organized around a small set of responsibilities:

```text
lib/
├── application/
├── core/
├── database/
├── models/
├── repositories/
├── screens/
├── services/
├── theme/
├── utils/
└── widgets/
```

The UI works through repositories and application/controller layers rather than accessing Drift directly.

Shared infrastructure includes application-wide handling for task actions, task editor state, IDs, current time and civil-date calculations.

## Local data

Task and category data is persisted locally with SQLite and Drift.

Recurring series are stored once and individual occurrence state is stored separately when needed.

Personal-day settings are stored locally outside the task database.

The project is designed to preserve existing local data across database migrations.

## Development

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

Static analysis:

```bash
flutter analyze
```

Run the automated test suite:

```bash
flutter test
```

## Project status

The task and calendar areas are the current implemented core of the application.

Planned areas include:

- Habits
- Home, inventory and shopping
- Expenses, budgets and subscriptions
- Hobby sessions and logs
- Notifications
- richer recurrence options
- barcode, receipt and expiration support

Cloud synchronization, multi-device use and shared household features may be considered later.
