import 'package:equatable/equatable.dart';

class OldAuthenticationState with EquatableMixin {
  final bool showBiometricAuthenticationScreen;
  final bool isAuthenticated;
  final String? username;
  final String? fullName;
  final String? localUserId;
  final int? apiVersion;

  const OldAuthenticationState({
    this.isAuthenticated = false,
    this.showBiometricAuthenticationScreen = false,
    this.username,
    this.fullName,
    this.localUserId,
    this.apiVersion,
  });

  OldAuthenticationState copyWith({
    bool? isAuthenticated,
    bool? showBiometricAuthenticationScreen,
    String? username,
    String? fullName,
    String? localUserId,
    int? apiVersion,
  }) {
    return OldAuthenticationState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      showBiometricAuthenticationScreen: showBiometricAuthenticationScreen ??
          this.showBiometricAuthenticationScreen,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      localUserId: localUserId ?? this.localUserId,
      apiVersion: apiVersion ?? this.apiVersion,
    );
  }

  @override
  List<Object?> get props => [
        localUserId,
        username,
        fullName,
        isAuthenticated,
        showBiometricAuthenticationScreen,
        apiVersion,
      ];
}
