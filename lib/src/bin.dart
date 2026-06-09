import 'dart:typed_data';

import 'package:binarize/binarize.dart' as binarize;

/// A field that can read and write itself from positioned binary streams.
abstract interface class Binned {
  /// Reads this field from [reader].
  void read(binarize.ByteReader reader);

  /// Writes this field to [writer].
  void write(binarize.ByteWriter writer);
}

/// A typed binary field backed by a binarize payload type.
abstract class Bin<T> implements Binned {
  /// Creates a field with a custom binarize [type] and initial [value].
  factory Bin.custom(binarize.PayloadType<T> type, T value) = _ValueBin<T>;

  /// The current in-memory value of this field.
  T get value;

  /// Updates the current in-memory value of this field.
  set value(T value);

  /// Creates a boolean field.
  static Bin<bool> boolean([bool value = false]) {
    return Bin.custom(binarize.boolean, value);
  }

  /// Creates an int8 field.
  static Bin<int> int8([int value = 0]) {
    return Bin.custom(binarize.int8, value);
  }

  /// Creates an int16 field.
  static Bin<int> int16([int value = 0]) {
    return Bin.custom(binarize.int16, value);
  }

  /// Creates an int32 field.
  static Bin<int> int32([int value = 0]) {
    return Bin.custom(binarize.int32, value);
  }

  /// Creates an int64 field.
  static Bin<int> int64([int value = 0]) {
    return Bin.custom(binarize.int64, value);
  }

  /// Creates a uint8 field.
  static Bin<int> uint8([int value = 0]) {
    return Bin.custom(binarize.uint8, value);
  }

  /// Creates a uint16 field.
  static Bin<int> uint16([int value = 0]) {
    return Bin.custom(binarize.uint16, value);
  }

  /// Creates a uint32 field.
  static Bin<int> uint32([int value = 0]) {
    return Bin.custom(binarize.uint32, value);
  }

  /// Creates a uint64 field.
  static Bin<int> uint64([int value = 0]) {
    return Bin.custom(binarize.uint64, value);
  }

  /// Creates a float32 field.
  static Bin<double> float32([double value = 0]) {
    return Bin.custom(binarize.float32, value);
  }

  /// Creates a float64 field.
  static Bin<double> float64([double value = 0]) {
    return Bin.custom(binarize.float64, value);
  }

  /// Creates a UTF-8 string field.
  static Bin<String> utf8({
    String value = '',
    binarize.PayloadType<int> lengthType = binarize.uint8,
  }) {
    return Bin.custom(binarize.string.utf8(lengthType: lengthType), value);
  }

  /// Creates a Latin-1 string field.
  static Bin<String> latin1({
    String value = '',
    binarize.PayloadType<int> lengthType = binarize.uint8,
  }) {
    return Bin.custom(binarize.string.latin1(lengthType: lengthType), value);
  }

  /// Creates an ASCII string field.
  static Bin<String> ascii({
    String value = '',
    binarize.PayloadType<int> lengthType = binarize.uint8,
  }) {
    return Bin.custom(binarize.string.ascii(lengthType: lengthType), value);
  }

  /// Creates a nullable field backed by [type].
  static Bin<T?> nullable<T>(binarize.PayloadType<T> type, [T? value]) {
    return Bin.custom(binarize.nil(type), value);
  }

  /// Creates a field for a child object from [create].
  static Bin<T> obj<T extends Binnable>(T Function() create, [T? value]) {
    return Bin.custom(_BinnablePayload(create), value ?? create());
  }

  /// Creates a nullable field for a child object from [create].
  static Bin<T?> nullableObj<T extends Binnable>(
    T Function() create, [
    T? value,
  ]) {
    return Bin.custom(binarize.nil(_BinnablePayload(create)), value);
  }
}

/// Creates a payload type for a [Binnable] object.
binarize.PayloadType<T> obj<T extends Binnable>(T Function() create) {
  return _BinnablePayload<T>(create);
}

/// A binary object described by an ordered list of fields.
mixin Binnable {
  /// The fields in binary read/write order.
  Iterable<Binned> get bins;

  /// Reads each field from [reader] in order.
  void read(binarize.ByteReader reader) {
    for (final bin in bins) {
      bin.read(reader);
    }
  }

  /// Writes each field to [writer] in order.
  void write(binarize.ByteWriter writer) {
    for (final bin in bins) {
      bin.write(writer);
    }
  }
}

final class _ValueBin<T> implements Bin<T> {
  _ValueBin(this.type, this.value);

  final binarize.PayloadType<T> type;

  @override
  T value;

  @override
  void read(binarize.ByteReader reader) {
    value = type.get(reader);
  }

  @override
  void write(binarize.ByteWriter writer) {
    type.set(writer, value);
  }
}

final class _BinnablePayload<T extends Binnable>
    extends binarize.PayloadType<T> {
  const _BinnablePayload(this.create);

  final T Function() create;

  @override
  T get(binarize.ByteReader reader, [binarize.Endian? endian]) {
    return create()..read(reader);
  }

  @override
  void set(binarize.ByteWriter writer, T value, [binarize.Endian? endian]) {
    value.write(writer);
  }
}

/// Encodes [object] into binary bytes.
Uint8List encode(Binnable object) {
  final writer = binarize.ByteWriter();
  object.write(writer);
  return writer.toBytes();
}

/// Decodes [bytes] into a new object created by [create].
T decode<T extends Binnable>(T Function() create, Uint8List bytes) {
  return create()..read(binarize.ByteReader(bytes));
}
