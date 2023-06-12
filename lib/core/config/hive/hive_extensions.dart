import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/adapters.dart';

///
/// Opens an encrypted box, calls [callback] with the now opened box, awaits
/// [callback] to return and returns the calculated value. Closes the box after.
///
Future<R?> withEncryptedBox<T, R>(
    String name, FutureOr<R?> Function(Box<T> box) callback) async {
  final key = await _getEncryptedBoxKey();
  final box = await Hive.openBox<T>(
    name,
    encryptionCipher: HiveAesCipher(key),
  );
  final result = await callback(box);
  await box.close();
  return result;
}

Future<Uint8List> _getEncryptedBoxKey() async {
  const secureStorage = FlutterSecureStorage();
  if (!await secureStorage.containsKey(key: 'key')) {
    final key = Hive.generateSecureKey();

    await secureStorage.write(
      key: 'key',
      value: base64UrlEncode(key),
    );
  }
  final key = (await secureStorage.read(key: 'key'))!;
  return base64Decode(key);
}
