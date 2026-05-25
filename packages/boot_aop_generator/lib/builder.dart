import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/aop_proxy_generator.dart';

Builder aopBuilder(BuilderOptions options) =>
    SharedPartBuilder([AopProxyGenerator()], 'boot_aop');
