import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';

/// Service for managing local file system storage
class StorageService {
  late Directory _storageRoot;
  late Directory _assetsDir;
  late Directory _thumbnailsDir;
  late Directory _tempDir;
  late Directory _exportsDir;

  /// Initialize storage directories
  Future<void> initialize() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    _storageRoot = Directory(path_pkg.join(appDocDir.path, 'GvStorage'));

    _assetsDir = Directory(path_pkg.join(_storageRoot.path, 'assets'));
    _thumbnailsDir = Directory(path_pkg.join(_storageRoot.path, 'thumbnails'));
    _tempDir = Directory(path_pkg.join(_storageRoot.path, 'temp'));
    _exportsDir = Directory(path_pkg.join(_storageRoot.path, 'exports'));

    // Create directories if they don't exist
    await _ensureDirectoryExists(_storageRoot);
    await _ensureDirectoryExists(_assetsDir);
    await _ensureDirectoryExists(_thumbnailsDir);
    await _ensureDirectoryExists(_tempDir);
    await _ensureDirectoryExists(_exportsDir);

    if (kDebugMode) {
      print('Storage initialized at: ${_storageRoot.path}');
    }
  }

  /// Ensure a directory exists, create if it doesn't
  Future<void> _ensureDirectoryExists(Directory dir) async {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Save an asset ZIP file to storage
  /// Returns the relative path from storage root
  Future<String> saveAsset(File sourceZip, String assetId, String categorySlug) async {
    // Create category directory if it doesn't exist
    final categoryDir = Directory(path_pkg.join(_assetsDir.path, categorySlug));
    await _ensureDirectoryExists(categoryDir);

    // Define destination path
    final destPath = path_pkg.join(categoryDir.path, '$assetId.zip');

    // Copy file to destination
    final destFile = await sourceZip.copy(destPath);

    // Return relative path from storage root
    return path_pkg.relative(destFile.path, from: _storageRoot.path);
  }

  /// Get an asset file from its relative path
  Future<File> getAssetFile(String zipPath) async {
    final absolutePath = path_pkg.join(_storageRoot.path, zipPath);
    final file = File(absolutePath);

    if (!file.existsSync()) {
      throw Exception('Asset file not found: $zipPath');
    }

    return file;
  }

  /// Delete an asset file
  Future<bool> deleteAsset(String zipPath) async {
    try {
      final file = await getAssetFile(zipPath);
      await file.delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting asset: $e');
      }
      return false;
    }
  }

  /// Move an asset to a new location (e.g., when category changes)
  Future<void> moveAsset(String oldPath, String newPath) async {
    final oldFile = await getAssetFile(oldPath);
    final newAbsolutePath = path_pkg.join(_storageRoot.path, newPath);

    // Ensure destination directory exists
    final newDir = Directory(path_pkg.dirname(newAbsolutePath));
    await _ensureDirectoryExists(newDir);

    // Move file
    await oldFile.rename(newAbsolutePath);
  }

  /// Save a thumbnail image
  /// Returns the relative path from storage root
  Future<String?> saveThumbnail(File image, String assetId, {bool isMain = true}) async {
    try {
      // Create asset thumbnail directory
      final assetThumbDir = Directory(path_pkg.join(_thumbnailsDir.path, assetId));
      await _ensureDirectoryExists(assetThumbDir);

      // Determine filename
      final filename = isMain ? 'main.jpg' : 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = path_pkg.join(assetThumbDir.path, filename);

      // Copy image
      final destFile = await image.copy(destPath);

      // Return relative path
      return path_pkg.relative(destFile.path, from: _storageRoot.path);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving thumbnail: $e');
      }
      return null;
    }
  }

  /// Save multiple gallery images
  /// Returns list of relative paths
  Future<List<String>> saveGalleryImages(List<File> images, String assetId) async {
    final paths = <String>[];

    for (int i = 0; i < images.length; i++) {
      final path = await saveThumbnail(images[i], assetId, isMain: false);
      if (path != null) {
        paths.add(path);
      }
    }

    return paths;
  }

  /// Get a thumbnail file
  Future<File?> getThumbnail(String thumbnailPath) async {
    try {
      final absolutePath = path_pkg.join(_storageRoot.path, thumbnailPath);
      final file = File(absolutePath);

      if (file.existsSync()) {
        return file;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting thumbnail: $e');
      }
      return null;
    }
  }

  /// Delete all thumbnails for an asset
  Future<void> deleteThumbnails(String assetId) async {
    try {
      final assetThumbDir = Directory(path_pkg.join(_thumbnailsDir.path, assetId));
      if (assetThumbDir.existsSync()) {
        await assetThumbDir.delete(recursive: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting thumbnails: $e');
      }
    }
  }

  /// Export (copy) an asset to a user-chosen destination
  /// Returns the destination path
  Future<String> exportAsset(String zipPath, String destinationPath) async {
    final sourceFile = await getAssetFile(zipPath);

    // Ensure destination has .zip extension
    String finalDestPath = destinationPath;
    if (!destinationPath.toLowerCase().endsWith('.zip')) {
      finalDestPath = '$destinationPath.zip';
    }

    // Copy file
    await sourceFile.copy(finalDestPath);

    return finalDestPath;
  }

  /// Export selected files from a ZIP to a new ZIP at destination
  /// This is handled by ZipService, this method just provides the temp directory
  String getTempExportPath(String assetId) {
    return path_pkg.join(_tempDir.path, '${assetId}_export.zip');
  }

  /// Get the file size of a file at the given path
  Future<int> getFileSize(String relativePath) async {
    final file = await getAssetFile(relativePath);
    return file.lengthSync();
  }

  /// Clean up temporary directory
  Future<void> cleanupTemp() async {
    try {
      if (_tempDir.existsSync()) {
        final files = _tempDir.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning temp directory: $e');
      }
    }
  }

  /// Get relative path from absolute path
  String getRelativePath(File file) {
    return path_pkg.relative(file.path, from: _storageRoot.path);
  }

  /// Get the absolute path from a relative path
  String getAbsolutePath(String relativePath) {
    return path_pkg.join(_storageRoot.path, relativePath);
  }

  /// Get storage root directory
  Directory get storageRoot => _storageRoot;

  /// Get assets directory
  Directory get assetsDirectory => _assetsDir;

  /// Get thumbnails directory
  Directory get thumbnailsDirectory => _thumbnailsDir;

  /// Get temp directory
  Directory get tempDirectory => _tempDir;

  /// Get exports directory
  Directory get exportsDirectory => _exportsDir;
}
