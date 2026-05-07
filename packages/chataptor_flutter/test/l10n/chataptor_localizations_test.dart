import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('english defaults', () {
    expect(ChataptorLocalizations.en.typeMessage, 'Type a message…');
    expect(ChataptorLocalizations.en.sendMessage, 'Send');
    expect(ChataptorLocalizations.en.todaySeparator, 'Today');
  });

  test('polish defaults', () {
    expect(ChataptorLocalizations.pl.typeMessage, 'Napisz wiadomość…');
    expect(ChataptorLocalizations.pl.sendMessage, 'Wyślij');
  });

  test('copyWith overrides a single field', () {
    final custom = ChataptorLocalizations.en.copyWith(
      welcomeMessage: 'Hey there',
    );
    expect(custom.welcomeMessage, 'Hey there');
    expect(custom.sendMessage, 'Send');
  });

  testWidgets('delegate returns PL locale when requested', (tester) async {
    const delegate = ChataptorLocalizations.delegate;
    final loc = await delegate.load(const Locale('pl'));
    expect(loc.sendMessage, 'Wyślij');
  });

  testWidgets('delegate falls back to EN for unknown locale', (tester) async {
    const delegate = ChataptorLocalizations.delegate;
    final loc = await delegate.load(const Locale('xx'));
    expect(loc.sendMessage, 'Send');
  });
}
