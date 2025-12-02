class User {
  final int id;
  final String name;
  final String cpf;
  final String email;
  final String phone;
  final String? nfcCardUuid;

  User({
    required this.id,
    required this.name,
    required this.cpf,
    required this.email,
    required this.phone,
    this.nfcCardUuid,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      cpf: json['cpf'],
      email: json['email'],
      phone: json['phone'],
      nfcCardUuid: json['nfc_card_uuid'],
    );
  }
}
