import 'package:flutter/material.dart';
import 'package:applemint/main.dart';
import 'package:applemint/ItemList.dart';

class Bookmark extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _BookmarkState();
  }
}

class _BookmarkState extends State<Bookmark>{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Bookmak"),
      ),
      body: Container(
        color: Colors.green[100],
        child: Center(
          child: ItemList(
            target: peppermint+'mint/bmk',
            activeBtn: false,
          ),
        ),
      ),
    );
  }
}