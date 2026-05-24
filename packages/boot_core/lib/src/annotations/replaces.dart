/// Declares that this bean replaces another bean.
///
/// The replacement bean must be assignable to the replaced type.
class Replaces {
  /// The bean type to replace.
  final Type value;

  /// If the replaced bean is named, specify the name.
  final String? named;

  const Replaces(this.value, {this.named});
}
