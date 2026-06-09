# 🗑️ Bin

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Coverage][coverage_badge]][coverage_link]
![Made in Minnesota][minnesota_badge]
[![License: MIT][license_badge]][license_link]

Typed binary data structures in Dart (without code generation) built on the excellent [binarize](https://pub.dev/packages/binarize) package.

```dart
import 'package:bin/bin.dart';

/// A phone number category.
enum PhoneKind { home, mobile, work }

final class AddressBook with Binnable {
  static final binType = obj(AddressBook.new);

  final owner = Bin.utf8();
  final emergencyContact = Bin.nullableObj(Contact.new);
  final contacts = Bin.custom(list(Contact.binType), <Contact>[]);
  final groups = Bin.custom(
    map(string.utf8(), list(list(uint32))),
    <String, List<List<int>>>{},
  );

  @override
  Iterable<Binned> get bins => [owner, emergencyContact, contacts, groups];
}

final class Contact with Binnable {
  static final binType = obj(Contact.new);

  // ...
}

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

  final bytes = encode(AddressBook.binType, addressBook);
  final decoded = decode(AddressBook.binType, bytes);
}
```

The above was taken from the complete [example](./example).

## 📦 Installation

```sh
dart pub add bin
```

## 📖 Usage

### 🔟 Binarize 101

Bin uses Binarize under the hood. A Binarize `PayloadType<T>` describes how
a value is read and written.

```dart
final countType = uint32;
final nameType = string.utf8();
final kindType = enumeration(PhoneKind.values);
```

Payload types nest inside each other. Collection payloads accept other payloads:

```dart
final idsType = list(uint32);
final rowsType = list(list(uint32));
final lookupType = map(
  string.utf8(),
  list(uint32),
);
```

Common payloads include:

- Numbers
  - `int8`, `int16`, `int32`, `int64`
  - `uint8`, `uint16`, `uint32`, `uint64`
  - `float32`, `float64`
- Other primitives
  - `boolean`
  - `string.utf8()`, `string.ascii()`, `string.latin1()`
  - `enumeration(MyEnum.values)`
- Composition
  - `list(type)`
  - `map(keyType, valueType)`
  - `RawList(type, amount: n)`
  - `nil(type)`
- Bytes and typed data
  - `Bytes(n)`
  - `uint8List()`, `byteData()`, and other typed list payloads

Length-prefixed payloads use compact defaults, but most accept a `lengthType`
when you need larger values:

```dart
final longNamesType = list(string.utf8(), lengthType: uint32);
```

### 🔌 Bin Additions

Bin adds field, object, enum, union, and custom schema helpers on top of
Binarize payloads.

#### Binnable Types

To make a type serializable, use the `Binnable` mixin on it.

```dart
final class Contact with Binnable {
  static final binType = obj(Contact.new);

  final id = Bin.uint32();
  final name = Bin.utf8();
  final phoneNumbers = Bin.custom(
    map(enumeration(PhoneKind.values), string.utf8()),
    <PhoneKind, String>{},
  );

  // Fields in serialization order.
  @override
  Iterable<Binned> get bins => [id, name, phoneNumbers];
}
```

Fields are implemented as `Bin` objects. Read and write field values through
`.value`.

```dart
final contact = Contact()
  ..id.value = 7
  ..name.value = 'Alice'
  ..phoneNumbers.value = {PhoneKind.mobile: '1-234-5678'};

print(contact.name.value); // Alice
```

> [!WARNING]
> The order of `bins` is the binary schema. Changing the order changes the bytes.

#### Custom Payloads and Enums

Use `Bin.custom` to turn any Binarize payload into a field:

```dart
final count = Bin.custom(uint32, 0);
final tags = Bin.custom(list(string.utf8()), <String>[]);
```

For direct enum fields, use `Bin.enumeration`:

```dart
final kind = Bin.enumeration(PhoneKind.values, PhoneKind.home);
```

#### Nested Objects

Other `Binnable` objects work with `obj`:

```dart
static final binType = obj(Contact.new);

final emergencyContact = Bin.obj(Contact.new);
final contacts = Bin.custom(list(Contact.binType), <Contact>[]);
final pages = Bin.custom(list(list(Contact.binType)), <List<Contact>>[]);
```

> [!NOTE]
> Bin needs a way to create a type when deserializing a byte stream, so by convention we pass in the parameter-less default constructor as `MyClass.new`.
> Public serializable models should expose this as `static final binType = obj(MyClass.new)`.

#### Encoding and Decoding

Use `encode` and `decode` at the byte boundary with any Binarize
`PayloadType<T>`. For concrete `Binnable` objects, use the model's `binType`.

```dart
final bytes = encode(Contact.binType, contact);
final decoded = decode(Contact.binType, bytes);
```

Because the boundary is payload-based, the same helpers also work for lists,
maps, nullable values, primitives, and union roots:

```dart
final bytes = encode(ContactMethod.union, contactMethod);
final decoded = decode(ContactMethod.union, bytes);
```

For streaming or embedded formats, use `read(ByteReader)` and
`write(ByteWriter)` directly.

#### Discriminated Unions

Discriminated unions declare a variants table on the sealed root:

```dart
sealed class ContactMethod with Binnable, Union {
  // by convention, base union types should declare a static field named `union`
  static final union = UnionType<ContactMethod, int>(
    uint8,
    {
      1: EmailContactMethod.new,
      2: PhoneContactMethod.new,
    },
  );
}

final class EmailContactMethod extends ContactMethod {
  final email = Bin.utf8();

  @override
  Iterable<Binned> get bins => [email];
}
```

Each derived type is entered into the map as an identifier that's associated with its class factory.

Fields inside Binnable objects simply reference the base union utility:

```dart
final preferredContactMethod = ContactMethod.union(EmailContactMethod());
final contactMethods = Bin.custom(list(ContactMethod.union), <ContactMethod>[]);
```

#### Custom Binned Fields

Implement `Binned` when a schema needs custom read/write behavior instead of
one stored value.

```dart
final class MagicHeader implements Binned {
  const MagicHeader(this.expected);

  final int expected;

  @override
  void read(ByteReader reader) {
    final actual = uint32.get(reader);

    if (actual != expected) {
      throw FormatException('Invalid magic header: $actual');
    }
  }

  @override
  void write(ByteWriter writer) {
    uint32.set(writer, expected);
  }
}

final class Packet with Binnable {
  static const magic = MagicHeader(0x5041434b);

  final version = Bin.uint8();
  final payload = Bin.utf8();

  @override
  Iterable<Binned> get bins => [magic, version, payload];
}
```

Custom `Binned` fields are useful for magic headers, padding, checksums,
alignment, version gates, and other schema steps that need direct stream access.

[coverage_badge]: coverage_badge.svg
[coverage_link]: coverage/lcov.info
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[minnesota_badge]: minnesota.svg
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
