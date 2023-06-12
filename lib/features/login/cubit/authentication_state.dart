part of 'authentication_cubit.dart';

@freezed
class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState.unauthenticated() = _Unauthenticated;
  const factory AuthenticationState.requriresLocalAuthentication() =
      _RequiresLocalAuthentication;
  const factory AuthenticationState.authenticated({
    required String localUserId,
    required int apiVersion,
  }) = _Authenticated;
  const factory AuthenticationState.switchingAccounts() = _SwitchingAccounts;
}
