class UserMeResponse {
  const UserMeResponse({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.bio,
    required this.city,
    this.preferredLanguage,
    required this.phone,
    required this.theme,
    required this.notifyNewMessage,
    required this.notifyContactRequest,
    required this.notifyListingFavorited,
    required this.avatarUrl,
    required this.status,
    required this.emailVerified,
    required this.phoneVerified,
    required this.profileCompleted,
    required this.trustScore,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String fullName;
  final String firstName;
  final String lastName;
  final String email;
  final String bio;
  final String city;
  final String? preferredLanguage;
  final String phone;
  final String theme;
  final bool notifyNewMessage;
  final bool notifyContactRequest;
  final bool notifyListingFavorited;
  /// Absolute `http(s)://` from API, null if none; legacy responses may use `/…` paths.
  final String? avatarUrl;
  final String status;
  final bool emailVerified;
  final bool phoneVerified;
  final bool profileCompleted;
  final int trustScore;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserMeResponse.fromJson(Map<String, dynamic> json) {
    return UserMeResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      city: json['city'] as String? ?? '',
      preferredLanguage: json['preferred_language'] as String?,
      phone: json['phone'] as String? ?? '',
      theme: json['theme'] as String? ?? 'system',
      notifyNewMessage: json['notify_new_message'] as bool? ?? true,
      notifyContactRequest: json['notify_contact_request'] as bool? ?? true,
      notifyListingFavorited:
          json['notify_listing_favorited'] as bool? ?? true,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String? ?? 'active',
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      profileCompleted: json['profile_completed'] as bool? ?? false,
      trustScore: (json['trust_score'] as num?)?.toInt() ?? 0,
      lastSeenAt: DateTime.tryParse(json['last_seen_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}

class UpdateUserMeRequest {
  const UpdateUserMeRequest({
    this.fullName,
    this.firstName,
    this.lastName,
    this.bio,
    this.city,
    this.preferredLanguage,
    this.phone,
    this.theme,
    this.notifyNewMessage,
    this.notifyContactRequest,
    this.notifyListingFavorited,
  });

  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? city;
  final String? preferredLanguage;
  final String? phone;
  final String? theme;
  final bool? notifyNewMessage;
  final bool? notifyContactRequest;
  final bool? notifyListingFavorited;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'bio': bio,
      'city': city,
      'preferred_language': preferredLanguage,
      'phone': phone,
      'theme': theme,
      'notify_new_message': notifyNewMessage,
      'notify_contact_request': notifyContactRequest,
      'notify_listing_favorited': notifyListingFavorited,
    }..removeWhere((key, value) => value == null);
  }
}

class FieldValidationError {
  const FieldValidationError({required this.field, required this.message});

  final String field;
  final String message;

  factory FieldValidationError.fromJson(Map<String, dynamic> json) {
    return FieldValidationError(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? 'Validation failed.',
    );
  }
}

class AvatarUploadResponse {
  const AvatarUploadResponse({
    this.avatarUrl,
    required this.contentType,
    required this.sizeBytes,
  });

  /// Absolute `http(s)://` URL from the server, or null if not set.
  final String? avatarUrl;
  final String contentType;
  final int sizeBytes;

  factory AvatarUploadResponse.fromJson(Map<String, dynamic> json) {
    return AvatarUploadResponse(
      avatarUrl: json['avatar_url'] as String?,
      contentType: json['content_type'] as String? ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return {'current_password': currentPassword, 'new_password': newPassword};
  }
}

class DetailMessageResponse {
  const DetailMessageResponse({required this.detail});

  final String detail;

  factory DetailMessageResponse.fromJson(Map<String, dynamic> json) {
    return DetailMessageResponse(detail: json['detail'] as String? ?? '');
  }
}

class ProfileCompletenessDto {
  const ProfileCompletenessDto({
    required this.percentage,
    required this.completedFields,
    required this.missingFields,
  });

  final int percentage;
  final List<String> completedFields;
  final List<String> missingFields;

  factory ProfileCompletenessDto.fromJson(Map<String, dynamic> json) {
    return ProfileCompletenessDto(
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      completedFields: (json['completed_fields'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      missingFields: (json['missing_fields'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
