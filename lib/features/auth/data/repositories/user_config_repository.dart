import 'dart:convert';

import 'package:dairy_app/core/logger/logger.dart';
import 'package:dairy_app/features/auth/data/models/user_config_model.dart';
import 'package:dairy_app/features/sync/data/datasources/temeplates/key_value_data_source_template.dart';

final log = printer("UserConfigRepository");

/// deals with storing and retrieiving values for UserCOnfig model
class UserConfigRepository {
  final IKeyValueDataSource keyValueDataSource;

  UserConfigRepository({required this.keyValueDataSource});

  /// Sets the default values of userConfig into key-value store if not present
  Future<void> setDefaultIdNotPresent(String userId) async {
    String? value = keyValueDataSource.getValue(userId);
    if (value == null) {
      log.i("Setting default values for $userId");
      final userConfigMap =
          jsonEncode(UserConfigModel(userId: userId).toJson());
      await keyValueDataSource.setValue(userId, userConfigMap);
      return;
    }
  }

  /// Get the value of userconfig from key-value store
  Future<UserConfigModel> getValue(String userId) async {
    await setDefaultIdNotPresent(userId);
    return UserConfigModel.fromJson(
        jsonDecode(keyValueDataSource.getValue(userId)!));
  }

  /// Set the key-value pair for particular user
  Future<UserConfigModel> setValue(
      String userId, String key, dynamic value) async {
    await setDefaultIdNotPresent(userId);

    var userConfigMap = jsonDecode(keyValueDataSource.getValue(userId)!);
    userConfigMap = {...userConfigMap, key: value};
    keyValueDataSource.setValue(userId, jsonEncode(userConfigMap));
    return UserConfigModel.fromJson(
        jsonDecode(keyValueDataSource.getValue(userId)!));
  }
}
