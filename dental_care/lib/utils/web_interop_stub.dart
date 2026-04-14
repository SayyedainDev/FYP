import 'dart:async';

class StyleElement {
  String text = '';
  void remove() {}
}

class _Head {
  void append(StyleElement element) {}
}

class _DocumentElement {
  void requestFullscreen() {}
}

class _Document {
  Stream<Object?> get onVisibilityChange => const Stream.empty();
  bool? get hidden => false;
  _Head? get head => _Head();
  Stream<Object?> get onFullscreenChange => const Stream.empty();
  Object? get fullscreenElement => Object();
  _DocumentElement? get documentElement => _DocumentElement();
}

class _MediaQueryList {
  Stream<Object?> get onChange => const Stream.empty();
}

class _Window {
  Stream<Object?> get onBlur => const Stream.empty();
  _MediaQueryList matchMedia(String query) => _MediaQueryList();
}

final _Document document = _Document();
final _Window window = _Window();
