import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'dart:ui';

// AppState (immutable)
class AppState{
  List<ChatMessage> messages = new List<ChatMessage>();

  bool isComposing = false;
  AppState(this.messages);
}
// Action (immutable)
abstract class Action {}
class SendAction extends Action {
  final ChatMessage message;
  final TextEditingController textController;
  SendAction(this.message, this.textController);
}
class ComposingAction extends Action {
  bool composing;
  ComposingAction(this.composing);
}

// Reducer
AppState reducer(AppState prev, dynamic action) {
  if (action is SendAction) {

    action.message.animationController.forward();
    AppState newState = new AppState(prev.messages);

    if (newState.messages == null) {
      newState.messages = new List<ChatMessage>();
      newState.messages.add(action.message);

    } else {
      newState.messages.insert(0, action.message);
    }
    action.textController.clear();

    return newState;
  } else if (action is ComposingAction) {
    AppState newState = new AppState(prev.messages);
    newState.isComposing = action.composing;
    return newState;
  }
  return prev;
}


// store that holds our current AppState obj
final store = new Store<AppState>(
  reducer,
  initialState: new AppState(null),
);
// Define ios theme and android theme
final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent,
);
void main() => runApp(
  new MaterialApp(
    theme: defaultTargetPlatform == TargetPlatform.iOS ? kIOSTheme : kDefaultTheme ,
    title: "FriendlyChat",
    home: new ChatScreen(),
  )
);
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = new TextEditingController();

  Widget _buildTextComposer() {
    return new StoreProvider<AppState>(
      store: store,
      child: new IconTheme(
          data: new IconThemeData(color: Theme.of(context).accentColor),
          child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new Row(
                children: <Widget>[
                  new Flexible(
                    child: new StoreConnector<AppState, Function>(
                      converter: (store) {
                        return (action) => store.dispatch(action);
                      },
                      builder: (context, callback) {
                        return new TextField(
                          onChanged: (String s) {
                            callback(new ComposingAction(s.length > 0));
                          },
                          controller: _textController,
                          onSubmitted: (String text) {
                            ChatMessage cm = new ChatMessage(
                                text: text,
                                animationController: new AnimationController(
                                  duration: new Duration(milliseconds: 1000),
                                  vsync: this,));
                            callback(new SendAction(cm, _textController));
                          },
                          decoration: new InputDecoration.collapsed(
                              hintText: "Send a message"),
                        );

                      }
                    ),
                  ),

                  // the send button
                  new Container(
                    margin: new EdgeInsets.symmetric(horizontal: 4.0),
                    child: new StoreConnector<AppState, Store<AppState>>(
                        builder: (context, store) {
                          return Theme.of(context).platform == TargetPlatform.iOS ?
                            new CupertinoButton(
                              child: new Text("Send"),
                              onPressed: store.state.isComposing ? (){

                                AnimationController ani = new AnimationController(
                                  duration: new Duration(milliseconds: 1000),
                                  vsync: this,);
                                store.dispatch(new SendAction(new ChatMessage(text: _textController.text, animationController: ani ), _textController));

                              } : null

                            ) :
                            new IconButton(
                              icon: new Icon(Icons.send),
                                onPressed: store.state.isComposing ? (){

                                  AnimationController ani = new AnimationController(
                                    duration: new Duration(milliseconds: 1000),
                                    vsync: this,);
                                  store.dispatch(new SendAction(new ChatMessage(text: _textController.text, animationController: ani ), _textController));

                                } : null
                            );
                          },
                        converter: (store) {
                          return store;
                        }
                    )
                  )





                ],
              )
          ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return new StoreProvider<AppState>(
      store: store,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text("Friendly Chat By Jack"),
          elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        ),
        body: new Container(
          child: new Column(
            children: <Widget>[

              // a list of messages in chronological order
              new StoreConnector<AppState, List<ChatMessage>>(
                  builder: (_, messages){
                    return new Flexible(
                      child: new ListView.builder(
                        itemBuilder: (_, int index) => messages[index],
                        reverse: true,
                        padding: new EdgeInsets.all(8.0),
                        itemCount: messages?.length == null ? 0 : messages.length,
                      ),

                    );
                  },
                  converter: (store) => store.state.messages,
              ),

              new Divider(height: 1.0,),


              // this part lies at the bottom of the screen. it consists of textfield
              // and send button.
              new Container(
                decoration: new BoxDecoration(
                  color: Theme.of(context).cardColor,
                ),
                child: _buildTextComposer(),
              )
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS ?
            new BoxDecoration(
              border: new Border(
                top: new BorderSide(color: Colors.grey[200])
              )
            ) :
            null,
        ),
      ),
    );
  }
}


String _name = "Jack Wong";

// Model
// to construct a chat message.
class ChatMessage extends StatelessWidget {
  final String text;
  final AnimationController animationController;
  ChatMessage({this.text, this.animationController});
  @override
  Widget build(BuildContext context) {
    return new FadeTransition(
      opacity: new CurvedAnimation(
          parent: this.animationController,
          curve: Curves.easeOut),
      child: Container(
        margin: new EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // circular avatar as the leftmost item
            new Container(
              margin: new EdgeInsets.only(right: 16.0),
              child: new CircleAvatar(child: new Text(_name[0]),),
            ),

            // this is the part where message is displayed, tgt with the name of
            // the message creator.
            new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(_name, style: Theme.of(context).textTheme.subhead,),
                  new Container(
                    margin: new EdgeInsets.only(top: 5.0),
                    child: new Text(text),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
