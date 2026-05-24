// coverage:ignore-file
/// Marks a class for both serialization (toJson) and deserialization (fromJson).
class Serdeable {
  const Serdeable();
}

/// Marks a class for serialization only (toJson).
class Serializable {
  const Serializable();
}

/// Marks a class for deserialization only (fromJson).
class Deserializable {
  const Deserializable();
}
