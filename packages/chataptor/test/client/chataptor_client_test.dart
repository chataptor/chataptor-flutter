import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:test/test.dart';

ChataptorConfig _testConfig() => ChataptorConfig(
  siteId: 'abc',
  widgetKey: 'pk_x',
  apiUrl: Uri.parse('http://localhost:4000'),
);

void main() {
  group('ChataptorClient lifecycle', () {
    test('starts in Disconnected state', () {
      final transport = FakeChatTransport();
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      expect(
        client.currentConnectionState,
        const Disconnected(DisconnectReason.userRequested),
      );
    });

    test('connect transitions Connecting → Connected', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      final states = <ConnectionState>[];
      client.connectionState.listen(states.add);

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.any((s) => s is Connecting), isTrue);
      expect(states.last, isA<Connected>());
    });

    test(
      'connect joins site:<siteId> then conversation:<id> channels',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(transport.recorded.joinedChannels, [
          'site:abc',
          'conversation:conv1',
        ]);
      },
    );

    test(
      'connect stays Disconnected when conversation:create times out',
      () async {
        final transport = FakeChatTransport();
        // No conversationCreated → push returns PushTimeout.
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );
        final states = <ConnectionState>[];
        client.connectionState.listen(states.add);

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states.last, isA<Disconnected>());
      },
    );

    test('disconnect transitions to Disconnected', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await client.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(client.currentConnectionState, isA<Disconnected>());
    });

    test('throws ChataptorStateError when sending before connect', () async {
      final transport = FakeChatTransport();
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      expect(
        () => client.sendMessage('hi'),
        throwsA(isA<ChataptorStateError>()),
      );
    });
  });

  group('ChataptorClient translation params', () {
    ChataptorConfig translationConfig() => ChataptorConfig(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      translation: TranslationConfig.auto(customerLanguage: 'pl'),
    );

    test(
      'connect passes browser_language in site channel join params',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: translationConfig(),
          transport: transport,
        );

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Index 0 = site channel join, index 1 = conversation channel join.
        expect(transport.recorded.joinedChannelParams[0], {
          'browser_language': 'pl',
        });
      },
    );

    test(
      'connect includes client_language in conversation:create payload',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: translationConfig(),
          transport: transport,
        );

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final createPush = transport.recorded.pushes.firstWhere(
          (p) => p.event == 'conversation:create',
        );
        expect(createPush.payload['client_language'], 'pl');
      },
    );

    test(
      'connect omits browser_language when customerLanguage is null',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          transport.recorded.joinedChannelParams[0].containsKey(
            'browser_language',
          ),
          isFalse,
        );
      },
    );

    test(
      'connect omits client_language in conversation:create when not set',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final createPush = transport.recorded.pushes.firstWhere(
          (p) => p.event == 'conversation:create',
        );
        expect(createPush.payload.containsKey('client_language'), isFalse);
      },
    );
  });

  group('ChataptorClient message deduplication', () {
    test('deduplicates message:received events with the same msg_id', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final messages = <Message>[];
      client.messages.listen(messages.add);

      const payload = {
        'message': {
          'msg_id': 'msg-1',
          'body_src': 'Hello agent',
          'author': 'agent',
        },
      };
      transport.inject.event(
        const MessageReceived(
          topic: 'conversation:conv1',
          event: 'message:received',
          payload: payload,
        ),
      );
      transport.inject.event(
        const MessageReceived(
          topic: 'conversation:conv1',
          event: 'message:received',
          payload: payload,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(messages, hasLength(1));
      expect(messages.first.id, 'msg-1');
    });

    test(
      'filters server echo of own sent message when msg_id matches push reply',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        transport.inject.replyFor(
          topic: 'conversation:conv1',
          event: 'message:send',
          result: const PushOk({
            'message': {
              'msg_id': 'msg-42',
              'body_src': 'Hello',
              'author': 'customer',
            },
          }),
        );
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final messages = <Message>[];
        client.messages.listen(messages.add);

        await client.sendMessage('Hello');

        transport.inject.event(
          const MessageReceived(
            topic: 'conversation:conv1',
            event: 'message:received',
            payload: {
              'message': {
                'msg_id': 'msg-42',
                'body_src': 'Hello',
                'author': 'customer',
              },
            },
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(messages, isEmpty);
      },
    );

    test('does not filter message:received with a different msg_id', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.replyFor(
        topic: 'conversation:conv1',
        event: 'message:send',
        result: const PushOk({
          'message': {
            'msg_id': 'msg-1',
            'body_src': 'Hi',
            'author': 'customer',
          },
        }),
      );
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final messages = <Message>[];
      client.messages.listen(messages.add);

      await client.sendMessage('Hi');

      transport.inject.event(
        const MessageReceived(
          topic: 'conversation:conv1',
          event: 'message:received',
          payload: {
            'message': {
              'msg_id': 'msg-99',
              'body_src': 'Different message',
              'author': 'agent',
            },
          },
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(messages, hasLength(1));
      expect(messages.first.id, 'msg-99');
    });
  });

  group('ChataptorClient history loading', () {
    test('connect() emits history messages from conversation channel join'
        ' response', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.joinPayload('conversation:conv1', {
        'messages': [
          {
            'msg_id': 10,
            'conv_id': 1,
            'body_src': 'Hej, jak mogę pomóc?',
            'author': 'agent',
            'inserted_at': '2026-05-12T10:00:00Z',
            'delivery_channel': 'websocket',
          },
          {
            'msg_id': 11,
            'conv_id': 1,
            'body_src': 'Mam pytanie.',
            'author': 'customer',
            'inserted_at': '2026-05-12T10:01:00Z',
            'delivery_channel': 'websocket',
          },
        ],
      });

      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      final received = <Message>[];
      client.messages.listen(received.add);

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(received, hasLength(2));
      expect(received[0].id, '10');
      expect(received[0].body, 'Hej, jak mogę pomóc?');
      expect(received[0].author, MessageAuthor.agent);
      expect(received[1].id, '11');
      expect(received[1].body, 'Mam pytanie.');
      expect(received[1].author, MessageAuthor.customer);
    });

    test(
      'history message IDs are added to seen set — subsequent message:received'
      ' with same ID is deduplicated',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        transport.inject.joinPayload('conversation:conv1', {
          'messages': [
            {
              'msg_id': 99,
              'conv_id': 1,
              'body_src': 'Old message',
              'author': 'agent',
              'inserted_at': '2026-05-12T09:00:00Z',
              'delivery_channel': 'websocket',
            },
          ],
        });

        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );

        final received = <Message>[];
        client.messages.listen(received.add);

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // History emitted — 1 message.
        expect(received, hasLength(1));

        // PubSub echo with same msg_id arrives → must be deduplicated.
        transport.inject.event(
          const MessageReceived(
            topic: 'conversation:conv1',
            event: 'message:received',
            payload: {
              'message': {
                'msg_id': 99,
                'body_src': 'Old message',
                'author': 'agent',
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(received, hasLength(1));
      },
    );

    test(
      'connect() with empty messages list in join response emits nothing',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        transport.inject.joinPayload('conversation:conv1', {
          'messages': <Map<String, dynamic>>[],
        });

        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );

        final received = <Message>[];
        client.messages.listen(received.add);

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(received, isEmpty);
      },
    );

    test(
      'connect() with no messages key in join response emits nothing',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        // No joinPayload set → FakeChatTransport returns {} by default.

        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );

        final received = <Message>[];
        client.messages.listen(received.add);

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(received, isEmpty);
      },
    );

    test(
      'history messages with translation sub-object expose bodyTranslated',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        transport.inject.joinPayload('conversation:conv1', {
          'messages': [
            {
              'msg_id': 5,
              'conv_id': 1,
              'body_src': 'Dzień dobry',
              'author': 'agent',
              'inserted_at': '2026-05-12T09:00:00Z',
              'delivery_channel': 'websocket',
              'translation': {
                'translatedText': 'Good morning',
                'sourceLanguage': 'pl',
                'targetLanguage': 'en',
              },
            },
          ],
        });

        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );

        final received = <Message>[];
        client.messages.listen(received.add);

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(received, hasLength(1));
        expect(received.first.bodyTranslated, 'Good morning');
        expect(received.first.sourceLanguage, 'pl');
        expect(received.first.targetLanguage, 'en');
      },
    );
  });

  group('ChataptorClient session management', () {
    test('clearSession() removes guestId from storage', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final storage = InMemoryChataptorStorage();
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
        storage: storage,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // guestId must have been written during connect().
      expect(await storage.readString('chataptor.guest_id.abc'), isNotNull);

      await client.clearSession();

      expect(await storage.readString('chataptor.guest_id.abc'), isNull);
    });

    test('clearSession() disconnects when currently connected', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(client.currentConnectionState, isA<Connected>());

      await client.clearSession();

      expect(client.currentConnectionState, isA<Disconnected>());
    });

    test('clearSession() is safe when already disconnected', () async {
      final transport = FakeChatTransport();
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      // Must not throw.
      await client.clearSession();

      expect(client.currentConnectionState, isA<Disconnected>());
    });
  });

  group('ChataptorClient sessionIdleTimeout', () {
    ChataptorConfig idleConfig({Duration? timeout}) => ChataptorConfig(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      sessionIdleTimeout: timeout,
    );

    test('when stored last_activity is older than the timeout, '
        'connect clears the guest session before joining', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final storage = InMemoryChataptorStorage();
      // Pretend a previous session left a guestId and a stale activity ts.
      await storage.writeString(
        'chataptor.guest_id.abc',
        'pre-existing-guest-uuid',
      );
      await storage.writeString(
        'chataptor.last_activity_at.abc',
        DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 48))
            .toIso8601String(),
      );

      final client = ChataptorClient.internal(
        config: idleConfig(timeout: const Duration(hours: 24)),
        transport: transport,
        storage: storage,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // The stale guest was cleared and a fresh one was allocated.
      final newGuest = await storage.readString('chataptor.guest_id.abc');
      expect(newGuest, isNotNull);
      expect(newGuest, isNot('pre-existing-guest-uuid'));
    });

    test('when stored last_activity is within the timeout, '
        'connect preserves the existing guestId', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final storage = InMemoryChataptorStorage();
      await storage.writeString(
        'chataptor.guest_id.abc',
        'pre-existing-guest-uuid',
      );
      await storage.writeString(
        'chataptor.last_activity_at.abc',
        DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
      );

      final client = ChataptorClient.internal(
        config: idleConfig(timeout: const Duration(hours: 24)),
        transport: transport,
        storage: storage,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        await storage.readString('chataptor.guest_id.abc'),
        'pre-existing-guest-uuid',
      );
    });

    test(
      'when sessionIdleTimeout is null, connect ignores any stored timestamp',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final storage = InMemoryChataptorStorage();
        await storage.writeString(
          'chataptor.guest_id.abc',
          'pre-existing-guest-uuid',
        );
        await storage.writeString(
          'chataptor.last_activity_at.abc',
          DateTime.now()
              .toUtc()
              .subtract(const Duration(days: 365))
              .toIso8601String(),
        );

        final client = ChataptorClient.internal(
          config: idleConfig(),
          transport: transport,
          storage: storage,
        );
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Timeout disabled → guest is kept regardless of staleness.
        expect(
          await storage.readString('chataptor.guest_id.abc'),
          'pre-existing-guest-uuid',
        );
      },
    );

    test(
      'a received message refreshes the stored last_activity timestamp',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final storage = InMemoryChataptorStorage();
        final client = ChataptorClient.internal(
          config: idleConfig(timeout: const Duration(hours: 24)),
          transport: transport,
          storage: storage,
        );
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          await storage.readString('chataptor.last_activity_at.abc'),
          isNull,
        );

        transport.inject.event(
          const MessageReceived(
            topic: 'conversation:conv1',
            event: 'message:received',
            payload: {
              'message': {
                'msg_id': 'msg-1',
                'body_src': 'Hi',
                'author': 'agent',
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final ts = await storage.readString('chataptor.last_activity_at.abc');
        expect(ts, isNotNull);
        // Parses as a valid recent UTC instant.
        final parsed = DateTime.parse(ts!);
        expect(parsed.isUtc, isTrue);
        expect(
          DateTime.now().toUtc().difference(parsed).inSeconds,
          lessThan(5),
        );
      },
    );

    test(
      'successful send refreshes the stored last_activity timestamp',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        transport.inject.replyFor(
          topic: 'conversation:conv1',
          event: 'message:send',
          result: const PushOk({
            'message': {'msg_id': 'sent-1'},
          }),
        );
        final storage = InMemoryChataptorStorage();
        final client = ChataptorClient.internal(
          config: idleConfig(timeout: const Duration(hours: 24)),
          transport: transport,
          storage: storage,
        );
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final result = await client.sendMessage('hello');
        expect(result, isA<SendSuccess>());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          await storage.readString('chataptor.last_activity_at.abc'),
          isNotNull,
        );
      },
    );
  });

  group('ChataptorClient identify()', () {
    test(
      'with the same identity is a no-op — no extra channel joins',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final joinsBefore = transport.recorded.joinedChannels.length;

        await client.identify(const CustomerIdentity.anonymous());

        expect(transport.recorded.joinedChannels.length, joinsBefore);
      },
    );

    test('with a new identity reconnects with updated customer', () async {
      final transport = FakeChatTransport();
      // Two `conversation:create` replies: initial + reconnect-after-identify.
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await client.identify(
        const CustomerIdentity(id: 'user-42', email: 'jane@example.com'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(client.config.customer.id, 'user-42');
      expect(client.config.customer.email, 'jane@example.com');
      // Site channel rejoined → two joins to `site:abc` recorded.
      expect(
        transport.recorded.joinedChannels.where((t) => t == 'site:abc').length,
        2,
      );
    });

    test('preserves guestId across anonymous → identified migration', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final initialGuestId =
          transport.recorded.socketParams[0]['guestId'] as String?;
      expect(initialGuestId, isNotNull);

      await client.identify(
        const CustomerIdentity(id: 'user-42', email: 'jane@example.com'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // After identify, the reconnect must still carry the same guestId
      // so conversation continuity is preserved across the migration.
      expect(transport.recorded.socketParams[1]['guestId'], initialGuestId);
      expect(transport.recorded.socketParams[1]['customerId'], 'user-42');
    });

    test('before connect just swaps config (no reconnect)', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      await client.identify(const CustomerIdentity(id: 'user-42'));

      expect(client.config.customer.id, 'user-42');
      expect(client.currentConnectionState, isA<Disconnected>());
      expect(transport.recorded.joinedChannels, isEmpty);
    });
  });

  group('ChataptorClient socket params', () {
    ChataptorClient buildIdentifiedClient(
      FakeChatTransport transport, {
      CustomerIdentity? customer,
    }) {
      return ChataptorClient.internal(
        config: ChataptorConfig(
          siteId: 'abc',
          widgetKey: 'pk_x',
          apiUrl: Uri.parse('http://localhost:4000'),
          customer:
              customer ??
              const CustomerIdentity(
                id: 'user-42',
                email: 'jane@example.com',
                name: 'Jane Doe',
              ),
        ),
        transport: transport,
      );
    }

    test(
      'connect always sends guestId, even for identified customers',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final client = buildIdentifiedClient(transport);

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final params = transport.recorded.socketParams[0];
        expect(
          params['guestId'],
          isNotNull,
          reason:
              'guestId must always be sent so conversation continuity '
              'is preserved across anonymous→identified migrations',
        );
        expect(params['customerId'], 'user-42');
      },
    );

    test('connect packs identified customer email and name into customerData '
        '(single map, not separate customerEmail/customerName keys)', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = buildIdentifiedClient(transport);

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final params = transport.recorded.socketParams[0];
      expect(
        params['customerData'],
        isA<Map<String, dynamic>>(),
        reason:
            'identified customers must surface email/name via the '
            'customerData map — this is the only attribution channel '
            'honoured on the wire',
      );
      final customerData = params['customerData'] as Map<String, dynamic>;
      expect(customerData['email'], 'jane@example.com');
      expect(customerData['name'], 'Jane Doe');
      // Hash absent when no verificationHash was supplied.
      expect(customerData.containsKey('hash'), isFalse);
    });

    test('connect merges CustomerIdentity.customData into customerData and '
        'includes hash when verificationHash is present', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = buildIdentifiedClient(
        transport,
        customer: const CustomerIdentity(
          id: 'user-42',
          email: 'jane@example.com',
          name: 'Jane Doe',
          verificationHash: 'deadbeef',
          customData: {'plan': 'pro', 'lifetimeValue': 4200},
        ),
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final customerData =
          transport.recorded.socketParams[0]['customerData']
              as Map<String, dynamic>;
      expect(customerData['email'], 'jane@example.com');
      expect(customerData['name'], 'Jane Doe');
      expect(customerData['hash'], 'deadbeef');
      expect(customerData['plan'], 'pro');
      expect(customerData['lifetimeValue'], 4200);
    });

    test('connect omits top-level customerEmail/customerName keys — the '
        'wire format only honours customerData', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = buildIdentifiedClient(transport);

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final params = transport.recorded.socketParams[0];
      expect(params.containsKey('customerEmail'), isFalse);
      expect(params.containsKey('customerName'), isFalse);
    });

    test('connect sends customerName and customerEmail in the '
        'conversation:create payload so the conversation gets the '
        'right attribution from the first message', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = buildIdentifiedClient(transport);

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final createPush = transport.recorded.pushes.firstWhere(
        (p) => p.event == 'conversation:create',
      );
      expect(createPush.payload['customerName'], 'Jane Doe');
      expect(createPush.payload['customerEmail'], 'jane@example.com');
    });

    test('connect omits customerName/customerEmail from conversation:create '
        'when the customer is anonymous', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final createPush = transport.recorded.pushes.firstWhere(
        (p) => p.event == 'conversation:create',
      );
      expect(createPush.payload.containsKey('customerName'), isFalse);
      expect(createPush.payload.containsKey('customerEmail'), isFalse);
    });
  });

  group('ChataptorClient currentMessages buffer', () {
    test('currentMessages is empty before any connect', () {
      final transport = FakeChatTransport();
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      expect(client.currentMessages, isEmpty);
    });

    test('currentMessages contains history messages after connect', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.joinPayload('conversation:conv1', {
        'messages': [
          {
            'msg_id': 10,
            'conv_id': 1,
            'body_src': 'Hej!',
            'author': 'agent',
            'inserted_at': '2026-05-12T10:00:00Z',
            'delivery_channel': 'websocket',
          },
          {
            'msg_id': 11,
            'conv_id': 1,
            'body_src': 'Dzień dobry',
            'author': 'customer',
            'inserted_at': '2026-05-12T10:01:00Z',
            'delivery_channel': 'websocket',
          },
        ],
      });
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(client.currentMessages, hasLength(2));
      expect(client.currentMessages[0].id, '10');
      expect(client.currentMessages[1].id, '11');
    });

    test(
      'currentMessages appends real-time messages from message:received',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        transport.inject.event(
          const MessageReceived(
            topic: 'conversation:conv1',
            event: 'message:received',
            payload: {
              'message': {
                'msg_id': 'rt-1',
                'body_src': 'Real-time message',
                'author': 'agent',
              },
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(client.currentMessages, hasLength(1));
        expect(client.currentMessages.first.id, 'rt-1');
      },
    );

    test(
      'currentMessages survives disconnect — not cleared between sessions',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        transport.inject.joinPayload('conversation:conv1', {
          'messages': [
            {
              'msg_id': 20,
              'conv_id': 1,
              'body_src': 'Cached message',
              'author': 'agent',
              'inserted_at': '2026-05-12T10:00:00Z',
              'delivery_channel': 'websocket',
            },
          ],
        });
        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(client.currentMessages, hasLength(1));

        await client.disconnect();

        expect(client.currentMessages, hasLength(1));
      },
    );

    test('clearSession clears the message history buffer', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.joinPayload('conversation:conv1', {
        'messages': [
          {
            'msg_id': 30,
            'conv_id': 1,
            'body_src': 'To be cleared',
            'author': 'agent',
            'inserted_at': '2026-05-12T10:00:00Z',
            'delivery_channel': 'websocket',
          },
        ],
      });
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(client.currentMessages, hasLength(1));

      await client.clearSession();

      expect(client.currentMessages, isEmpty);
    });

    test(
      'on reconnect, history already in buffer is not re-emitted to stream',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        transport.inject.conversationCreated('site:abc', 'conv1');
        transport.inject.joinPayload('conversation:conv1', {
          'messages': [
            {
              'msg_id': 40,
              'conv_id': 1,
              'body_src': 'Persistent message',
              'author': 'agent',
              'inserted_at': '2026-05-12T10:00:00Z',
              'delivery_channel': 'websocket',
            },
          ],
        });

        final client = ChataptorClient.internal(
          config: _testConfig(),
          transport: transport,
        );

        final streamMessages = <Message>[];
        client.messages.listen(streamMessages.add);

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(streamMessages, hasLength(1));
        expect(client.currentMessages, hasLength(1));

        await client.disconnect();

        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(client.currentMessages, hasLength(1));
        expect(streamMessages, hasLength(1));
      },
    );
  });

  group('ChataptorClient storage initialization', () {
    test('when neither config.storage nor storage param is provided, '
        'the SDK uses a single shared in-memory storage for both _storage and '
        '_guestIdStore — guestId written via _guestIdStore is visible via '
        'debugStorage', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // _guestIdStore.getOrCreate() ran during connect() — guestId is in
      // the storage instance owned by _guestIdStore. If _storage and
      // _guestIdStore share a single InMemoryChataptorStorage, the
      // value must be readable via the publicly exposed debugStorage.
      expect(
        await client.debugStorage.readString('chataptor.guest_id.abc'),
        isNotNull,
        reason:
            '_storage and _guestIdStore must share a single backing '
            'instance when no storage is provided',
      );
    });
  });

  group('ChataptorClient sessionIdleTimeout — history replay', () {
    test('_loadHistory does NOT touch last_activity_at when history is '
        'loaded from the conversation:join response', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.joinPayload('conversation:conv1', {
        'messages': [
          {
            'msg_id': 'hist-1',
            'conv_id': 1,
            'body_src': 'Old message',
            'author': 'agent',
            'inserted_at': '2026-05-12T09:00:00Z',
            'delivery_channel': 'websocket',
          },
          {
            'msg_id': 'hist-2',
            'conv_id': 1,
            'body_src': 'Another old message',
            'author': 'agent',
            'inserted_at': '2026-05-12T09:01:00Z',
            'delivery_channel': 'websocket',
          },
        ],
      });
      final storage = InMemoryChataptorStorage();
      final client = ChataptorClient.internal(
        config: ChataptorConfig(
          siteId: 'abc',
          widgetKey: 'pk_x',
          apiUrl: Uri.parse('http://localhost:4000'),
          sessionIdleTimeout: const Duration(hours: 24),
        ),
        transport: transport,
        storage: storage,
      );

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // History loading must not pretend the user just interacted. If
      // _loadHistory ever started touching last_activity, idle timeout
      // would never fire for conversations with any persisted history.
      expect(
        await storage.readString('chataptor.last_activity_at.abc'),
        isNull,
        reason:
            'History replay through _loadHistory must not write '
            'last_activity_at — only live message exchanges count.',
      );
    });
  });

  group('ChataptorClient identify() interactions', () {
    ChataptorConfig idleConfig({Duration? timeout}) => ChataptorConfig(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      sessionIdleTimeout: timeout,
    );

    test('when the persisted session has been idle past sessionIdleTimeout, '
        'identify() honors the timeout and rotates the guestId (idle wins '
        'over continuity)', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.conversationCreated('site:abc', 'conv2');
      final storage = InMemoryChataptorStorage();

      final client = ChataptorClient.internal(
        config: idleConfig(timeout: const Duration(hours: 24)),
        transport: transport,
        storage: storage,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final firstGuest =
          transport.recorded.socketParams[0]['guestId'] as String;

      // Simulate the user being idle past the timeout — overwrite the
      // last_activity_at directly.
      await storage.writeString(
        'chataptor.last_activity_at.abc',
        DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 7))
            .toIso8601String(),
      );

      await client.identify(
        const CustomerIdentity(id: 'user-42', email: 'jane@example.com'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final secondGuest =
          transport.recorded.socketParams[1]['guestId'] as String;
      expect(
        secondGuest,
        isNot(firstGuest),
        reason:
            'sessionIdleTimeout wins over identify() continuity — when '
            'the session has been idle past the timeout, identify() '
            'starts a fresh anonymous session before migrating identity.',
      );
      expect(transport.recorded.socketParams[1]['customerId'], 'user-42');
    });

    test('identify() throws ChataptorStateError when the connection is '
        'Connecting — caller must wait for a stable state', () async {
      final transport = FakeChatTransport();
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );

      // Simulate transport-level Connecting — _handleTransportState
      // maps this to a Connecting client state.
      transport.inject.connectionState(const TransportConnecting());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(client.currentConnectionState, isA<Connecting>());

      expect(
        () => client.identify(const CustomerIdentity(id: 'user-42')),
        throwsA(isA<ChataptorStateError>()),
      );
    });

    test('identify() throws ChataptorStateError when the connection is '
        'Reconnecting', () async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      final client = ChataptorClient.internal(
        config: _testConfig(),
        transport: transport,
      );
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(client.currentConnectionState, isA<Connected>());

      // Simulate transport-level reconnect.
      transport.inject.connectionState(
        const TransportReconnecting(
          attemptNumber: 1,
          nextAttemptIn: Duration(seconds: 1),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(client.currentConnectionState, isA<Reconnecting>());

      expect(
        () => client.identify(const CustomerIdentity(id: 'user-42')),
        throwsA(isA<ChataptorStateError>()),
      );
    });
  });

  group('ChataptorClient clearSession() cleanup', () {
    test(
      'clearSession() also removes the persisted last_activity_at stamp',
      () async {
        final transport = FakeChatTransport();
        transport.inject.conversationCreated('site:abc', 'conv1');
        transport.inject.replyFor(
          topic: 'conversation:conv1',
          event: 'message:send',
          result: const PushOk({
            'message': {'msg_id': 'sent-1'},
          }),
        );
        final storage = InMemoryChataptorStorage();
        final client = ChataptorClient.internal(
          config: ChataptorConfig(
            siteId: 'abc',
            widgetKey: 'pk_x',
            apiUrl: Uri.parse('http://localhost:4000'),
            sessionIdleTimeout: const Duration(hours: 24),
          ),
          transport: transport,
          storage: storage,
        );
        await client.connect();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await client.sendMessage('hi');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          await storage.readString('chataptor.last_activity_at.abc'),
          isNotNull,
        );

        await client.clearSession();

        expect(
          await storage.readString('chataptor.last_activity_at.abc'),
          isNull,
          reason:
              'clearSession() must remove every persisted artefact of the '
              'session — including last_activity_at — so the next connect() '
              'starts with a clean slate.',
        );
      },
    );
  });
}
