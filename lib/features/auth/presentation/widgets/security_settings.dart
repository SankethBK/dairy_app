import 'package:dairy_app/core/constants/exports.dart';
import 'package:dairy_app/features/auth/core/exports.dart';
import 'package:dairy_app/features/auth/presentation/bloc/user_config/user_config_cubit.dart';

// ignore: must_be_immutable
class SecuritySettings extends StatelessWidget {
  late IAuthenticationRepository authenticationRepository;

  SecuritySettings({Key? key}) : super(key: key) {
    authenticationRepository = sl<IAuthenticationRepository>();
  }

  @override
  Widget build(BuildContext context) {
    final authSessionBloc = BlocProvider.of<AuthSessionBloc>(context);
    final userConfigCubit = BlocProvider.of<UserConfigCubit>(context);

    final mainTextColor = Theme.of(context)
        .extension<NoteCreatePageThemeExtensions>()!
        .mainTextColor;

    final inactiveTrackColor = Theme.of(context)
        .extension<SettingsPageThemeExtensions>()!
        .inactiveTrackColor;

    final activeColor =
        Theme.of(context).extension<SettingsPageThemeExtensions>()!.activeColor;

    return BlocBuilder<UserConfigCubit, UserConfigState>(
      builder: (context, state) {
        var isFingerPrintLoginEnabledValue =
            state.userConfigModel!.isFingerPrintLoginEnabled;

        final userId = state.userConfigModel?.userId;
        return SimpleAccordion(
          headerColor: mainTextColor,
          headerTextStyle: TextStyle(
            color: mainTextColor,
            fontSize: 16,
          ),
          children: [
            AccordionHeaderItem(
              title: "Security Settings",
              children: [
                AccordionItem(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: SettingsTile(
                            child: Text(
                              AppLocalizations.of(context).changePassword,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: mainTextColor,
                              ),
                            ),
                            onTap: () async {
                              if (userId == null) {
                                showToast(AppLocalizations.of(context)
                                    .unexpectedErrorOccured);
                                return;
                              }

                              if (userId == GuestUserDetails.guestUserId) {
                                showToast(AppLocalizations.of(context)
                                    .pleaseSetupYourAccountToUseThisFeature);
                                return;
                              }
                              String? result = await passwordLoginPopup(
                                context: context,
                                submitPassword: (password) =>
                                    authenticationRepository.verifyPassword(
                                        userId, password),
                              );

                              // old password will be retrieved from previous dialog
                              if (result != null) {
                                passwordResetPopup(
                                  context: context,
                                  submitPassword: (newPassword) =>
                                      authenticationRepository.updatePassword(
                                    authSessionBloc.state.user!.email,
                                    result,
                                    newPassword,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Material(
                          color: Colors.transparent,
                          child: SettingsTile(
                            child: Text(
                              AppLocalizations.of(context).changeEmail,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: mainTextColor,
                              ),
                            ),
                            onTap: () async {
                              if (userId == null) {
                                showToast(AppLocalizations.of(context)
                                    .unexpectedErrorOccured);
                              }

                              if (userId == GuestUserDetails.guestUserId) {
                                showToast(AppLocalizations.of(context)
                                    .pleaseSetupYourAccountToUseThisFeature);
                              }

                              String? result = await passwordLoginPopup(
                                context: context,
                                submitPassword: (password) =>
                                    authenticationRepository.verifyPassword(
                                        authSessionBloc.state.user!.id,
                                        password),
                              );

                              // old password will be retrieved from previous dialog
                              dynamic emailChanged;
                              if (result != null) {
                                emailChanged = await emailChangePopup(
                                  context,
                                  (newEmail) =>
                                      authenticationRepository.updateEmail(
                                    oldEmail: authSessionBloc.state.user!.email,
                                    password: result,
                                    newEmail: newEmail,
                                  ),
                                );
                              }

                              if (emailChanged == true) {
                                authSessionBloc.add(UserLoggedOut());
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          inactiveTrackColor: inactiveTrackColor,
                          activeColor: activeColor,
                          contentPadding: const EdgeInsets.all(0.0),
                          title: Text(
                            AppLocalizations.of(context).enableFingerPrintLogin,
                            style: TextStyle(color: mainTextColor),
                          ),
                          subtitle: Text(
                            AppLocalizations.of(context)
                                .fingerPrintAthShouldBeEnabledInDeviceSettings,
                            style: TextStyle(color: mainTextColor),
                          ),
                          value: isFingerPrintLoginEnabledValue ?? false,
                          onChanged: (value) async {
                            if (userId == null) {
                              showToast(AppLocalizations.of(context)
                                  .unexpectedErrorOccured);
                              return;
                            }

                            if (userId == GuestUserDetails.guestUserId) {
                              showToast(AppLocalizations.of(context)
                                  .pleaseSetupYourAccountToUseThisFeature);
                              return;
                            }

                            try {
                              await authenticationRepository
                                  .isFingerprintAuthPossible();
                              userConfigCubit.setUserConfig(
                                UserConfigConstants.isFingerPrintLoginEnabled,
                                value,
                              );
                            } on Exception catch (e) {
                              showToast(
                                  e.toString().replaceAll("Exception: ", ""));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
