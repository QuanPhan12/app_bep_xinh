/// Mỗi caller nhận đúng kết quả/lỗi của mình; lỗi một tác vụ không chặn hàng đợi.
class AsyncSerialQueue {
  Future<void> _tail = Future.value();

  Future<void> get settled => _tail;

  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
