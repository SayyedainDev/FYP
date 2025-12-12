// model: dentist user profile
class UserModel {
  final String uid;
  final String userId;
  final String firstName;
  final String lastName;
  final String cnic;
  final String address;
  final String highestEducation;
  final String email;

  UserModel({
    required this.uid,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.cnic,
    required this.address,
    required this.highestEducation,
    required this.email,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'userId': userId,
    'firstName': firstName,
    'lastName': lastName,
    'cnic': cnic,
    'address': address,
    'highestEducation': highestEducation,
    'email': email,
  };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    uid: m['uid'] ?? '',
    userId: m['userId'] ?? '',
    firstName: m['firstName'] ?? '',
    lastName: m['lastName'] ?? '',
    cnic: m['cnic'] ?? '',
    address: m['address'] ?? '',
    highestEducation: m['highestEducation'] ?? '',
    email: m['email'] ?? '',
  );
}
