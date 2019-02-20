import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:unicorndial/unicorndial.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:applemint/main.dart';
import 'package:applemint/ItemList.dart';
import 'dart:io';
import 'dart:convert';

class WebView extends StatefulWidget{
  final TARGET target;
  final String title;
  final String url;
  final String domain;
  final int index;
  final bool activeFab;
  final State<ItemList> parent;

  WebView({Key key, this.target, this.title, this.url, this.domain, this.index, this.activeFab, this.parent}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _WebViewState();
  }
}

class _WebViewState extends State<WebView>{
  final GlobalKey<ScaffoldState> _webViewScaffoldKey = new GlobalKey<ScaffoldState>();
  InAppWebViewController webView;
  String innerHTML;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      key: _webViewScaffoldKey,
        appBar: AppBar(
          title: Text("Web Viewer"),
        ),
        body: ModalProgressHUD(
            opacity: 0.5,
            inAsyncCall: isLoading,
            child: Container(
              child: InAppWebView(
                initialUrl: widget.url,
                onWebViewCreated: (controller) {
                  webView = controller;
                },
              ),
            )
        ),
        floatingActionButton: widget.activeFab ? UnicornDialer(
          backgroundColor: Color.fromRGBO(255, 255, 255, 0.6),
          parentButtonBackground: Colors.green,
          orientation: UnicornOrientation.VERTICAL,
          parentButton: Icon(Icons.add),
          childButtons: [
            UnicornButton(
              currentButton: FloatingActionButton(
                  heroTag: "Checked",
                  backgroundColor: Colors.red,
                  mini: true,
                  child: Icon(Icons.check),
                  onPressed: () async {
                    await _postVisitEvent(widget.target, widget.title, widget.url, widget.domain, false);
                    widget.parent.initState();
                  }
              ),
            ),
            UnicornButton(
              currentButton: FloatingActionButton(
                  heroTag: "Upload",
                  backgroundColor: Colors.orange,
                  mini: true,
                  child: Icon(Icons.cloud_upload),
                  onPressed: () async {
                    await doCloudAction(webView, widget.target, widget.title, widget.url, widget.domain);
                    widget.parent.initState();
                  }
              ),
            ),
            UnicornButton(
              currentButton: FloatingActionButton(
                  heroTag: "Bookmark",
                  backgroundColor: Colors.blueAccent,
                  mini: true,
                  child: Icon(Icons.bookmark),
                  onPressed: () async {
                    await _postVisitEvent(widget.target, widget.title, widget.url, widget.domain, true);
                    widget.parent.initState();
                  }
              ),
            ),
          ],
        ): null
    );
  }

  _postVisitEvent(TARGET target, String title, String url, String domain, bool flagBmk, [bool msgDisable]) async {
    bool showMsg = msgDisable ?? true;
    setState(() {
      isLoading = true;
    });
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

    setState(() {
      isLoading = false;
    });

    if(response.statusCode == HttpStatus.ok){
      Navigator.of(context).pop(true);
//      Navigator.pop(context, true);
      showMsg ?
      mainScaffoldKey.currentState.showSnackBar(SnackBar(
        content: flagBmk ? Text("'"+title+"'\nThis Item is moved to Bookmark") : Text("'"+title+"'\nPage checked and Recorded"),
        duration: Duration(seconds: 2),
      )): debugPrint("cloud_submmit");
    }
    else {
      debugPrint("muta/error");
      _webViewScaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Submit Fail.. Please check peppermint!"),
        duration: Duration(seconds: 2),
      ));
    }
  }

  doCloudAction(InAppWebViewController controller, TARGET target, String title, String url, String domain) async {
    setState(() {
      isLoading = true;
    });
    var targetDomain;
    var targetTitle;
    var selectorQuery;

    if(domain == 'v12.battlepage.com'){
      targetDomain = 'http://v12.battlepage.com';
      selectorQuery = '.search_content';
    }
    else if(domain  == 'www.dogdrip.net'){
      targetDomain = 'https://www.dogdrip.net';
      selectorQuery = '#article_1 > div';
    }else{
      mainScaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Unsupported Domain.. :<"),
        duration: Duration(seconds: 1),
      ));
      return;
    }

    var innerHTML = await controller.injectScriptCode("document.getElementsByTagName('html')[0].innerHTML");
    var document = parse(innerHTML);
    List<dom.Element> imgList =  document.querySelector(selectorQuery).getElementsByTagName("img");
    targetTitle = title.replaceAll(" ", "_");

    if(imgList.length == 1){
      var imgUrl = getAttribute('src', imgList.elementAt(0));
      if(imgUrl.startsWith("/")){
        imgUrl = targetDomain+imgUrl;
      }
      var savePath = targetTitle+imgUrl.substring(imgUrl.lastIndexOf('.'));
      _postDapina(imgUrl, savePath);
    }else{
      for(int i=0; i<imgList.length; i++){
        var imgUrl = getAttribute('src', imgList.elementAt(i));
        if(imgUrl.startsWith("/")){
          imgUrl = targetDomain+imgUrl;
        }
        var savePath = targetTitle+"/"+i.toString().padLeft(3, '0')+imgUrl.substring(imgUrl.lastIndexOf('.'));
        _postDapina(imgUrl, savePath);
      }
    }
    mainScaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text("'"+title+"'\nImages of this page will be upload to Dropbox.."),
      duration: Duration(seconds: 1),
    ));
    await _postVisitEvent(target, title, url, domain, false, false);
    setState(() {
      isLoading = false;
    });
  }

  String getAttribute(String attributeName, dom.Element element){
    var imgElement = element.attributes.entries;
    var imgUrl = "";
    for(int i=0; i<imgElement.length; i++){
      if(imgElement.elementAt(i).key == attributeName){
        imgUrl = imgElement.elementAt(i).value;
      }
    }
    print(imgUrl);
    return imgUrl;
  }

  _postDapina(String srcUrl, String savePath) async {
    var dapinaUrl = "https://api.dropboxapi.com/2/files/save_url";
    var authToken = "Bearer FMwnuyPWJdsAAAAAAAB42rajrfht7VYrlXL8F_SoyCQYjvgEh-u-x7z49fS7WloT";
    var targetPath = "/dapina/";
    var requestBody = {
      'path':targetPath+savePath,
      'url':srcUrl
    };

    var response = await http.post(
        dapinaUrl,
        headers: {
          "Content-Type":"application/json",
          "Authorization": authToken
        },
        body: json.encode(requestBody)
    );

    if(response.statusCode == HttpStatus.ok){
      debugPrint("muta/suceess");
      debugPrint(response.body);
    }else{
      debugPrint("muta/error");
    }
  }
}

