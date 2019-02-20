import 'package:flutter/material.dart';
import 'package:applemint/main.dart';
import 'package:applemint/WebView.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';


class Item {
  final String title;
  final String domain;
  final String url;

  Item({this.title, this.domain, this.url});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      title: json['title'],
      domain: json['domain'],
      url: json['url'],
    );
  }
}

class ItemList extends StatefulWidget {
  final String target;
  final bool activeBtn;

  ItemList({Key key, @required this.target, this.activeBtn}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ItemListState();
  }
}

class _ItemListState extends State<ItemList> with AutomaticKeepAliveClientMixin<ItemList> {
  List<Item> items = new List();
  RefreshController _refreshController;
  Future<List<Item>> future;

  @override
  void initState(){
    _refreshController = new RefreshController();
    future = fetchPost(widget.target);
    super.initState();
  }

  Widget _buildItem(TARGET tag, Item item, [int index]) {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            key: ValueKey<Item>(item),
            title: Text(
              item.title,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.url,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context)
                    => WebView(
                      parent: this,
                      target: tag,
                      title: item.title,
                      url: item.url,
                      domain: item.domain,
                      index: index,
                      activeFab: widget.activeBtn,
                    )
                ));
            },
          ),
          widget.activeBtn ?
          Row(
            children: <Widget>[
              MaterialButton(
                minWidth: 10,
                child: Text("REMOVE", style: TextStyle(color: Colors.blue),),
                onPressed: () async {
                  await _postVisitEvent(tag, item.title, item.url, item.domain, false);
                  setState(() {
                    items.removeAt(index);
                  });
                }),
              Spacer(),
              IconButton(
                color: Colors.black26,
                  icon: Icon(Icons.bookmark),
                  onPressed: () async {
                    await _postVisitEvent(tag, item.title, item.url, item.domain, true);
                    setState(() {
                      items.removeAt(index);
                    });
                  }
              )
            ],
          ) : Container()
        ],
    ));
  }

  @override
  Widget build(BuildContext context) {

    TARGET tag;
    switch(widget.target){
      case peppermint+'mint/hrm':
        tag = TARGET.HRM;
        break;
      case peppermint+'mint/bp':
        tag = TARGET.BP;
        break;
      case peppermint+'mint/dd':
        tag = TARGET.DD;
        break;
    }
    super.build(context);
    // TODO: implement build
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          items = snapshot.data;
          if (items.length == 0) {
            return Container(
              alignment: Alignment.center,
              color: Colors.green[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'No Item on Firestore :)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  FlatButton(
                      onPressed: (){
                        setState(() {
                          future = fetchPost(widget.target);
                        });
                      },
                      child: Text(
                        "Refresh",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline
                        ),
                      )
                  )
                ],
              )
            );
          } else {
            return Container(
              padding: EdgeInsets.all(10),
              color: Colors.green[100],
              child: SmartRefresher(
                enablePullDown: true,
                onRefresh: _onRefresh,
                controller: _refreshController,
                child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index){
                      return _buildItem(tag, items[index], index);
                    }
                  )
              ),
            );
          }
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        // By default, show a loading spinner
        return Container(
          color: Colors.green[100],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(),
              Text(
                  "\nLoad Data from Peppermint..\nIf this process is too long,\nCheck your network or Restart Applemint!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      });
  }

  void _onRefresh(bool up){
    if(up){
      new Future.delayed(const Duration(milliseconds: 100)).then((val){
        return fetchPost(widget.target);
      }).then((result){
        if(result == null){
          _refreshController.sendBack(true, RefreshStatus.failed);
        }else{
          items = result;
          setState(() {});
          _refreshController.sendBack(true, RefreshStatus.completed);
        }
      });
    }
  }

  _postVisitEvent(TARGET target, String title, String url, String domain, bool flagBmk, [bool msgDisable]) async {
    bool showMsg = msgDisable ?? true;
    var mintTarget;
    var requestBody = {
      'client':'applemint',
      'flag_bmk': flagBmk,
      'req_data':[{
        'title':title,
        'domain':domain,
        'url':url
      }]
    };

    switch(target){
      case TARGET.HRM:
        mintTarget = peppermint+'mint/hrm';
        break;
      case TARGET.BP:
        mintTarget = peppermint+'mint/bp';
        break;
      case TARGET.DD:
        mintTarget = peppermint+'mint/dd';
        break;
    }

    var response = await http.put(
      mintTarget,
      headers: {
        "Content-Type":"application/json",
        "Authorization":authToken
      },
      body: json.encode(requestBody),
    ).catchError((){
      return false;
    });

    if(response.statusCode == HttpStatus.ok){
      showMsg ?
      mainScaffoldKey.currentState.showSnackBar(SnackBar(
        content: flagBmk ? Text("'"+title+"'\nThis Item is moved to Bookmark") : Text("'"+title+"'\nPage checked and Recorded"),
        duration: Duration(seconds: 1),
      )): debugPrint("cloud_submmit");
    }
    else {
      debugPrint("muta/error");
      mainScaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Submit Fail.. Please check peppermint!"),
        duration: Duration(seconds: 1),
      ));
    }
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

Future<List<Item>> fetchPost(String target) async {
  debugPrint("Get Item from Server!");
  http.Response response =
      await http.get(target, headers: {"authorization": authToken});
  if (response.statusCode == HttpStatus.ok) {
    List responseJson = json.decode(response.body);
    return responseJson.map((m) => new Item.fromJson(m)).toList();
  } else {
    return null;
  }
}