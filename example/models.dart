import 'package:bin/bin.dart';

/// A phone number category.
enum PhoneKind { home, mobile, work }

/// A portable address book snapshot.
final class AddressBook with Binnable {
  /// Name of the person who owns this address book.
  final Bin<String> owner = Bin.utf8();

  /// Optional contact to call first in an emergency.
  final Bin<Contact?> emergencyContact = Bin.nullableObj(Contact.new);

  /// Contacts stored in insertion order.
  final Bin<List<Contact>> contacts = Bin.custom(list(obj(Contact.new)), []);

  /// Named groups with nested contact id sections.
  final Bin<Map<String, List<List<int>>>> groups = Bin.custom(
    map(string.utf8(), list(list(uint32))),
    {},
  );

  @override
  Iterable<Binned> get bins => [
    owner,
    emergencyContact,
    contacts,
    groups,
  ];
}

/// A person or organization in the address book.
final class Contact with Binnable {
  /// Stable contact id used by group references.
  final Bin<int> id = Bin.uint32();

  /// Display name for this contact.
  final Bin<String> name = Bin.utf8();

  /// Phone numbers for this contact.
  final Bin<Map<PhoneKind, String>> phoneNumbers = Bin.custom(
    map(enumeration(PhoneKind.values), string.utf8()),
    {},
  );

  /// Postal address lines.
  final Bin<List<String>> addressLines = Bin.custom(list(string.utf8()), []);

  @override
  Iterable<Binned> get bins => [id, name, phoneNumbers, addressLines];
}
