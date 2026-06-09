import 'package:bin/bin.dart';
import 'package:test/test.dart';

import '../../example/models.dart';

void main() {
  group('$Bin', () {
    test('convenience constructors round trip values', () {
      final record = _ConvenienceRecord()
        ..boolean.value = true
        ..int8.value = -8
        ..int16.value = -16
        ..int32.value = -32
        ..int64.value = -64
        ..uint8Bin.value = 8
        ..uint16Bin.value = 16
        ..uint32Bin.value = 32
        ..uint64Bin.value = 64
        ..float32Bin.value = 1.5
        ..float64Bin.value = 2.5
        ..utf8.value = 'hello'
        ..latin1.value = 'cafe'
        ..ascii.value = 'abc'
        ..enumBin.value = PhoneKind.work
        ..nullableUint8.value = 3
        ..contact.value = (Contact()
          ..id.value = 1
          ..name.value = 'Bob');

      final decoded = decode(
        _ConvenienceRecord.binType,
        encode(_ConvenienceRecord.binType, record),
      );

      expect(decoded.boolean.value, isTrue);
      expect(decoded.int8.value, -8);
      expect(decoded.int16.value, -16);
      expect(decoded.int32.value, -32);
      expect(decoded.int64.value, -64);
      expect(decoded.uint8Bin.value, 8);
      expect(decoded.uint16Bin.value, 16);
      expect(decoded.uint32Bin.value, 32);
      expect(decoded.uint64Bin.value, 64);
      expect(decoded.float32Bin.value, 1.5);
      expect(decoded.float64Bin.value, 2.5);
      expect(decoded.utf8.value, 'hello');
      expect(decoded.latin1.value, 'cafe');
      expect(decoded.ascii.value, 'abc');
      expect(decoded.enumBin.value, PhoneKind.work);
      expect(decoded.nullableUint8.value, 3);
      expect(decoded.contact.value.id.value, 1);
      expect(decoded.contact.value.name.value, 'Bob');
    });

    test('reads and writes scalar fields', () {
      final contact = Contact()
        ..id.value = 42
        ..name.value = 'Alice';

      final decoded = decode(Contact.binType, encode(Contact.binType, contact));

      expect(decoded.id.value, 42);
      expect(decoded.name.value, 'Alice');
    });

    test('replaces child objects when reading', () {
      final emergencyContact = Contact()
        ..id.value = 7
        ..name.value = 'Alice';
      final addressBook = AddressBook()
        ..emergencyContact.value = emergencyContact;

      final bytes = encode(AddressBook.binType, addressBook);
      emergencyContact
        ..id.value = 0
        ..name.value = '';

      addressBook.read(ByteReader(bytes));

      expect(
        identical(addressBook.emergencyContact.value, emergencyContact),
        isFalse,
      );
      expect(addressBook.emergencyContact.value?.id.value, 7);
      expect(addressBook.emergencyContact.value?.name.value, 'Alice');
    });

    test('reads nullable child objects', () {
      final addressBook = AddressBook()
        ..emergencyContact.value = (Contact()
          ..id.value = 7
          ..name.value = 'Alice');

      final bytes = encode(AddressBook.binType, addressBook);
      addressBook.emergencyContact.value = null;
      addressBook.read(ByteReader(bytes));

      expect(addressBook.emergencyContact.value?.id.value, 7);
      expect(addressBook.emergencyContact.value?.name.value, 'Alice');
    });

    test('clears nullable child objects when null is read', () {
      final addressBook = AddressBook()
        ..emergencyContact.value = (Contact()
          ..id.value = 7
          ..name.value = 'Alice');
      final source = AddressBook();

      final bytes = encode(AddressBook.binType, source);
      addressBook.read(ByteReader(bytes));

      expect(addressBook.emergencyContact.value, isNull);
    });

    test('reads and writes lists of child objects', () {
      final contact = Contact()
        ..id.value = 7
        ..name.value = 'Alice'
        ..phoneNumbers.value = {
          PhoneKind.home: '1-234-5678',
          PhoneKind.mobile: '1-234-5678',
          PhoneKind.work: '1-234-5678',
        };

      final bytes = encode(Contact.binType, contact);
      contact.phoneNumbers.value = {};
      contact.read(ByteReader(bytes));

      expect(
        contact.phoneNumbers.value.keys,
        [PhoneKind.home, PhoneKind.mobile, PhoneKind.work],
      );
      expect(
        contact.phoneNumbers.value.values,
        ['1-234-5678', '1-234-5678', '1-234-5678'],
      );
    });

    test('reads and writes maps of nested contact id lists', () {
      final addressBook = AddressBook()
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
      addressBook.groups.value = {};
      addressBook.read(ByteReader(bytes));

      expect(addressBook.groups.value.keys, ['family', 'work']);
      expect(addressBook.groups.value['family'], [
        [7],
        [12],
      ]);
      expect(addressBook.groups.value['work'], [
        [12],
      ]);
    });

    test('reads and writes union fields', () {
      final contact = Contact()
        ..preferredContactMethod.value = (PhoneContactMethod()
          ..kind.value = PhoneKind.work
          ..number.value = '1-234-5678');

      final decoded = decode(Contact.binType, encode(Contact.binType, contact));
      final preferredContactMethod = decoded.preferredContactMethod.value;

      expect(preferredContactMethod, isA<PhoneContactMethod>());
      expect(
        (preferredContactMethod as PhoneContactMethod).kind.value,
        PhoneKind.work,
      );
      expect(preferredContactMethod.number.value, '1-234-5678');
    });

    test('reads and writes nullable union fields', () {
      final record = _NullableUnionRecord()
        ..contactMethod.value = (EmailContactMethod()
          ..email.value = 'alice@example.com');

      final decoded = decode(
        _NullableUnionRecord.binType,
        encode(_NullableUnionRecord.binType, record),
      );
      final contactMethod = decoded.contactMethod.value;

      expect(contactMethod, isA<EmailContactMethod>());
      expect(
        (contactMethod! as EmailContactMethod).email.value,
        'alice@example.com',
      );

      record.contactMethod.value = null;

      final decodedNull = decode(
        _NullableUnionRecord.binType,
        encode(_NullableUnionRecord.binType, record),
      );

      expect(decodedNull.contactMethod.value, isNull);
    });

    test('rejects duplicate union variant types', () {
      expect(
        () => UnionType<_TestUnion, int>(
          uint8,
          {
            1: _TestUnionA.new,
            2: _TestUnionA.new,
          },
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty union variants', () {
      expect(
        () => UnionType<_TestUnion, int>(uint8, {}),
        throwsArgumentError,
      );
    });

    test('rejects unknown union type ids', () {
      final writer = ByteWriter();
      uint8.set(writer, 255);

      expect(
        () => ContactMethod.union.get(ByteReader(writer.toBytes())),
        throwsStateError,
      );
    });

    test('rejects unknown union variant types', () {
      final union = UnionType<_TestUnion, int>(
        uint8,
        {1: _TestUnionA.new},
      );

      expect(
        () => union.set(ByteWriter(), _TestUnionB()),
        throwsStateError,
      );
    });

    test('reads and writes union roots at byte boundaries', () {
      final contactMethod = PhoneContactMethod()
        ..kind.value = PhoneKind.work
        ..number.value = '1-234-5678';

      final decoded = decode(
        ContactMethod.union,
        encode(ContactMethod.union, contactMethod),
      );

      expect(decoded, isA<PhoneContactMethod>());
      expect((decoded as PhoneContactMethod).kind.value, PhoneKind.work);
      expect(decoded.number.value, '1-234-5678');
    });
  });
}

final class _ConvenienceRecord with Binnable {
  static final binType = obj(_ConvenienceRecord.new);

  final Bin<bool> boolean = Bin.boolean();
  final Bin<int> int8 = Bin.int8();
  final Bin<int> int16 = Bin.int16();
  final Bin<int> int32 = Bin.int32();
  final Bin<int> int64 = Bin.int64();
  final Bin<int> uint8Bin = Bin.uint8();
  final Bin<int> uint16Bin = Bin.uint16();
  final Bin<int> uint32Bin = Bin.uint32();
  final Bin<int> uint64Bin = Bin.uint64();
  final Bin<double> float32Bin = Bin.float32();
  final Bin<double> float64Bin = Bin.float64();
  final Bin<String> utf8 = Bin.utf8();
  final Bin<String> latin1 = Bin.latin1();
  final Bin<String> ascii = Bin.ascii();
  final Bin<PhoneKind> enumBin = Bin.enumeration(
    PhoneKind.values,
    PhoneKind.home,
  );
  final Bin<int?> nullableUint8 = Bin.nullable(uint8);
  final Bin<Contact> contact = Bin.obj(Contact.new);

  @override
  Iterable<Binned> get bins => [
    boolean,
    int8,
    int16,
    int32,
    int64,
    uint8Bin,
    uint16Bin,
    uint32Bin,
    uint64Bin,
    float32Bin,
    float64Bin,
    utf8,
    latin1,
    ascii,
    enumBin,
    nullableUint8,
    contact,
  ];
}

final class _NullableUnionRecord with Binnable {
  static final binType = obj(_NullableUnionRecord.new);

  final contactMethod = ContactMethod.union.nullable();

  @override
  Iterable<Binned> get bins => [contactMethod];
}

abstract base class _TestUnion with Binnable, Union {}

final class _TestUnionA extends _TestUnion {
  @override
  Iterable<Binned> get bins => [];
}

final class _TestUnionB extends _TestUnion {
  @override
  Iterable<Binned> get bins => [];
}
