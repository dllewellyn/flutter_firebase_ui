import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

enum LoginState {
  LOGGED_IN,
  LOADING,
  NO_STATE,
  FAILED,
  CHECKING_EMAIL,
  EMAIL_EXISTS,
  EMAIL_NOT_EXISTS
}

class LoginUIBloc {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamController<LoginState> _streamController =
  BehaviorSubject<LoginState>();

  Stream<LoginState> get stream => _streamController.stream;

  void reset() {
    _streamController.add(LoginState.NO_STATE);
  }

  void tryLogin() {
    _streamController.add(LoginState.LOADING);
  }

  void failedLogin() {
    _streamController.add(LoginState.FAILED);
  }

  void checkEmail(String email) {
    _streamController.add(LoginState.CHECKING_EMAIL);
    _auth.fetchSignInMethodsForEmail(email: email).then((b) =>
        _streamController.add((b != null && b.isNotEmpty)
            ? LoginState.EMAIL_EXISTS
            : LoginState.EMAIL_NOT_EXISTS));
  }

  void refresh() {
    _auth.currentUser().then((user) {
      if (user != null) {
        _streamController.add(LoginState.LOGGED_IN);
      }
    });
  }


  void createUserWithEmailAndPassword({String email, String password}) {
    _auth.createUserWithEmailAndPassword(email: email, password: password).then(
            (result) =>
        result.uid != null
            ? _streamController.add(LoginState.LOGGED_IN)
            : _streamController.add(LoginState.FAILED))
        .catchError((err) {
      print(err);
      _streamController.add(LoginState.FAILED);
    });
  }

  void signInWithEmailAndPassword({String email, String password}) {
    _auth.signInWithEmailAndPassword(email: email, password: password).then(
            (result) =>
        result.uid != null
            ? _streamController.add(LoginState.LOGGED_IN)
            : _streamController.add(LoginState.FAILED)).catchError((err) {
      print(err);
      _streamController.add(LoginState.FAILED);
    });
  }

  void dispose() {
    _streamController.close();
  }
}
