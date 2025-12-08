import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/zip_metadata.dart';

/// Service for handling ZIP archive operations
class ZipService {
  final _uuid = const Uuid();

  /// Validate if a file is a valid ZIP archive
  Future<bool> validateZipFile(File zipFile) async {
    try {
      if (!zipFile.existsSync()) {
        return false;
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Check if archive has at least one file
      return archive.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('ZIP validation error: $e');
      }
      return false;
    }
  }

  /// Extract metadata from a ZIP file
  Future<ZipMetadata> extractMetadata(File zipFile, String assetId, {String? originalName}) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Calculate compression ratio
    int totalUncompressed = 0;
    final fileBytes = await zipFile.readAsBytes();
    final totalCompressed = fileBytes.length;

    for (final file in archive.files) {
      totalUncompressed += file.size;
    }

    final compressionRatio = totalUncompressed > 0
        ? totalCompressed / totalUncompressed
        : null;

    final hasDirectoryStructure = archive.files.any((f) => f.name.contains('/'));

    return ZipMetadata(
      id: _uuid.v4(),
      assetId: assetId,
      entryCount: archive.length,
      compressionRatio: compressionRatio,
      hasDirectoryStructure: hasDirectoryStructure,
      originalName: originalName,
    );
  }

  /// Extract all files from ZIP to a destination directory
  Future<void> extractAll(File zipFile, Directory destination) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Ensure destination exists
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    // Extract files
    for (final file in archive.files) {
      final filename = file.name;
      final filePath = '${destination.path}/$filename';

      if (file.isFile) {
        final outFile = File(filePath);
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(filePath).createSync(recursive: true);
      }
    }
  }

  /// Extract selected files from ZIP to a new ZIP file
  Future<void> extractSelected(
    File zipFile,
    List<String> entryPaths,
    String destinationPath,
  ) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Create new archive with selected files
    final newArchive = Archive();

    for (final entryPath in entryPaths) {
      // Find the file in the archive
      final file = archive.files.firstWhere(
        (f) => f.name == entryPath,
        orElse: () => throw Exception('File not found in archive: $entryPath'),
      );

      newArchive.addFile(file);
    }

    // Encode and save new ZIP
    final encodedBytes = ZipEncoder().encode(newArchive);
    if (encodedBytes != null) {
      final outputFile = File(destinationPath);
      await outputFile.writeAsBytes(encodedBytes);
    }
  }

  /// Try to extract README content from ZIP
  Future<String?> extractReadmeContent(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Look for README files (case-insensitive)
      final readmeFile = archive.files.firstWhere(
        (f) => f.name.toLowerCase().contains('readme') && f.isFile,
        orElse: () => throw Exception('No README found'),
      );

      final content = readmeFile.content as List<int>;
      return String.fromCharCodes(content);
    } catch (e) {
      return null;
    }
  }

  /// Try to auto-extract a thumbnail image from ZIP
  /// Looks for common image files (png, jpg, jpeg)
  Future<Uint8List?> extractThumbnailImage(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Look for image files in root or common screenshot directories
      final imageExtensions = ['png', 'jpg', 'jpeg', 'gif'];
      final commonImageNames = [
        'screenshot',
        'preview',
        'thumbnail',
        'thumb',
        'icon',
      ];

      // First, try to find images with common names
      for (final name in commonImageNames) {
        for (final ext in imageExtensions) {
          final file = archive.files.firstWhere(
            (f) =>
                f.isFile &&
                f.name.toLowerCase().contains(name) &&
                f.name.toLowerCase().endsWith('.$ext'),
            orElse: () => throw Exception('Not found'),
          );

          if (file.name != 'Not found') {
            return file.content as Uint8List;
          }
        }
      }

      // If not found, try to find any image file
      final imageFile = archive.files.firstWhere(
        (f) =>
            f.isFile &&
            imageExtensions.any((ext) => f.name.toLowerCase().endsWith('.$ext')),
        orElse: () => throw Exception('No image found'),
      );

      return imageFile.content as Uint8List;
    } catch (e) {
      if (kDebugMode) {
        print('No thumbnail image found in ZIP: $e');
      }
      return null;
    }
  }

  /// Calculate compression ratio for a ZIP file
  Future<double> calculateCompressionRatio(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final totalCompressed = bytes.length;

    int totalUncompressed = 0;

    for (final file in archive.files) {
      totalUncompressed += file.size;
    }

    return totalUncompressed > 0 ? totalCompressed / totalUncompressed : 0.0;
  }

  /// Get total entry count in ZIP
  Future<int> getEntryCount(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    return archive.length;
  }

  /// Get total uncompressed size of all files in ZIP
  Future<int> getTotalUncompressedSize(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    int totalSize = 0;
    for (final file in archive.files) {
      totalSize += file.size;
    }

    return totalSize;
  }

  /// Check if ZIP contains a specific file
  Future<bool> containsFile(File zipFile, String filePath) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      return archive.files.any((f) => f.name == filePath);
    } catch (e) {
      return false;
    }
  }
}
