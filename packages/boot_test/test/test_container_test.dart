import 'package:boot/boot.dart';
import 'package:boot_test/boot_test.dart';
import 'package:test/test.dart';

class _Svc {
  final String name;
  _Svc(this.name);
}

class _SvcDef extends BeanDefinition {
  final _Svc _instance;
  _SvcDef(this._instance);
  @override
  get beanType => _Svc;
  @override
  dynamic create(BeanContainer container) => _instance;
}

void main() {
  group('TestContainer', () {
    late TestContainer c;

    setUp(() => c = TestContainer());
    tearDown(() => c.reset());

    test('register and get', () {
      c.container.register<_Svc>(_SvcDef(_Svc('original')));
      expect(c.get<_Svc>().name, 'original');
    });

    test('override replaces bean', () {
      c.container.register<_Svc>(_SvcDef(_Svc('original')));
      c.override<_Svc>(_Svc('mocked'));
      expect(c.get<_Svc>().name, 'mocked');
    });

    test('overrideFactory replaces with definition', () {
      c.container.register<_Svc>(_SvcDef(_Svc('original')));
      c.overrideFactory<_Svc>(_SvcDef(_Svc('factory')));
      expect(c.get<_Svc>().name, 'factory');
    });

    test('overrideNamed replaces named bean', () {
      c.container.registerNamed<_Svc>('a', _SvcDef(_Svc('first')));
      c.overrideNamed<_Svc>('a', _SvcDef(_Svc('replaced')));
      expect(c.getNamed<_Svc>('a').name, 'replaced');
    });

    test('getAll returns all beans of type', () {
      c.container.register<_Svc>(_SvcDef(_Svc('one')));
      expect(c.getAll<_Svc>(), isNotEmpty);
    });

    test('has returns true when registered', () {
      c.container.register<_Svc>(_SvcDef(_Svc('x')));
      expect(c.has<_Svc>(), isTrue);
    });

    test('has returns false when not registered', () {
      expect(c.has<_Svc>(), isFalse);
    });

    test('container accessor returns BeanContainer', () {
      expect(c.container, isA<BeanContainer>());
    });
  });
}
