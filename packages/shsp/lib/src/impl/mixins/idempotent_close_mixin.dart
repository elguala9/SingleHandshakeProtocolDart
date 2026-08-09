import 'package:meta/meta.dart';

mixin IdempotentCloseMixin {
  bool _closed = false;

  @protected
  bool get isClosed => _closed;

  void close() {
    if (_closed) return;
    _closed = true;
    closeImpl();
  }

  void destroy() {
    close();
  }

  @protected
  void closeImpl();
}
