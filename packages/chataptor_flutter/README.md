# chataptor_flutter

Official Flutter widgets for [Chataptor](https://chataptor.com) — real-time multilingual customer support chat.

Built on top of [`chataptor`](../chataptor/) (the pure-Dart core).

## Install

```yaml
dependencies:
  chataptor_flutter: ^0.1.0
```

This transitively pulls in `chataptor`. You rarely need both in `dependencies:`.

## Usage

```dart
import 'package:chataptor_flutter/chataptor_flutter.dart';

await Chataptor.init(siteId: 'your-site', widgetKey: 'pk_xxx');

// Then somewhere in your widget tree:
Navigator.push(context, MaterialPageRoute(builder: (_) => const ChataptorChatScreen()));
```

See the [getting started guide](../../docs/guides/getting-started.md).

## License

[MIT](../../LICENSE) © 2026 Chataptor
