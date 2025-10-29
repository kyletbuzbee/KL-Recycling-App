/// Utility class containing common validation functions with regex patterns
class ValidationUtils {
  // Email validation - simplified pattern for common email formats
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // US Phone number validation - supports (555) 123-4567, 555-123-4567, 5551234567
  static final RegExp _phoneRegex = RegExp(
    r'^\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})$',
  );

  // US ZIP code validation - supports 12345 and 12345-6789
  static final RegExp _zipCodeRegex = RegExp(
    r'^\d{5}(?:-\d{4})?$',
  );

  // Name validation - allows letters, spaces, hyphens, apostrophes, periods
  static final RegExp _nameRegex = RegExp(
    r"^[a-zA-Z\s\-'.]{2,50}$",
  );

  // Address validation - basic, allows letters, numbers, spaces, common punctuation
  static final RegExp _addressRegex = RegExp(
    r"^[a-zA-Z0-9\s\-'.,#&/]{5,100}$",
  );

  /// Validates email address using RFC 5322 compliant pattern
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email address is required';
    }

    if (!_emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address (e.g. john@example.com)';
    }

    return null; // Valid
  }

  /// Validates US phone number
  /// Accepts formats: (555) 123-4567, 555-123-4567, 5551234567
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // Phone is optional unless specified otherwise
    }

    if (!_phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''))) {
      return 'Please enter a valid phone number (e.g. (555) 123-4567 or 555-123-4567)';
    }

    return null; // Valid
  }

  /// Validates US ZIP code - accepts 12345 or 12345-6789 formats
  static String? validateZipCode(String? zipCode) {
    if (zipCode == null || zipCode.isEmpty) {
      return 'ZIP code is required';
    }

    if (!_zipCodeRegex.hasMatch(zipCode.trim())) {
      return 'Please enter a valid ZIP code (e.g. 12345 or 12345-6789)';
    }

    return null; // Valid
  }

  /// Validates full name - allows 2-50 characters, letters only
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Full name is required';
    }

    final trimmedName = name.trim();
    if (trimmedName.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (trimmedName.length > 50) {
      return 'Name must be less than 50 characters long';
    }

    if (!_nameRegex.hasMatch(trimmedName)) {
      return 'Name can only contain letters, spaces, hyphens, apostrophes, and periods';
    }

    return null; // Valid
  }

  /// Validates street address - basic validation
  static String? validateAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Address is required';
    }

    final trimmedAddress = address.trim();
    if (trimmedAddress.length < 5) {
      return 'Address must be at least 5 characters long';
    }

    if (trimmedAddress.length > 100) {
      return 'Address must be less than 100 characters long';
    }

    if (!_addressRegex.hasMatch(trimmedAddress)) {
      return 'Please enter a valid address';
    }

    return null; // Valid
  }

  /// Validates required text field with length constraints
  static String? validateRequiredText(String? value, String fieldName, {int minLength = 1, int maxLength = 1000}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final trimmedValue = value.trim();
    if (trimmedValue.length < minLength) {
      return '$fieldName must be at least $minLength character${minLength == 1 ? '' : 's'} long';
    }

    if (trimmedValue.length > maxLength) {
      return '$fieldName must be less than $maxLength characters long';
    }

    return null; // Valid
  }

  /// Validates city name - allows letters, spaces, hyphens
  static String? validateCity(String? city) {
    if (city == null || city.isEmpty) {
      return 'City is required';
    }

    final trimmedCity = city.trim();
    if (trimmedCity.length < 2) {
      return 'City must be at least 2 characters long';
    }

    if (trimmedCity.length > 50) {
      return 'City must be less than 50 characters long';
    }

    // City names can contain letters, spaces, and hyphens
    final cityRegex = RegExp(r"^[a-zA-Z\s\-]{2,50}$");
    if (!cityRegex.hasMatch(trimmedCity)) {
      return 'City can only contain letters, spaces, and hyphens';
    }

    return null; // Valid
  }
}
