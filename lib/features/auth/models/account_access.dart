enum AccountAccessStatus { signedOut, checking, active, locked, unavailable }

class AccountAccess {
  final AccountAccessStatus status;
  final String? message;
  const AccountAccess(this.status, {this.message});
}

abstract interface class AccountAccessSource {
  Stream<AccountAccess> watch(String uid);
}

/// Router chỉ mở phiên sau khi trạng thái hồ sơ được xác nhận.
abstract interface class AccountSessionAccess {
  AccountAccess get accountAccess;
  Future<void> retryAccountAccess();
}
