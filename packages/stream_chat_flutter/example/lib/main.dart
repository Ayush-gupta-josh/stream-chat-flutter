// ignore_for_file: public_member_api_docs
// ignore_for_file: prefer_expression_function_bodies

import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Second step of the [tutorial](https://getstream.io/chat/flutter/tutorial/)
///
/// Most chat applications handle more than just one single conversation.
/// Apps like Facebook Messenger, Whatsapp and Telegram allows you to have
/// multiple one-to-one and group conversations.
///
/// Let’s find out how we can change our application chat screen to display
/// the list of conversations and navigate between them.
///
/// > Note: the SDK uses Flutter’s [Navigator] to move from one route to
/// another. This allows us to avoid any boiler-plate code.
/// > Of course, you can take total control of how navigation works by
/// customizing widgets like [StreamChannel] and [StreamChannelListView].
///
/// If you run the application, you will see that the first screen shows a
/// list of conversations, you can open each by tapping and go back to the list.
///
/// Every single widget involved in this UI can be customized or swapped
/// with your own.
///
/// The [ChannelListPage] widget retrieves the list of channels based on a
/// custom query and ordering. In this case we are showing the list of
/// channels in which the current user is a member and we order them based
/// on the time they had a new message.
/// [StreamChannelListView] handles pagination
/// and updates automatically when new channels are created or when a new
/// message is added to a channel.
void main() async {
  final client = StreamChatClient(
    's2dxdhpxd94g',
    logLevel: Level.INFO,
  );

  await client.connectUser(
    User(id: 'super-band-9'),
    '''eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoic3VwZXItYmFuZC05In0.0L6lGoeLwkz0aZRUcpZKsvaXtNEDHBcezVTZ0oPq40A''',
  );

  runApp(
    MyApp(
      client: client,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.client,
  });

  final StreamChatClient client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => StreamChat(
        client: client,
        child: child,
      ),
      home: ChannelListPage(
        client: client,
      ),
    );
  }
}

class ChannelListPage extends StatefulWidget {
  const ChannelListPage({
    super.key,
    required this.client,
  });

  final StreamChatClient client;

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  late final channelListController = StreamChannelListController(
    client: widget.client,
    filter: Filter.in_(
      'members',
      [StreamChat.of(context).currentUser!.id],
    ),
    sort: const [SortOption('last_message_at')],
  );

  @override
  void initState() {
    channelListController.doInitialLoad();
    super.initState();
  }

  @override
  void dispose() {
    channelListController.dispose();
    super.dispose();
  }

  late Channel lastChannel;
  int count = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PagedValueListenableBuilder<int, Channel>(
          valueListenable: channelListController,
          builder: (context, value, child) {
            return value.when(
              (channels, nextPageKey, error) => LazyLoadScrollView(
                onEndOfPage: () async {
                  if (nextPageKey != null) {
                    channelListController.loadMore(nextPageKey);
                  }
                },
                child: ListView.builder(
                  /// We're using the channels length when there are no more
                  /// pages to load and there are no errors with pagination.
                  /// In case we need to show a loading indicator or and error
                  /// tile we're increasing the count by 1.
                  itemCount: (nextPageKey != null || error != null)
                      ? channels.length + 1
                      : channels.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == channels.length) {
                      if (error != null) {
                        return TextButton(
                          onPressed: () {
                            channelListController.retry();
                          },
                          child: Text(error.message),
                        );
                      }
                      return CircularProgressIndicator();
                    }

                    final _item = channels[index];
                    return ListTile(
                      title: _item.extraData['hidden'] == false
                          ? Text(_item.name ?? 'Dummy')
                          : Text("Hidden"),
                      subtitle: StreamBuilder<Message?>(
                        stream: _item.state!.lastMessageStream,
                        initialData: _item.state!.lastMessage,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(snapshot.data!.text!);
                          }

                          return const SizedBox();
                        },
                      ),
                      onTap: () {
                        print(count);
                        if (_item.extraData['hidden'] == false) {
                          if (count > 0) {
                            print("object");
                            lastChannel.show();
                          }
                          _item.hide();
                          setState(() {
                            lastChannel = _item;
                            count = count + 1;
                          });
                        } else {
                          _item.show();
                        }

                        /// Display a list of messages when the user taps on
                        /// an item. We can use [StreamChannel] to wrap our
                        /// [MessageScreen] screen with the selected channel.
                        ///
                        /// This allows us to use a built-in inherited widget
                        /// for accessing our `channel` later on.
                        // Navigator.of(context).push(
                        //   MaterialPageRoute(
                        //     builder: (context) => StreamChannel(
                        //       channel: _item,
                        //       child: const MessageScreen(),
                        //     ),
                        //   ),
                        // );
                      },
                    );
                  },
                ),
              ),
              loading: () => const Center(
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e) => Center(
                child: Text(
                  'Oh no, something went wrong. '
                  'Please check your config. $e',
                ),
              ),
            );
          },
        ),
      );
}

class ChannelPage extends StatelessWidget {
  const ChannelPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const StreamChannelHeader(),
        body: Column(
          children: const <Widget>[
            Expanded(
              child: StreamMessageListView(),
            ),
            StreamMessageInput(),
          ],
        ),
      );
}
