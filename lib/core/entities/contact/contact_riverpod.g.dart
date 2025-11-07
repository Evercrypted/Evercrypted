// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Contacts)
const contactsProvider = ContactsProvider._();

final class ContactsProvider
    extends $NotifierProvider<Contacts, List<Contact>> {
  const ContactsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'contactsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$contactsHash();

  @$internal
  @override
  Contacts create() => Contacts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Contact> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Contact>>(value),
    );
  }
}

String _$contactsHash() => r'39ce309266f52dcbc5595735dbcae73e897fada4';

abstract class _$Contacts extends $Notifier<List<Contact>> {
  List<Contact> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<Contact>, List<Contact>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<Contact>, List<Contact>>,
        List<Contact>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
