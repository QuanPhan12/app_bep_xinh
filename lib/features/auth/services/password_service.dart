abstract interface class PasswordService {
  bool get canChangePassword;
  Future<void> changePassword(String currentPassword, String newPassword);
}
