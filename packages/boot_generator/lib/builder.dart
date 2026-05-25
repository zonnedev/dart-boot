import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/bean_definition_generator.dart';
import 'src/factory_generator.dart';
import 'src/context_builder.dart';

Builder beanBuilder(BuilderOptions options) =>
    SharedPartBuilder([BeanDefinitionGenerator(), FactoryGenerator()], 'boot');

Builder contextBuilder(BuilderOptions options) => ContextBuilder();
