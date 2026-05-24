import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/aop_proxy_generator.dart';
import 'src/bean_generator.dart';
import 'src/controller_generator.dart';
import 'src/factory_generator.dart';
import 'src/serializable_generator.dart';
import 'src/websocket_generator.dart';
import 'src/context_builder.dart';

Builder beanBuilder(BuilderOptions options) =>
    SharedPartBuilder([BeanGenerator(), ControllerBeanGenerator(), ServerFilterBeanGenerator(), ClientFilterBeanGenerator(), InterceptorBeanBeanGenerator(), FactoryGenerator(), AopProxyGenerator(), ControllerAopProxyGenerator(), WebSocketGenerator()], 'boot');

Builder controllerBuilder(BuilderOptions options) =>
    SharedPartBuilder([ControllerGenerator()], 'boot_route');

Builder serializableBuilder(BuilderOptions options) =>
    SharedPartBuilder([
      SerdeableGenerator(),
      SerializableGenerator(),
      DeserializableGenerator(),
    ], 'boot_serde');

Builder contextBuilder(BuilderOptions options) => ContextBuilder();
