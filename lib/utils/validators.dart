import '../constants/app_constants.dart';

/// Utility class for form validation
class Validators {
  Validators._();

  /// Validates email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.emailRequiredMessage;
    }
    
    if (!RegExp(AppConstants.emailRegex).hasMatch(value)) {
      return AppConstants.emailInvalidMessage;
    }
    
    return null;
  }

  /// Validates password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.passwordRequiredMessage;
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return AppConstants.passwordTooShortMessage;
    }
    
    return null;
  }

  /// Validates password with strength requirements
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.passwordRequiredMessage;
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return AppConstants.passwordTooShortMessage;
    }
    
    if (!RegExp(AppConstants.passwordRegex).hasMatch(value)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }
    
    return null;
  }

  /// Validates confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validates name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.nameRequiredMessage;
    }
    
    if (value.length < AppConstants.minNameLength) {
      return 'Name must be at least ${AppConstants.minNameLength} characters';
    }
    
    if (value.length > AppConstants.maxNameLength) {
      return 'Name must be less than ${AppConstants.maxNameLength} characters';
    }
    
    return null;
  }

  /// Validates phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.phoneRequiredMessage;
    }
    
    // Remove all non-digit characters for validation
    String cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (!RegExp(AppConstants.phoneRegex).hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// Validates required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.addressRequiredMessage;
    }
    
    if (value.length < 10) {
      return 'Address must be at least 10 characters';
    }
    
    return null;
  }

  /// Validates ZIP code
  static String? validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'ZIP code is required';
    }
    
    // Basic validation for various ZIP code formats
    if (value.length < 5 || value.length > 10) {
      return 'Please enter a valid ZIP code';
    }
    
    return null;
  }

  /// Validates price
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    double? price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    
    return null;
  }

  /// Validates quantity
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    
    int? quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid quantity';
    }
    
    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }
    
    return null;
  }

  /// Validates description
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    
    if (value.length > 1000) {
      return 'Description must be less than 1000 characters';
    }
    
    return null;
  }

  /// Validates review text
  static String? validateReview(String? value) {
    if (value == null || value.isEmpty) {
      return 'Review is required';
    }
    
    if (value.length < 5) {
      return 'Review must be at least 5 characters';
    }
    
    if (value.length > AppConstants.maxReviewCharacters) {
      return 'Review must be less than ${AppConstants.maxReviewCharacters} characters';
    }
    
    return null;
  }

  /// Validates URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional in most cases
    }
    
    try {
      Uri.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  /// Validates credit card number (basic validation)
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    
    // Remove spaces and dashes
    String cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Card number must contain only digits';
    }
    
    // Check length (most cards are 13-19 digits)
    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Invalid card number length';
    }
    
    // Luhn algorithm check
    if (!_isValidLuhn(cleaned)) {
      return 'Invalid card number';
    }
    
    return null;
  }

  /// Validates CVV
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3 or 4 digits';
    }
    
    return null;
  }

  /// Validates expiry date (MM/YY format)
  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Use MM/YY format';
    }
    
    List<String> parts = value.split('/');
    int month = int.parse(parts[0]);
    int year = int.parse('20${parts[1]}');
    
    if (month < 1 || month > 12) {
      return 'Invalid month';
    }
    
    DateTime now = DateTime.now();
    DateTime expiry = DateTime(year, month);
    
    if (expiry.isBefore(DateTime(now.year, now.month))) {
      return 'Card has expired';
    }
    
    return null;
  }

  /// Validates search query
  static String? validateSearchQuery(String? value) {
    if (value == null || value.isEmpty) {
      return 'Search query cannot be empty';
    }
    
    if (value.length < 2) {
      return 'Search query must be at least 2 characters';
    }
    
    return null;
  }

  /// Helper method for Luhn algorithm
  static bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool isEven = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      isEven = !isEven;
    }
    
    return sum % 10 == 0;
  }

  /// Validates if value is a valid number
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    
    return null;
  }

  /// Validates if value is a valid positive integer
  static String? validatePositiveInteger(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    int? number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }

  /// Validates date string
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  /// Validates email or phone number
  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email or phone number is required';
    }
    if (validateEmail(value) == null || validatePhone(value) == null) {
      return null;
    }
    return 'Please enter a valid email or phone number';
  }
} 