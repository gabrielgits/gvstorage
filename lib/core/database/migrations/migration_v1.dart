import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initial database schema migration
Future<void> migrationV1(Database db) async {
  // Create assets table
  await db.execute('''
    CREATE TABLE assets (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      slug TEXT UNIQUE NOT NULL,
      description TEXT NOT NULL,
      short_description TEXT,
      category_id TEXT NOT NULL,
      version TEXT,
      last_updated INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
      file_size INTEGER NOT NULL,
      zip_path TEXT NOT NULL UNIQUE,
      thumbnail_path TEXT,
      demo_url TEXT,
      is_featured INTEGER DEFAULT 0,
      downloads_count INTEGER DEFAULT 0,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
    )
  ''');

  // Create categories table
  await db.execute('''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      slug TEXT UNIQUE NOT NULL,
      description TEXT,
      parent_id TEXT,
      display_order INTEGER DEFAULT 0,
      asset_count INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE CASCADE
    )
  ''');

  // Create tags table
  await db.execute('''
    CREATE TABLE tags (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      slug TEXT UNIQUE NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');

  // Create asset_tags junction table
  await db.execute('''
    CREATE TABLE asset_tags (
      asset_id TEXT NOT NULL,
      tag_id TEXT NOT NULL,
      PRIMARY KEY (asset_id, tag_id),
      FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
      FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
    )
  ''');

  // Create zip_metadata table
  await db.execute('''
    CREATE TABLE zip_metadata (
      id TEXT PRIMARY KEY,
      asset_id TEXT NOT NULL UNIQUE,
      entry_count INTEGER NOT NULL,
      compression_ratio REAL,
      has_directory_structure INTEGER DEFAULT 1,
      original_name TEXT,
      FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
    )
  ''');

  // Create app_settings table
  await db.execute('''
    CREATE TABLE app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

  // Create export_history table
  await db.execute('''
    CREATE TABLE export_history (
      id TEXT PRIMARY KEY,
      asset_id TEXT NOT NULL,
      export_path TEXT NOT NULL,
      exported_at INTEGER NOT NULL,
      export_type TEXT NOT NULL,
      FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
    )
  ''');

  // Create indexes
  await db.execute('CREATE INDEX idx_assets_category ON assets(category_id)');
  await db.execute('CREATE INDEX idx_assets_featured ON assets(is_featured)');
  await db.execute('CREATE INDEX idx_assets_title ON assets(title)');
  await db.execute('CREATE INDEX idx_assets_created ON assets(created_at DESC)');
  await db.execute('CREATE INDEX idx_assets_slug ON assets(slug)');

  await db.execute('CREATE INDEX idx_tags_name ON tags(name)');
  await db.execute('CREATE INDEX idx_asset_tags_asset ON asset_tags(asset_id)');
  await db.execute('CREATE INDEX idx_asset_tags_tag ON asset_tags(tag_id)');

  await db.execute('CREATE INDEX idx_categories_parent ON categories(parent_id)');
  await db.execute('CREATE INDEX idx_categories_slug ON categories(slug)');

  // Create FTS5 virtual table for full-text search
  await db.execute('''
    CREATE VIRTUAL TABLE assets_fts USING fts5(
      title,
      description,
      content=assets,
      content_rowid=rowid
    )
  ''');

  // Create triggers to keep FTS in sync
  await db.execute('''
    CREATE TRIGGER assets_fts_insert AFTER INSERT ON assets BEGIN
      INSERT INTO assets_fts(rowid, title, description)
      VALUES (new.rowid, new.title, new.description);
    END
  ''');

  await db.execute('''
    CREATE TRIGGER assets_fts_delete AFTER DELETE ON assets BEGIN
      DELETE FROM assets_fts WHERE rowid = old.rowid;
    END
  ''');

  await db.execute('''
    CREATE TRIGGER assets_fts_update AFTER UPDATE ON assets BEGIN
      UPDATE assets_fts
      SET title = new.title, description = new.description
      WHERE rowid = new.rowid;
    END
  ''');

  // Create trigger to auto-update updated_at on record changes
  await db.execute('''
    CREATE TRIGGER assets_updated_at_trigger
    AFTER UPDATE ON assets
    FOR EACH ROW
    BEGIN
      UPDATE assets SET updated_at = (strftime('%s', 'now') * 1000)
      WHERE id = NEW.id;
    END
  ''');
}