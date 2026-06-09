import 'dart:io';

import 'package:bin/bin.dart';

import 'models.dart';

void main() {
  final addressBook = AddressBook()
    ..owner.value = 'Bob'
    ..emergencyContact.value = (Contact()
      ..id.value = 7
      ..name.value = 'Alice'
      ..phoneNumbers.value = {PhoneKind.mobile: '1-234-5678'}
      ..preferredContactMethod.value = (PhoneContactMethod()
        ..kind.value = PhoneKind.mobile
        ..number.value = '1-234-5678'))
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
        ]
        ..preferredContactMethod.value = (EmailContactMethod()
          ..email.value = 'alice@example.com'),
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
  final firstPreferredMethod =
      decoded.contacts.value.first.preferredContactMethod.value.runtimeType;

  stdout
    ..writeln('Encoded ${bytes.length} bytes.')
    ..writeln('Owner: ${decoded.owner.value}')
    ..writeln('Contacts: ${decoded.contacts.value.length}')
    ..writeln(
      'Emergency contact: ${decoded.emergencyContact.value?.name.value}',
    )
    ..writeln(
      'First preferred method: '
      '$firstPreferredMethod',
    )
    ..writeln(
      'Family group: '
      '${decoded.groups.value['family']}',
    );
}
