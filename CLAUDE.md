# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GvStorage is a Flutter desktop application for managing digital assets compressed in ZIP format. It provides a centralized library for organizing scripts, applications, website templates, themes, and code snippets with search, categorization, and version tracking capabilities.

**Target Platforms**: Windows, Linux, macOS (desktop only)

## Development Commands

### Setup and Dependencies
```bash
flutter pub get                    # Install dependencies
```

### Running the Application
```bash
flutter run -d linux              # Run on Linux
flutter run -d windows            # Run on Windows
flutter run -d macos              # Run on macOS
```

### Building
```bash
flutter build linux               # Build Linux executable
flutter build windows             # Build Windows executable
flutter build macos               # Build macOS executable
```

### Testing and Analysis
```bash
flutter test                      # Run all tests
flutter test test/widget_test.dart  # Run specific test file
flutter analyze                   # Run static analysis
```

## Architecture Overview

### Service-Based Architecture

The application uses a **service locator pattern** for dependency injection. All services are initialized in `ServiceLocator` (`lib/services/service_locator.dart`) and accessed globally via the `services` singleton.

**Core Services**:
- `DatabaseService`: SQLite database operations using sqflite_ffi
- `StorageService`: File system management for ZIP files, thumbnails, and temp files
- `ZipService`: ZIP file processing and extraction using the archive package
- `AssetService`: Business logic for asset CRUD operations
- `CategoryService`: Category management
- `SearchService`: Full-text search using SQLite FTS5

**Service Initialization**: Services must be initialized before app startup in `main()`. The order matters:
1. Database service (creates schema via migrations)
2. Storage service (creates directory structure)
3. Business logic services (depend on database and storage)

### Data Layer

**Database Schema** (defined in `lib/core/database/migrations/migration_v1.dart`):
- `assets`: Core asset metadata, foreign key to categories
- `categories`: Hierarchical categories with parent_id self-reference
- `tags` + `asset_tags`: Many-to-many tagging system
- `zip_metadata` + `zip_entries`: ZIP file content analysis
- `export_history`: Track export operations
- `app_settings`: Key-value configuration storage
- `assets_fts`: FTS5 virtual table for full-text search with automatic sync triggers

**Key Indexes**: Assets are indexed by category, featured status, title, created date, and slug. Foreign key constraints maintain referential integrity.

### Storage Structure

Files are stored in the application documents directory under `GvStorage/`:
```
GvStorage/
├── assets/{category-slug}/{asset-id}.zip
├── thumbnails/{asset-id}/main.jpg
├── thumbnails/{asset-id}/gallery_*.jpg
├── temp/                    # Temporary extraction/export files
└── exports/                 # User export staging area
```

**Important**: Asset ZIP paths in the database are relative to the storage root, not absolute paths. Use `StorageService.getAbsolutePath()` to convert.

### Navigation Pattern

The app uses a custom navigation system (not Navigator 2.0) in `MainNavigator` (`lib/main.dart`):
- Route-based state management with string routes (`/`, `/upload`, `/category/{slug}`, `/asset/{slug}`)
- Route changes trigger page rebuilds with appropriate data
- Asset and category data are loaded once on init and passed down to pages
- Navigation callbacks (`onNavigate`, `onAssetTap`, `onUploadTap`) are passed through widget tree

### UI Organization

**Directory Structure**:
- `lib/widgets/layout/`: App-wide layout components (header, footer, scaffold)
- `lib/widgets/common/`: Reusable UI components (pagination, sorting, section headers)
- `lib/widgets/asset/`: Asset-specific components (cards, grids, ZIP preview)
- `lib/pages/`: Full-page components (home, asset listing, asset detail, upload)

**Theme System**: Centralized in `lib/core/theme/` with `AppTheme`, `AppColors`, and `AppTextStyles`. The app uses Material Design with a light theme.

## Key Models

**Asset Model** (`lib/models/asset.dart`):
- Contains presentation data (title, description, tags, features)
- `zipPath`: Relative path to ZIP file in storage
- `ZipMetadata`: Lazy-loaded ZIP analysis data
- `features`: List of `AssetFeature` for bullet points
- Includes `fromJson()`/`toJson()` for database serialization

**Note**: The Asset model has both `toJson()` (includes computed fields like category name) and `toDatabase()` (only fields that map to database columns).

## Important Implementation Details

1. **SQLite FFI Initialization**: Desktop platforms require `sqfliteFfiInit()` and setting `databaseFactory = databaseFactoryFfi` before any database operations. This is done in both `main.dart` and `ServiceLocator`.

2. **File Picker Usage**: Use `file_picker` package for selecting ZIP files and thumbnails. Ensure file validation (ZIP format, file size) before processing.

3. **ZIP Processing**: ZIP files are analyzed on upload to extract metadata (entry count, file structure, compression ratio) and stored in `zip_metadata` table. The actual ZIP content is not extracted to disk unless explicitly requested by the user.

4. **Search Implementation**: Uses SQLite FTS5 for full-text search on asset titles and descriptions. The FTS table is automatically kept in sync via database triggers.

5. **Slug Generation**: Assets and categories use URL-friendly slugs for routing. Slugs must be unique and are generated from titles using lowercase + hyphenation.

6. **Boolean Storage**: SQLite doesn't have native boolean types. Use INTEGER (0/1) in database, convert to/from bool in Dart models.
