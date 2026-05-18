import 'package:flutter/widgets.dart';

/// Localizable strings used by Chataptor widgets.
///
/// v0.1.0 ships English and Polish. The remaining 10 locales land in
/// v0.5.0.
@immutable
class ChataptorLocalizations {
  /// Creates a [ChataptorLocalizations].
  const ChataptorLocalizations({
    required this.typeMessage,
    required this.sendMessage,
    required this.attachmentHint,
    required this.connecting,
    required this.reconnecting,
    required this.disconnected,
    required this.agentTypingSingle,
    required this.todaySeparator,
    required this.yesterdaySeparator,
    required this.translatedLabel,
    required this.messageFailed,
    required this.retryMessage,
    required this.closeChat,
    required this.emptyState,
    required this.welcomeMessage,
    required this.headerOnline,
    required this.headerOffline,
    required this.headerDefaultTitle,
    required this.poweredByPrefix,
  });

  /// English strings.
  static const ChataptorLocalizations en = ChataptorLocalizations(
    typeMessage: 'Type a message…',
    sendMessage: 'Send',
    attachmentHint: 'Attach file',
    connecting: 'Connecting…',
    reconnecting: 'Reconnecting…',
    disconnected: 'You are offline',
    agentTypingSingle: '{name} is typing…',
    todaySeparator: 'Today',
    yesterdaySeparator: 'Yesterday',
    translatedLabel: 'Translated from {language}',
    messageFailed: 'Failed to send',
    retryMessage: 'Tap to retry',
    closeChat: 'Close chat',
    emptyState: 'No messages yet',
    welcomeMessage: 'Hi! How can we help?',
    headerOnline: 'Online',
    headerOffline: 'Offline',
    headerDefaultTitle: 'Support',
    poweredByPrefix: 'Powered by ',
  );

  /// Polish strings.
  static const ChataptorLocalizations pl = ChataptorLocalizations(
    typeMessage: 'Napisz wiadomość…',
    sendMessage: 'Wyślij',
    attachmentHint: 'Załącz plik',
    connecting: 'Łączenie…',
    reconnecting: 'Ponowne łączenie…',
    disconnected: 'Brak połączenia',
    agentTypingSingle: '{name} pisze…',
    todaySeparator: 'Dziś',
    yesterdaySeparator: 'Wczoraj',
    translatedLabel: 'Przetłumaczone z {language}',
    messageFailed: 'Nie udało się wysłać',
    retryMessage: 'Dotknij, aby ponowić',
    closeChat: 'Zamknij czat',
    emptyState: 'Brak wiadomości',
    welcomeMessage: 'Cześć! Jak możemy pomóc?',
    headerOnline: 'Online',
    headerOffline: 'Offline',
    headerDefaultTitle: 'Wsparcie',
    poweredByPrefix: 'Wspierane przez ',
  );

  /// Locales supported out of the box in v0.1.0.
  static const List<Locale> supportedLocales = [Locale('en'), Locale('pl')];

  /// Placeholder in composer input field.
  final String typeMessage;

  /// Label on the send button.
  final String sendMessage;

  /// Tooltip on the attachment picker button.
  final String attachmentHint;

  /// Status text while connecting.
  final String connecting;

  /// Status text while reconnecting.
  final String reconnecting;

  /// Status text while offline.
  final String disconnected;

  /// Typing indicator text — `{name}` is replaced with the agent name.
  final String agentTypingSingle;

  /// Date separator label for today's messages.
  final String todaySeparator;

  /// Date separator label for yesterday's messages.
  final String yesterdaySeparator;

  /// Translation source language label — `{language}` is replaced.
  final String translatedLabel;

  /// Label shown when a message fails to send.
  final String messageFailed;

  /// Helper text under a failed message inviting a retry tap.
  final String retryMessage;

  /// Tooltip on the close-chat button.
  final String closeChat;

  /// Body of the empty state widget.
  final String emptyState;

  /// Greeting shown in the empty state before any messages arrive.
  final String welcomeMessage;

  /// Header status label when at least one agent is online.
  final String headerOnline;

  /// Header status label when no agents are online.
  final String headerOffline;

  /// Header title fallback when neither widget.title nor SiteConfig
  /// supplies one (e.g. `'Support'` / `'Wsparcie'`).
  final String headerDefaultTitle;

  /// Prefix before the bolded brand domain in the attribution strip
  /// (`'Powered by '` / `'Wspierane przez '`). The domain itself is not
  /// localized.
  final String poweredByPrefix;

  /// Returns the nearest [ChataptorLocalizations] from the widget tree, or
  /// [ChataptorLocalizations.en] if none was provided.
  static ChataptorLocalizations of(BuildContext context) {
    return Localizations.of<ChataptorLocalizations>(
          context,
          ChataptorLocalizations,
        ) ??
        ChataptorLocalizations.en;
  }

  /// [LocalizationsDelegate] that resolves a [Locale] to the matching
  /// bundle.
  static const LocalizationsDelegate<ChataptorLocalizations> delegate =
      _ChataptorLocalizationsDelegate();

  /// Returns a copy with the given fields overridden.
  ChataptorLocalizations copyWith({
    String? typeMessage,
    String? sendMessage,
    String? attachmentHint,
    String? connecting,
    String? reconnecting,
    String? disconnected,
    String? agentTypingSingle,
    String? todaySeparator,
    String? yesterdaySeparator,
    String? translatedLabel,
    String? messageFailed,
    String? retryMessage,
    String? closeChat,
    String? emptyState,
    String? welcomeMessage,
    String? headerOnline,
    String? headerOffline,
    String? headerDefaultTitle,
    String? poweredByPrefix,
  }) {
    return ChataptorLocalizations(
      typeMessage: typeMessage ?? this.typeMessage,
      sendMessage: sendMessage ?? this.sendMessage,
      attachmentHint: attachmentHint ?? this.attachmentHint,
      connecting: connecting ?? this.connecting,
      reconnecting: reconnecting ?? this.reconnecting,
      disconnected: disconnected ?? this.disconnected,
      agentTypingSingle: agentTypingSingle ?? this.agentTypingSingle,
      todaySeparator: todaySeparator ?? this.todaySeparator,
      yesterdaySeparator: yesterdaySeparator ?? this.yesterdaySeparator,
      translatedLabel: translatedLabel ?? this.translatedLabel,
      messageFailed: messageFailed ?? this.messageFailed,
      retryMessage: retryMessage ?? this.retryMessage,
      closeChat: closeChat ?? this.closeChat,
      emptyState: emptyState ?? this.emptyState,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      headerOnline: headerOnline ?? this.headerOnline,
      headerOffline: headerOffline ?? this.headerOffline,
      headerDefaultTitle: headerDefaultTitle ?? this.headerDefaultTitle,
      poweredByPrefix: poweredByPrefix ?? this.poweredByPrefix,
    );
  }
}

class _ChataptorLocalizationsDelegate
    extends LocalizationsDelegate<ChataptorLocalizations> {
  const _ChataptorLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ChataptorLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<ChataptorLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'pl':
        return ChataptorLocalizations.pl;
      case 'en':
      default:
        return ChataptorLocalizations.en;
    }
  }

  @override
  bool shouldReload(_ChataptorLocalizationsDelegate old) => false;
}
