import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'firebase_ui_state.dart';

class FirebaseAuthUI extends StatefulWidget {
  final Function onComplete;
  final Widget loadingWidget;
  final TextStyle buttonStyle;
  final TextStyle textInputStyle;

  const FirebaseAuthUI({Key key,
    @required this.onComplete,
    @required this.loadingWidget,
    this.buttonStyle,
    this.textInputStyle})
      : super(key: key);

  @override
  _FirebaseAuthUIState createState() => _FirebaseAuthUIState();
}

class _FirebaseAuthUIState extends State<FirebaseAuthUI> {
  final _formKey = GlobalKey<FormState>();
  LoginUIBloc _bloc;

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();


  @override
  Widget build(BuildContext context) {

    return StreamBuilder<LoginState>(
        stream: _bloc.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == LoginState.LOADING) {
            return widget.loadingWidget;
          }

          return Center(
            child: GestureDetector(
              onTap: () => dismissKeyboard(context),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        snapshot.data == LoginState.FAILED
                            ? Text("Failed to login. Please try again")
                            : Container(),
                        TextFormField(
                            style: Theme
                                .of(context)
                                .textTheme
                                .body2,
                            decoration: InputDecoration(
                                labelText: "Email",
                                hintText: "Enter email address"),
                            controller: _emailController,
                            validator: _emailValidation),
                        snapshot.data == LoginState.CHECKING_EMAIL
                            ? Container(
                            height: 40,
                            width: 40,
                            child: widget.loadingWidget)
                            : widgetForState(snapshot.data),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }

  void dismissKeyboard(BuildContext context) =>
      FocusScope.of(context).requestFocus(new FocusNode());

  Widget widgetForState(LoginState state) {
    if (state == LoginState.EMAIL_EXISTS) {
      return Column(children: [
        TextFormField(
            obscureText: true,
            style: Theme
                .of(context)
                .textTheme
                .body2,
            controller: _passwordController,
            decoration: InputDecoration(
                labelText: "Password", hintText: "Enter password"),
            validator: _passwordValidation),
        FlatButton(
          key: Key("login"),
          onPressed: () => _validateForm(false),
          child: Text("Login", style: widget.buttonStyle),
          padding: const EdgeInsets.all(30.0),
        )
      ]);
    } else if (state == LoginState.EMAIL_NOT_EXISTS) {
      return Column(children: [
        TextFormField(
            key: Key("password"),
            obscureText: true,
            style: Theme
                .of(context)
                .textTheme
                .body2,
            controller: _passwordController,
            decoration: InputDecoration(
                labelText: "Password", hintText: "Enter password"),
            validator: _passwordValidation),
        FlatButton(
          onPressed: () => _validateForm(false),
          child: Text("Create account", style: widget.buttonStyle),
          padding: const EdgeInsets.all(30.0),
        )
      ]);
    } else {
      return FlatButton(
        key: Key("continue"),
        onPressed: () => _bloc.checkEmail(_emailController.text),
        child: Text(
          "Continue",
          style: widget.buttonStyle,
        ),
        padding: const EdgeInsets.all(30.0),
      );
    }
  }

  String _passwordValidation(String password) {
    if (password.isEmpty) {
      return "Password cannot be empty";
    }

    if (password.length < 6) {
      return "Password must be at least 6 characters long";
    }

    return null;
  }

  String _emailValidation(String value) {
    if (value.isEmpty) {
      return 'Email must not be empty';
    }

    if (!value.contains("@")) {
      return "Please enter a valid email";
    }
    return null;
  }

  Future _validateForm(bool createAccount) async {
    if (_formKey.currentState.validate()) {
      createAccount
          ? _bloc.createUserWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text)
          : _bloc.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);

      var result = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StreamBuilder<LoginState>(
                stream: _bloc.stream,
                builder: (context, snapshot) {
                  String title;
                  Widget body;

                  if (snapshot.data == LoginState.FAILED) {
                    title = "Sorry!";
                    body = OutlineButton(
                        key: Key("cancel"),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text("Something went wrong. Please try again.")
                    );
                  } else if (snapshot.data == LoginState.LOGGED_IN) {
                    title = "Done";
                    body = OutlineButton(
                        key: Key("success"),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text("Success - click to continue"));
                  } else {
                    title = "Loading...";
                    body = widget.loadingWidget;
                  }

                  return AlertDialog(
                      title: Text(
                        title,
                        style: Theme.of(context).textTheme.title,
                      ),
                      content: body);
                });
          });

      if (result != null && result == true) {
        widget.onComplete();
      }
    }
  }

  @override
  void didChangeDependencies() {
    _bloc = LoginUIBloc();
    _bloc.reset();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
