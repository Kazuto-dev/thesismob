import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who is quoting: printed at the top of quotations and billings.
@immutable
class BusinessProfile {
  const BusinessProfile({
    this.name = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.tin = '',
    this.preparedBy = '',
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key] is String ? json[key] as String : '';
    return BusinessProfile(
      name: text('name'),
      address: text('address'),
      phone: text('phone'),
      email: text('email'),
      tin: text('tin'),
      preparedBy: text('preparedBy'),
    );
  }

  /// The business or contractor's name.
  final String name;
  final String address;
  final String phone;
  final String email;

  /// Taxpayer identification number, for VAT-registered contractors.
  final String tin;

  /// The person who signs the quotation.
  final String preparedBy;

  bool get isEmpty =>
      name.isEmpty &&
      address.isEmpty &&
      phone.isEmpty &&
      email.isEmpty &&
      tin.isEmpty &&
      preparedBy.isEmpty;

  Map<String, dynamic> toJson() => {
    if (name.isNotEmpty) 'name': name,
    if (address.isNotEmpty) 'address': address,
    if (phone.isNotEmpty) 'phone': phone,
    if (email.isNotEmpty) 'email': email,
    if (tin.isNotEmpty) 'tin': tin,
    if (preparedBy.isNotEmpty) 'preparedBy': preparedBy,
  };
}

/// The user's business profile, kept in this browser.
class ProfileController extends ChangeNotifier {
  ProfileController(this._prefs) : _profile = _load(_prefs);

  static const key = 'business_profile_v1';

  final SharedPreferences _prefs;
  BusinessProfile _profile;

  static BusinessProfile _load(SharedPreferences prefs) {
    final raw = prefs.getString(key);
    if (raw == null) return const BusinessProfile();
    try {
      return BusinessProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const BusinessProfile();
    }
  }

  BusinessProfile get profile => _profile;

  void update(BusinessProfile profile) {
    _profile = profile;
    unawaited(_prefs.setString(key, jsonEncode(profile.toJson())));
    notifyListeners();
  }
}
