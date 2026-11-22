import 'dart:async';

import 'package:app_bep_xinh/features/auth/cubits/login/login.dart';
import 'package:app_bep_xinh/features/auth/cubits/register/register.dart';
import 'package:app_bep_xinh/features/auth/cubits/forgot_password/forgot_password.dart';
import 'package:app_bep_xinh/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_fake.dart';

void main() {
  late StubAuthService auth;
  setUp(() => auth = StubAuthService());
  tearDown(() => auth.dispose());

  test(
    'Google sign-in needs no password and blocks duplicate/password submits',
    () async {
      final pending = Completer<void>();
      auth.operation = () => pending.future;
      final cubit = LoginCubit(service: auth);
      addTearDown(cubit.close);
      final task = cubit.submitGoogleLogin();
      await cubit.submitGoogleLogin();
      await cubit.submitLogin();
      expect(cubit.state.method, LoginMethod.google);
      expect(auth.googleSignInCalls, 1);
      expect(auth.signInCalls, 0);
      pending.complete();
      await task;
      expect(cubit.state.status, LoginStatus.success);
    },
  );

  test(
    'canceling Google picker restores form without error or losing text',
    () async {
      final cubit = LoginCubit(service: auth)
        ..emailChanged('cook@example.test')
        ..passwordChanged('secret-123');
      addTearDown(cubit.close);
      auth.operation = () async => throw const AuthCancelled();
      await cubit.submitGoogleLogin();
      expect(cubit.state.status, LoginStatus.initial);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.email, 'cook@example.test');
      expect(cubit.state.password, 'secret-123');
    },
  );

  test('login normalizes email, preserves password and prevents concurrent submits', () async {
    final pending = Completer<void>();
    auth.operation = () => pending.future;
    final cubit = LoginCubit(service: auth);
    addTearDown(cubit.close);
    cubit.emailChanged(' cook@example.test ');
    cubit.passwordChanged(' secret ');
    final task = cubit.submitLogin();
    cubit.emailChanged('other@example.test');
    await cubit.submitLogin();
    expect(auth.signInCalls, 1);
    expect(auth.email, 'cook@example.test');
    expect(auth.password, ' secret ');
    expect(cubit.state.email, ' cook@example.test ');
    pending.complete();
    await task;
    expect(cubit.state.status, LoginStatus.success);
  });

  test(
    'invalid login never calls Firebase and failures can be retried',
    () async {
      final cubit = LoginCubit(service: auth);
      addTearDown(cubit.close);
      await cubit.submitLogin();
      expect(auth.signInCalls, 0);
      cubit.emailChanged('cook@example.test');
      cubit.passwordChanged('secret');
      auth.operation = () async => throw const AuthFailure('Thử lại sau');
      await cubit.submitLogin();
      expect(cubit.state.errorMessage, 'Thử lại sau');
      auth.operation = null;
      await cubit.submitLogin();
      expect(cubit.state.status, LoginStatus.success);
    },
  );

  test('closing during a request never emits a late result', () async {
    final pending = Completer<void>();
    auth.operation = () => pending.future;
    final cubit = LoginCubit(service: auth)
      ..emailChanged('cook@example.test')
      ..passwordChanged('secret');
    final task = cubit.submitLogin();
    await cubit.close();
    pending.completeError(StateError('late failure'));
    await task;
  });

  test('registration requires matching confirmation and terms before calling service', () async {
    final cubit = RegisterCubit(service: auth)
      ..nameChanged('  Đầu bếp  ')
      ..emailChanged(' cook@example.test ')
      ..passwordChanged(' secret ');
    addTearDown(cubit.close);
    await cubit.submitRegister();
    expect(auth.registerCalls, 0);
    cubit.termsAcceptedChanged(true);
    await cubit.submitRegister();
    expect(auth.registerCalls, 0);
    cubit.confirmPasswordChanged(' secret ');
    await cubit.submitRegister();
    expect(auth.name, 'Đầu bếp');
    expect(auth.password, ' secret ');
    expect(cubit.state.status, RegisterStatus.success);
  });

  test('reset reports service failure and permits retry', () async {
    final cubit = ForgotPasswordCubit(service: auth);
    addTearDown(cubit.close);
    cubit.emailChanged('cook@example.test');
    auth.operation = () async => throw const AuthFailure('Không có kết nối');
    await cubit.submitForgotPassword();
    expect(cubit.state.isEmailSent, false);
    expect(cubit.state.status, ForgotPasswordStatus.failure);
    auth.operation = null;
    await cubit.submitForgotPassword();
    expect(cubit.state.isEmailSent, true);
  });
}
