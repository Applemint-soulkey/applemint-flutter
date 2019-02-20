import 'package:flutter/material.dart';
import 'package:applemint/main.dart';
import 'package:http/http.dart' as http;
import 'package:splashscreen/splashscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

class AuthData {
  final String name;
  final String email;
  final String token;
  AuthData({this.name, this.email, this.token});
  AuthData.fromJson(Map<String, dynamic> json):
        name = json['name'],
        email = json['email'],
        token = json['token'];
}

class LoginSplash extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _LoginSplashState();
  }
}

class _LoginSplashState extends State<LoginSplash>{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new SplashScreen(
      seconds: 5,
      image: Image(image: AssetImage("images/logo_white.png")),
      title: Text(""),
      styleTextUnderTheLoader: TextStyle(color: Colors.green[700]),
      photoSize: 150,
      backgroundColor: Colors.green[700],
      navigateAfterSeconds: FutureBuilder<Widget>(
        future: getNextWidget(),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.hasData) {
            return snapshot.data;
          } else {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    Text(
                      "\nWaiting for Server Response..\nIf this screnn still showing, \nCheck Peppermint Server!",
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              )
            );
          }
        }
      ),
    );
  }
  Future<Widget> getNextWidget() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool _autoLogin = sharedPreferences.getBool('autoLogin') ?? false;
    if(_autoLogin){
      String _email = sharedPreferences.getString('email') ?? "";
      String _password = sharedPreferences.getString('password') ?? "";
      await getAuthToken(_email, _password).then((String token) async {
        authToken = token;
      });
      if (authToken == null) {
        return LoginPage();
      } else {
        return new AppleMintHome();
      }
    }else{
      return new LoginPage();
    }
  }
}

class LoginPage extends StatefulWidget{

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailFilter = new TextEditingController();
  final TextEditingController _passwordFilter = new TextEditingController();
  final GlobalKey<ScaffoldState> loginScaffoldKey = new GlobalKey<ScaffoldState>();

  SharedPreferences sharedPreferences;
  String _email="";
  String _password="";
  bool _rememberEmail=false;
  bool _autoLogin=false;

  @override
  void initState() {
    super.initState();
    _emailFilter.addListener(_emailListener);
    _passwordFilter.addListener(_passwordListener);
    getCredential();
  }

  getCredential() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      _rememberEmail = sharedPreferences.getBool('rememberEmail') ?? false;
      _autoLogin = sharedPreferences.getBool('autoLogin') ?? false;
      if(_rememberEmail){
        _emailFilter.text = sharedPreferences.getString('email') ?? "";
      }
    });
  }

  setSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool('rememberEmail', _rememberEmail);
    sharedPreferences.setBool('autoLogin', _autoLogin);
    if(_rememberEmail){
      sharedPreferences.setString('email', _email);
    }
    if(_autoLogin){
      sharedPreferences.setString('password', _password);
    }
  }

  @override
    Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      key: loginScaffoldKey,
        backgroundColor: Colors.green[100],
        body: Center(
          child: Container(
            padding: EdgeInsets.all(30),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image(
                    image: AssetImage('images/logo.png'),
                  ),
                  TextField(
                    controller: _emailFilter,
                    decoration: InputDecoration(
                      labelText: "Email",
                    ),
                  ),
                  TextField(
                    controller: _passwordFilter,
                    decoration: InputDecoration(
                      labelText: "Password",
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  ButtonTheme(
                    minWidth: 300,
                    child: RaisedButton(
                      textColor: Colors.white,
                      child: Text("Login"),
                      color: Theme.of(context).accentColor,
                      onPressed: () {
                        getAuthToken(_email, _password).then((String token) async {
                          authToken = token;
                          if (token == null) {
                            print("token is null");
                            loginScaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text("Can't Login to Server,\nCheck your Email and Password"),
                            ));
                          } else {
                            await setSharedPreferences();
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AppleMintHome()));
                          }
                        });
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: (){
                      _toggleRememberEmail();
                    },
                    child: Row(
                      children: <Widget>[
                        Checkbox(
                            value: _rememberEmail,
                            onChanged: (bool value){
                              _toggleRememberEmail();
                            }
                        ),
                        Text("Remeber Your Email")
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: (){
                      _toggleAutoLogin();
                    },
                    child: Row(
                      children: <Widget>[
                        Checkbox(
                            value: _autoLogin,
                            onChanged: (bool value){
                              _toggleAutoLogin();
                            }
                        ),
                        Text("Auto Login")
                      ],
                    ),
                  )
                ],
              ),
            )
          ),
        )
    );
  }

  _emailListener() {
    if (_emailFilter.text.isEmpty) {
      _email = "";
    } else {
      _email = _emailFilter.text;
    }
  }

  _passwordListener() {
    if (_passwordFilter.text.isEmpty) {
      _password = "";
    } else {
      _password = _passwordFilter.text;
    }
  }

  _toggleRememberEmail(){
    setState(() {
      if(_rememberEmail){
        _rememberEmail=false;
      }else{
        _rememberEmail=true;
      }
    });
  }

  _toggleAutoLogin(){
    setState(() {
      if(_autoLogin){
        _autoLogin=false;
      }else{
        _autoLogin=true;
      }
    });
  }
}

Future<String> getAuthToken(String _email, String _password) async {
  var loginData = {
    "email": _email,
    "password":_password
  };
  print(peppermint + 'auth/login/');
  print(loginData);

  http.Response response = await http.post(
    peppermint + 'auth/login/',
    body: loginData,
  );
  if (response.statusCode == HttpStatus.ok && response.body.isNotEmpty) {
    print(response.body);
    var responseJson = json.decode(response.body);
    var authData = new AuthData.fromJson(responseJson);
    userEmail = authData.email;
    userName = authData.name;
    return authData.token;
  } else {
    return null;
  }
}

