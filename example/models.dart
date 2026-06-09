import 'package:bin/bin.dart';

/// A phone number category.
enum PhoneKind { home, mobile, work }

/// A portable address book snapshot.
final class AddressBook with Binnable {
  /// Binary payload type for address books.
  static final binType = obj(AddressBook.new);

  /// Name of the person who owns this address book.
  final owner = Bin.utf8();

  /// Optional contact to call first in an emergency.
  final emergencyContact = Bin.nullableObj(Contact.new);

  /// Contacts stored in insertion order.
  final contacts = Bin.custom(list(Contact.binType), <Contact>[]);

  /// Named groups with nested contact id sections.
  final groups = Bin.custom(
    map(string.utf8(), list(list(uint32))),
    <String, List<List<int>>>{},
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
  /// Binary payload type for contacts.
  static final binType = obj(Contact.new);

  /// Stable contact id used by group references.
  final id = Bin.uint32();

  /// Display name for this contact.
  final name = Bin.utf8();

  /// Phone numbers for this contact.
  final phoneNumbers = Bin.custom(
    map(enumeration(PhoneKind.values), string.utf8()),
    <PhoneKind, String>{},
  );

  /// Postal address lines.
  final addressLines = Bin.custom(list(string.utf8()), <String>[]);

  /// The preferred way to reach this contact.
  final preferredContactMethod = ContactMethod.union(
    EmailContactMethod(),
  );

  @override
  Iterable<Binned> get bins => [
    id,
    name,
    phoneNumbers,
    addressLines,
    preferredContactMethod,
  ];
}

/// A preferred contact method stored as a discriminated union.
sealed class ContactMethod with Binnable, Union {
  /// Union fields and payloads for contact methods.
  static final union = UnionType<ContactMethod, int>(
    uint8,
    {
      1: EmailContactMethod.new,
      2: PhoneContactMethod.new,
    },
  );
}

/// A contact method that stores an email address.
final class EmailContactMethod extends ContactMethod {
  /// Email address.
  final email = Bin.utf8();

  @override
  Iterable<Binned> get bins => [email];
}

/// A contact method that stores a phone kind and number.
final class PhoneContactMethod extends ContactMethod {
  /// Phone number category.
  final kind = Bin.enumeration(PhoneKind.values, PhoneKind.mobile);

  /// Phone number.
  final number = Bin.utf8();

  @override
  Iterable<Binned> get bins => [kind, number];
}
