import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProductCatalogFileService {
  const ProductCatalogFileService();

  Future<String> pickJsonContent() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      throw const ProductCatalogFileCancelledException();
    }

    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      throw const ProductCatalogFileException(
        'No se pudo leer el archivo seleccionado.',
      );
    }

    return File(path).readAsString();
  }

  Future<ProductCatalogSavedFile> saveExportedJson(String jsonContent) async {
    final fileName = _buildExportFileName(DateTime.now());
    final directory = await _getExportDirectory();

    if (_isAndroidDownloadsDirectory(directory)) {
      final saved = await _tryWriteExport(
        directory: directory,
        fileName: fileName,
        jsonContent: jsonContent,
      );
      if (saved != null) {
        return ProductCatalogSavedFile(
          file: saved,
          storageMessage: 'Archivo guardado en Descargas',
        );
      }
    }

    final fallbackDirectory = _isAndroidDownloadsDirectory(directory)
        ? await getApplicationDocumentsDirectory()
        : directory;
    final file = await _writeExport(
      directory: fallbackDirectory,
      fileName: fileName,
      jsonContent: jsonContent,
    );

    return ProductCatalogSavedFile(
      file: file,
      storageMessage: 'Archivo guardado en carpeta interna de la app',
    );
  }

  Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      final downloads = Directory('/storage/emulated/0/Download');

      if (await downloads.exists()) {
        return downloads;
      }
    }

    return getApplicationDocumentsDirectory();
  }

  bool _isAndroidDownloadsDirectory(Directory directory) {
    return Platform.isAndroid &&
        directory.path == '/storage/emulated/0/Download';
  }

  Future<File?> _tryWriteExport({
    required Directory directory,
    required String fileName,
    required String jsonContent,
  }) async {
    try {
      return _writeExport(
        directory: directory,
        fileName: fileName,
        jsonContent: jsonContent,
      );
    } on FileSystemException {
      return null;
    }
  }

  Future<File> _writeExport({
    required Directory directory,
    required String fileName,
    required String jsonContent,
  }) {
    final file = File('${directory.path}/$fileName');
    return file.writeAsString(jsonContent, flush: true);
  }

  String _buildExportFileName(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    return 'productos_catalogo_${date.year}_${two(date.month)}_${two(date.day)}_${two(date.hour)}_${two(date.minute)}.json';
  }
}

class ProductCatalogFileException implements Exception {
  const ProductCatalogFileException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProductCatalogFileCancelledException implements Exception {
  const ProductCatalogFileCancelledException();
}

class ProductCatalogSavedFile {
  const ProductCatalogSavedFile({
    required this.file,
    required this.storageMessage,
  });

  final File file;
  final String storageMessage;
}
