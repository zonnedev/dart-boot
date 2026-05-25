import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/serializable_generator.dart';

Builder serializableBuilder(BuilderOptions options) =>
    SharedPartBuilder([
      SerdeableGenerator(),
      SerializableGenerator(),
      DeserializableGenerator(),
    ], 'boot_serde');
