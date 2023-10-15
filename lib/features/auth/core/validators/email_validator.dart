import 'package:dairy_app/core/constants/exports.dart';

class EmailValidator implements Validator<String> {
  @override
  bool call(String email) {
    bool isValid = RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(email);

    if (!isValid) {
      throw InvalidEmailException.invalidEmail();
    }

    return true;
  }
}
