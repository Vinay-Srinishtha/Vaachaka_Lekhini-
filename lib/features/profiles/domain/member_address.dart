import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum AddressType {
  home,
  work,
  other;

  String get label => switch (this) {
        AddressType.home => 'Home',
        AddressType.work => 'Work',
        AddressType.other => 'Other',
      };
}

// All 28 states + 8 UTs of India.
const kIndianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  // Union Territories
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
];

class MemberAddress extends Equatable {
  const MemberAddress({
    required this.id,
    required this.type,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.country = 'IN',
  });

  final String id;
  final AddressType type;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final String country;

  factory MemberAddress.blank() => MemberAddress(
        id: const Uuid().v4(),
        type: AddressType.home,
        line1: '',
        city: '',
        state: '',
        pincode: '',
      );

  MemberAddress copyWith({
    AddressType? type,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
  }) =>
      MemberAddress(
        id: id,
        type: type ?? this.type,
        line1: line1 ?? this.line1,
        line2: line2 ?? this.line2,
        city: city ?? this.city,
        state: state ?? this.state,
        pincode: pincode ?? this.pincode,
        country: country,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'line1': line1,
        if (line2 != null && line2!.isNotEmpty) 'line2': line2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'country': country,
      };

  factory MemberAddress.fromJson(Map<String, dynamic> j) => MemberAddress(
        id: j['id'] as String? ?? const Uuid().v4(),
        type: AddressType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => AddressType.home,
        ),
        line1: j['line1'] as String? ?? '',
        line2: j['line2'] as String?,
        city: j['city'] as String? ?? '',
        state: j['state'] as String? ?? '',
        pincode: j['pincode'] as String? ?? '',
        country: j['country'] as String? ?? 'IN',
      );

  bool get isValid =>
      line1.trim().isNotEmpty &&
      state.isNotEmpty &&
      pincode.trim().length == 6;

  String get summary {
    final parts = [
      line1,
      if (line2 != null && line2!.isNotEmpty) line2!,
      city,
      state,
      pincode,
    ];
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [id, type, line1, line2, city, state, pincode, country];
}
