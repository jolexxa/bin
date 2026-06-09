# 🗑️ Bin

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Coverage][coverage_badge]][coverage_link]
![Made in Minnesota][minnesota_badge]
[![License: MIT][license_badge]][license_link]

Declare typed binary data structures in Dart (without code generation) using the excellent [binarize](https://pub.dev/packages/binarize) package.

```dart
import 'package:bin/bin.dart';

/// A phone number category.
enum PhoneKind { home, mobile, work }

final class AddressBook with Binnable {
  final Bin<String> owner = Bin.utf8();
  final Bin<Contact?> emergencyContact = Bin.nullableObj(Contact.new);
  final Bin<List<Contact>> contacts = Bin.custom(list(obj(Contact.new)), []);
  final Bin<Map<String, List<List<int>>>> groups = Bin.custom(
    map(string.utf8(), list(list(uint32))),
    {},
  );

  @override
  Iterable<Binned> get bins => [owner, emergencyContact, contacts, groups];
}

final class Contact with Binnable { ... }

void main() {
  final addressBook = AddressBook()
    ..owner.value = 'Bob'
    ..emergencyContact.value = (Contact()
      ..id.value = 7
      ..name.value = 'Alice'
      ..phoneNumbers.value = {PhoneKind.mobile: '1-234-5678'})
    ..contacts.value = [
      Contact()
        ..id.value = 7
        ..name.value = 'Alice'
        ..phoneNumbers.value = {
          PhoneKind.home: '1-234-5678',
          PhoneKind.mobile: '1-234-5678',
          PhoneKind.work: '1-234-5678',
        }
        ..addressLines.value = [
          '1000 Home Street',
          'Shore Town, TS 12345',
        ],
      Contact()
        ..id.value = 12
        ..name.value = 'Eve'
        ..phoneNumbers.value = {PhoneKind.mobile: '1-234-5678'},
    ]
    ..groups.value = {
      'family': [
        [7],
        [12],
      ],
      'work': [
        [12],
      ],
    };

  final bytes = encode(addressBook);
  final decoded = decode(AddressBook.new, bytes);
}
```

The above was taken from the complete [example](./example).

## 📦 Installation

```sh
dart pub add bin
```

## 📖 Usage

### Declaring Types

Create a class with `Binnable`, define fields as `Bin<T>`, and return them in binary order.

```dart
final class Contact with Binnable {
  final Bin<int> id = Bin.uint32();
  final Bin<String> name = Bin.utf8();
  final Bin<Map<PhoneKind, String>> phoneNumbers = Bin.custom(
    map(enumeration(PhoneKind.values), string.utf8()),
    {},
  );

  @override
  Iterable<Binned> get bins => [id, name, phoneNumbers];
}
```

`Bin` comes with many constructors that allow you to create different types of primitive values:

```dart
final id = Bin.int32();
final weight = Bin.float64();
final name = Bin.utf8();
```

Bins can be composed to create composite types using lists:

```dart
final Bin<List<String>> names = Bin.custom(list(string.utf8()), <String>[]);
```

Maps can be used as well:

```dart
final Bin<Map<String, int>> lookup = Bin.custom(
  map(string.utf8(), uint32),
  <String, int>{},
);
```

You may nest lists and maps as much as you like.

`Bin.custom` enables you to use any Binarize `PayloadType<T>` as a field type, along with a default value.

You must implement a `bins` property that returns the fields in binary order.

```dart
@override
Iterable<Binned> get bins => [id, name, phoneNumbers];
```

> [!WARNING]
> The order of `bins` is the binary schema. Changing the order changes the bytes.

### Binarize 101

Bin uses Binarize under the hood to perform serialization, and associates each class field with a Binarize `PayloadType<T>`.

```dart
final count = Bin.uint32();
final name = Bin.utf8();
final tags = Bin.custom(list(string.utf8()), <String>[]);
final kind = Bin.custom(enumeration(PhoneKind.values), PhoneKind.home);
```

Payload types nest inside each other. A payload describes one value, and
collection payloads accept other payloads:

```dart
final ids = Bin.custom(list(uint32), <int>[]);
final rows = Bin.custom(list(list(uint32)), <List<int>>[]);
final lookup = Bin.custom(
  map(string.utf8(), list(uint32)),
  <String, List<int>>{},
);
```

Objects work the same way with `obj`:

```dart
final contact = Bin.obj(Contact.new);
final contacts = Bin.custom(list(obj(Contact.new)), <Contact>[]);
final pages = Bin.custom(list(list(obj(Contact.new))), <List<Contact>>[]);
```

Common payloads include:

- integers: `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`
- floats and booleans: `float32`, `float64`, `boolean`
- strings: `string.utf8()`, `string.ascii()`, `string.latin1()`
- collections: `list(type)`, `map(keyType, valueType)`, `RawList(type, amount: n)`
- nullable values: `nil(type)`
- enums: `enumeration(MyEnum.values)`
- bytes and typed data: `Bytes(n)`, `uint8List()`, `byteData()`, and other typed list payloads

Length-prefixed payloads use compact defaults, but most accept a `lengthType`
when you need larger values:

```dart
final longNames = Bin.custom(
  list(string.utf8(), lengthType: uint32),
  <String>[],
);
```

### Using Types

Read and write field values through `.value`.

```dart
final contact = Contact()
  ..id.value = 7
  ..name.value = 'Alice'
  ..phoneNumbers.value = {PhoneKind.mobile: '1-234-5678'};

print(contact.name.value); // Alice
```

Nested objects are created from factories when decoded.

### Encoding and Decoding

Use `encode` and `decode` at the byte boundary.

```dart
final bytes = encode(contact);
final decoded = decode(Contact.new, bytes);
```

For streaming or embedded formats, use `read(ByteReader)` and `write(ByteWriter)` directly.

[coverage_badge]: coverage_badge.svg
[coverage_link]: coverage/lcov.info
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[minnesota_badge]: minnesota.svg
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
