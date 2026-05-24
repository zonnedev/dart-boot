import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/client_generator.dart';

Builder clientBuilder(BuilderOptions options) =>
    SharedPartBuilder([ClientGenerator()], 'boot_client');
