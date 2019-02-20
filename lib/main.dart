import 'package:flutter/material.dart';
import 'package:applemint/BookMark.dart';
import 'package:applemint/Login.dart';
import 'package:applemint/ItemList.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

enum TARGET {HRM, BP, DD}

final GlobalKey<ScaffoldState> mainScaffoldKey = new GlobalKey<ScaffoldState>();
const String peppermint = 'https://soulkey-peppermint.appspot.com/';
//const String peppermint = 'http://10.0.2.2:3000/';
String authToken = "";
String userEmail = "";
String userName = "";

void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppleMint',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Rotobo'
      ),
      home: LoginSplash(),
      //debugShowCheckedModeBanner: false,
    );
  }
}

class AppleMintHome extends StatelessWidget{
  logOut() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool('autoLogin', false);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: mainScaffoldKey,
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                  accountName: Text(userName),
                  accountEmail: Text(userEmail)
              ),
              ListTile(
                leading: Icon(Icons.bookmark),
                title: Text("Bookmark"),
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Bookmark()));
                },
              ),
              ListTile(
                leading: Icon(Icons.assignment_return),
                title: Text("Log out"),
                onTap: (){
                  logOut();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginPage()));
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text("Exit"),
                onTap:()=> exit(0)
              ),
            ],
          ),
        ),
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.menu),
              tooltip: 'Navigation Menu',
              onPressed: (){
                mainScaffoldKey.currentState.openDrawer();
              }),
          title: Text('AppleMint'),
          bottom: TabBar(tabs: [
            Tab(text: "HRM"),
            Tab(text: "BP"),
            Tab(text: "DD",),
          ]),
        ),
        body: TabBarView(
          children: <Widget>[
            ItemList(target: peppermint+'mint/hrm', activeBtn: true,),
            ItemList(target: peppermint+'mint/bp', activeBtn: true,),
            ItemList(target: peppermint+'mint/dd', activeBtn: true,),
          ],
        ),
      ),
    );
  }
}

