// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $DatabaseDefinition extends BeanDefinition {
  @override
  String get typeName => 'Database';

  @override
  Database create(BeanContainer container) => Database(
    container.get<BootConfig>().resolvePlaceholder('\${pg.host}'),
    int.parse(
      container.get<BootConfig>().resolvePlaceholder('\${pg.port:5432}'),
    ),
    container.get<BootConfig>().resolvePlaceholder('\${pg.database:postgres}'),
    container.get<BootConfig>().resolvePlaceholder('\${pg.username:postgres}'),
    container.get<BootConfig>().resolvePlaceholder('\${pg.password:postgres}'),
  );
  @override
  bool get hasPostConstruct => true;
  @override
  void postConstruct(dynamic instance) {
    (instance as Database).init();
  }

  @override
  bool get hasPreDestroy => true;
  @override
  void preDestroy(dynamic instance) => (instance as Database).close();
}
