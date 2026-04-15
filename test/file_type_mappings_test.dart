import 'package:flutter_test/flutter_test.dart';
import 'package:ml_practice/models/file_type_mappings.dart';

void main() {
  group('FileTypeMappings', () {
    late FileTypeMappings mappings;

    setUp(() {
      mappings = FileTypeMappings();
    });

    test('getFileType returns correct type for known extensions', () {
      expect(mappings.getFileType('jpg'), 'images');
      expect(mappings.getFileType('png'), 'images');
      expect(mappings.getFileType('pdf'), 'documents');
      expect(mappings.getFileType('mp4'), 'multimedia');
      expect(mappings.getFileType('dart'), 'code');
      expect(mappings.getFileType('zip'), 'archives');
      expect(mappings.getFileType('xlsx'), 'spreadsheets');
      expect(mappings.getFileType('pptx'), 'presentations');
      expect(mappings.getFileType('sql'), 'databases');
      expect(mappings.getFileType('ttf'), 'fonts');
      expect(mappings.getFileType('exe'), 'system');
    });

    test('getFileType returns others for unknown extension', () {
      expect(mappings.getFileType('xyz'), 'others');
      expect(mappings.getFileType('abc'), 'others');
    });

    test('getFileType is case-insensitive', () {
      expect(mappings.getFileType('JPG'), 'images');
      expect(mappings.getFileType('PDF'), 'documents');
    });

    test('addExtension adds to existing type', () {
      mappings.addExtension('images', 'avif');
      expect(mappings.getFileType('avif'), 'images');
    });

    test('removeExtension removes from type', () {
      mappings.removeExtension('images', 'jpg');
      expect(mappings.getFileType('jpg'), 'others');
    });

    test('static isTextFile returns true for text files', () {
      expect(FileTypeMappings.isTextFile('file.txt'), true);
      expect(FileTypeMappings.isTextFile('file.dart'), true);
      expect(FileTypeMappings.isTextFile('file.json'), true);
      expect(FileTypeMappings.isTextFile('file.py'), true);
      expect(FileTypeMappings.isTextFile('/path/to/file.md'), true);
    });

    test('static isTextFile returns false for non-text files', () {
      expect(FileTypeMappings.isTextFile('file.jpg'), false);
      expect(FileTypeMappings.isTextFile('file.pdf'), false);
      expect(FileTypeMappings.isTextFile('file.mp4'), false);
    });

    test('static isImageFile returns true for images', () {
      expect(FileTypeMappings.isImageFile('photo.jpg'), true);
      expect(FileTypeMappings.isImageFile('photo.JPEG'), true);
      expect(FileTypeMappings.isImageFile('photo.png'), true);
      expect(FileTypeMappings.isImageFile('photo.webp'), true);
    });

    test('static isImageFile returns false for non-images', () {
      expect(FileTypeMappings.isImageFile('file.txt'), false);
      expect(FileTypeMappings.isImageFile('file.pdf'), false);
    });

    test('static isPdfFile works correctly', () {
      expect(FileTypeMappings.isPdfFile('doc.pdf'), true);
      expect(FileTypeMappings.isPdfFile('DOC.PDF'), true);
      expect(FileTypeMappings.isPdfFile('doc.txt'), false);
    });
  });
}
