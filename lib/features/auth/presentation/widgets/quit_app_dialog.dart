import 'package:dairy_app/app/themes/theme_extensions/popup_theme_extensions.dart';
import 'package:dairy_app/core/widgets/cancel_button.dart';
import 'package:dairy_app/core/widgets/glass_dialog.dart';
import 'package:dairy_app/core/widgets/submit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<bool> quitAppDialog(BuildContext context) async {
  final mainTextColor =
      Theme.of(context).extension<PopupThemeExtensions>()!.mainTextColor;

  return await showCustomDialog(
    context: context,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            AppLocalizations.of(context).closeTheApp,
            style: TextStyle(
              fontSize: 18.0,
              color: mainTextColor,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              CancelButton(
                buttonText: "No",
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              const SizedBox(width: 10),
              SubmitButton(
                isLoading: false,
                onSubmitted: () => Navigator.pop(context, true),
                buttonText: "Yes",
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
