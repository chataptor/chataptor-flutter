import 'package:chataptor/src/config/site_config.dart';
import 'package:test/test.dart';

void main() {
  group('SiteLanguageVariant.fromJson', () {
    test('parses a fully-populated variant', () {
      final variant = SiteLanguageVariant.fromJson(const {
        'language_code': 'pl',
        'is_default': false,
        'is_auto_generated': false,
        'welcome_message': 'Dzień dobry! W czym możemy pomóc?',
        'header_title': 'Customer Support',
        'input_placeholder': 'Napisz wiadomość…',
        'offline_title': 'Jesteśmy offline',
        'offline_subtitle': 'Zostaw wiadomość, oddzwonimy.',
        'email_label': 'Twój e-mail',
      });
      expect(variant.languageCode, 'pl');
      expect(variant.isDefault, isFalse);
      expect(variant.welcomeMessage, 'Dzień dobry! W czym możemy pomóc?');
      expect(variant.headerTitle, 'Customer Support');
      expect(variant.inputPlaceholder, 'Napisz wiadomość…');
      expect(variant.offlineTitle, 'Jesteśmy offline');
      expect(variant.offlineSubtitle, 'Zostaw wiadomość, oddzwonimy.');
      expect(variant.emailLabel, 'Twój e-mail');
    });

    test('tolerates a sparse variant — only language_code mandatory', () {
      final variant = SiteLanguageVariant.fromJson(const {
        'language_code': 'de',
      });
      expect(variant.languageCode, 'de');
      expect(variant.isDefault, isFalse);
      expect(variant.welcomeMessage, isNull);
      expect(variant.headerTitle, isNull);
      expect(variant.inputPlaceholder, isNull);
    });

    test('equality is value-based', () {
      final a = SiteLanguageVariant.fromJson(const {
        'language_code': 'pl',
        'welcome_message': 'Hej',
        'header_title': 'Wsparcie',
      });
      final b = SiteLanguageVariant.fromJson(const {
        'language_code': 'pl',
        'welcome_message': 'Hej',
        'header_title': 'Wsparcie',
      });
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('SiteConfig.fromJson', () {
    Map<String, dynamic> fullPayload() => {
      'widget_language': 'en',
      'welcome_message': 'Hello!',
      'offline_mode': 'auto',
      'working_hours_enabled': false,
      'typing_preview_enabled': false,
      'auto_translations_enabled': true,
      'widget_open_on': 'click',
      'language_variants': [
        {
          'language_code': 'en',
          'is_default': true,
          'welcome_message': 'Hi! How can we help?',
          'header_title': 'Customer Support',
        },
        {
          'language_code': 'pl',
          'is_default': false,
          'welcome_message': 'Dzień dobry!',
          'header_title': 'Pomoc techniczna',
        },
      ],
    };

    test('parses every top-level field', () {
      final config = SiteConfig.fromJson(fullPayload());
      expect(config.widgetLanguage, 'en');
      expect(config.siteWelcomeMessage, 'Hello!');
      expect(config.offlineMode, OfflineMode.auto);
      expect(config.workingHoursEnabled, isFalse);
      expect(config.typingPreviewEnabled, isFalse);
      expect(config.autoTranslationsEnabled, isTrue);
      expect(config.widgetOpenOn, 'click');
      expect(config.languageVariants, hasLength(2));
    });

    test('defaults when payload is essentially empty', () {
      final config = SiteConfig.fromJson(const {});
      expect(config.widgetLanguage, 'en');
      expect(config.siteWelcomeMessage, isNull);
      expect(config.offlineMode, OfflineMode.auto);
      expect(config.workingHoursEnabled, isFalse);
      expect(config.typingPreviewEnabled, isFalse);
      expect(config.autoTranslationsEnabled, isFalse);
      expect(config.languageVariants, isEmpty);
    });

    test('maps offline_mode strings to OfflineMode enum', () {
      expect(
        SiteConfig.fromJson(const {'offline_mode': 'auto'}).offlineMode,
        OfflineMode.auto,
      );
      expect(
        SiteConfig.fromJson(const {
          'offline_mode': 'manual_offline',
        }).offlineMode,
        OfflineMode.manualOffline,
      );
      expect(
        SiteConfig.fromJson(const {
          'offline_mode': 'manual_online',
        }).offlineMode,
        OfflineMode.manualOnline,
      );
    });

    test('unknown offline_mode falls back to auto', () {
      final config = SiteConfig.fromJson(const {'offline_mode': 'banana'});
      expect(config.offlineMode, OfflineMode.auto);
    });

    test('raw payload is preserved for forward-compat', () {
      final payload = fullPayload();
      // Backend may add fields the SDK does not model yet — they must survive.
      payload['future_field_v3'] = {'inner': 'value'};
      final config = SiteConfig.fromJson(payload);
      expect(config.raw['future_field_v3'], {'inner': 'value'});
      expect(config.raw['widget_language'], 'en');
    });
  });

  group('SiteConfig.variantFor', () {
    SiteConfig configWith(List<Map<String, dynamic>> variants) =>
        SiteConfig.fromJson({
          'widget_language': 'en',
          'welcome_message': 'site-level fallback',
          'language_variants': variants,
        });

    test('returns variant matching the requested language code', () {
      final config = configWith([
        {
          'language_code': 'en',
          'is_default': true,
          'welcome_message': 'Hi',
          'header_title': 'Support',
        },
        {
          'language_code': 'pl',
          'is_default': false,
          'welcome_message': 'Cześć',
          'header_title': 'Wsparcie',
        },
      ]);
      expect(config.variantFor('pl')?.welcomeMessage, 'Cześć');
      expect(config.variantFor('en')?.welcomeMessage, 'Hi');
    });

    test('falls back to default variant when language not present', () {
      final config = configWith([
        {
          'language_code': 'en',
          'is_default': true,
          'welcome_message': 'Hi',
          'header_title': 'Support',
        },
      ]);
      expect(config.variantFor('de')?.welcomeMessage, 'Hi');
    });

    test('returns null when no variants exist', () {
      final config = SiteConfig.fromJson(const {});
      expect(config.variantFor('en'), isNull);
    });
  });

  group('SiteConfig.activeWelcomeMessage', () {
    test('prefers variant welcome_message over site-level fallback', () {
      final config = SiteConfig.fromJson(const {
        'welcome_message': 'site-level',
        'language_variants': [
          {
            'language_code': 'pl',
            'is_default': true,
            'welcome_message': 'variant-level',
          },
        ],
      });
      expect(config.activeWelcomeMessage('pl'), 'variant-level');
    });

    test('falls back to site-level when variant has no welcome_message', () {
      final config = SiteConfig.fromJson(const {
        'welcome_message': 'site-level',
        'language_variants': [
          {'language_code': 'pl', 'is_default': true, 'header_title': 'PT'},
        ],
      });
      expect(config.activeWelcomeMessage('pl'), 'site-level');
    });

    test('returns null when neither variant nor site provide one', () {
      final config = SiteConfig.fromJson(const {});
      expect(config.activeWelcomeMessage('en'), isNull);
    });
  });

  group('SiteConfig.activeHeaderTitle', () {
    test('returns variant header_title for requested language', () {
      final config = SiteConfig.fromJson(const {
        'language_variants': [
          {'language_code': 'pl', 'is_default': true, 'header_title': 'Pomoc'},
        ],
      });
      expect(config.activeHeaderTitle('pl'), 'Pomoc');
    });

    test('returns null when no variant defines header_title', () {
      final config = SiteConfig.fromJson(const {});
      expect(config.activeHeaderTitle('en'), isNull);
    });
  });

  group('SiteConfig equality', () {
    test('two configs from identical payloads are equal', () {
      final p = {
        'widget_language': 'en',
        'welcome_message': 'Hi',
        'language_variants': [
          {'language_code': 'en', 'is_default': true},
        ],
      };
      expect(SiteConfig.fromJson(p), equals(SiteConfig.fromJson(p)));
    });
  });
}
