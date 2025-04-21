// lib/utils/file_utils.dart
import 'dart:io';
import 'dart:math'; // Import for log and pow functions
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for file operations
class FileUtils {
  /// Get application document directory
  static Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// Get external storage directory (Android only)
  static Future<Directory?> getExternalDirectory() async {
    return await getExternalStorageDirectory();
  }
  
  /// Create a file in the app directory
  static Future<File> createFileInAppDir(String fileName, List<int> bytes) async {
    final dir = await getAppDirectory();
    final filePath = path.join(dir.path, fileName);
    final file = File(filePath);
    
    return await file.writeAsBytes(bytes);
  }
  
  /// Create a text file in the app directory
  static Future<File> createTextFileInAppDir(String fileName, String content) async {
    final dir = await getAppDirectory();
    final filePath = path.join(dir.path, fileName);
    final file = File(filePath);
    
    return await file.writeAsString(content);
  }
  
  /// Read a file from the app directory
  static Future<List<int>> readFileFromAppDir(String fileName) async {
    final dir = await getAppDirectory();
    final filePath = path.join(dir.path, fileName);
    final file = File(filePath);
    
    return await file.readAsBytes();
  }
  
  /// Read a text file from the app directory
  static Future<String> readTextFileFromAppDir(String fileName) async {
    final dir = await getAppDirectory();
    final filePath = path.join(dir.path, fileName);
    final file = File(filePath);
    
    return await file.readAsString();
  }
  
  /// Delete a file from the app directory
  static Future<void> deleteFileFromAppDir(String fileName) async {
    final dir = await getAppDirectory();
    final filePath = path.join(dir.path, fileName);
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// List all files in app directory
  static Future<List<FileSystemEntity>> listFilesInAppDir() async {
    final dir = await getAppDirectory();
    return dir.listSync();
  }
  
  /// Create a zip archive from multiple files
  static Future<File> createZipArchive(List<File> files, String archiveName) async {
    final archive = Archive();
    
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final fileName = path.basename(file.path);
      
      // Create archive file with the bytes directly
      final archiveFile = ArchiveFile(fileName, bytes.length, bytes);
      archive.addFile(archiveFile);
    }
    
    final zipData = ZipEncoder().encode(archive);
    
    final dir = await getAppDirectory();
    final zipPath = path.join(dir.path, '$archiveName.zip');
    final zipFile = File(zipPath);
    
    return await zipFile.writeAsBytes(zipData ?? []);
  }
  
  /// Extract a zip archive
  static Future<List<File>> extractZipArchive(File zipFile, String outputDir) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final extractedFiles = <File>[];
    
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final outFile = File('$outputDir/$filename');
        await outFile.create(recursive: true);
        // Use a cast to ensure List<int> type
        final content = file.content;
        if (content != null) {
          await outFile.writeAsBytes(content as List<int>);
          extractedFiles.add(outFile);
        }
      }
    }
    
    return extractedFiles;
  }
  
  /// Share a file
  static Future<void> shareFile(File file, {String? subject}) async {
    // Using Share.share instead of shareFiles
    await Share.share(
      file.path,
      subject: subject,
    );
    
    // Alternative implementation for newer versions of share_plus:
    // await Share.shareXFiles([XFile(file.path)], subject: subject);
  }
  
  /// Get file size in human-readable format
  static String getFileSize(File file, {int decimals = 1}) {
    final bytes = file.lengthSync();
    if (bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    // Use proper math functions from dart:math
    final i = (log(bytes) / log(1024)).floor();
    
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
  
  /// Request storage permission and prepare directories
  static Future<bool> prepareStorage() async {
    final status = await Permission.storage.request();
    
    // Simple boolean check without unnecessary type check
    if (status.isGranted) {
      final appDir = await getAppDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      final exportDir = Directory('${appDir.path}/exports');
      final tempDir = Directory('${appDir.path}/temp');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      
      return true;
    }
    
    return false;
  }
  
  /// Clean temporary files
  static Future<void> cleanTempFiles() async {
    final appDir = await getAppDirectory();
    final tempDir = Directory('${appDir.path}/temp');
    
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      await tempDir.create();
    }
  }
}