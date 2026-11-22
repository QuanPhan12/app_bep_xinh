const chatHistoryPageSize = 6;

typedef LoadOlderMessages<T> = Future<ChatHistoryPage<T>> Function();

class ChatHistoryPage<T> {
  /// Messages in chronological order, oldest first.
  final List<T> messages;
  final LoadOlderMessages<T>? loadOlder;

  const ChatHistoryPage(this.messages, {this.loadOlder});
}
