import 'package:flutter/material.dart';

/// Application constants for the Amazon clone app
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Amazon Clone';
  static const String appVersion = '1.0.0';

  // API Keys (In production, these should be stored securely)
  static const String razorpayApiKey = 'YOUR_RAZORPAY_API_KEY';
  static const String stripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String cartsCollection = 'carts';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';
  static const String wishlistCollection = 'wishlist';
  static const String addressesCollection = 'addresses';
  static const String bannersCollection = 'banners';
  static const String couponsCollection = 'coupons';

  // Storage Paths
  static const String productImagesPath = 'products';
  static const String userImagesPath = 'users';
  static const String bannerImagesPath = 'banners';

  // Shared Preferences Keys
  static const String userKey = 'user';
  static const String cartKey = 'cart';
  static const String themeKey = 'theme';
  static const String languageKey = 'language';
  static const String fcmTokenKey = 'fcm_token';

  // Product Categories
  static const List<String> productCategories = [
    'Electronics',
    'Fashion',
    'Home & Kitchen',
    'Books',
    'Sports',
    'Health & Beauty',
    'Toys & Games',
    'Automotive',
    'Grocery',
    'Jewelry',
  ];

  // Order Settings
  static const double freeShippingThreshold = 500.0;
  static const double standardShippingCost = 50.0;
  static const double taxRate = 0.18; // 18% GST
  static const int orderTrackingDays = 30;

  // App Limits
  static const int maxCartItems = 50;
  static const int maxWishlistItems = 100;
  static const int maxAddresses = 10;
  static const int maxProductImages = 10;
  static const int maxReviewCharacters = 500;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // File Sizes (in bytes)
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Network Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Support
  static const String supportEmail = 'support@amazonclone.com';
  static const String supportPhone = '+91-1234567890';

  // URLs
  static const String privacyPolicyUrl = 'https://amazonclone.com/privacy';
  static const String termsOfServiceUrl = 'https://amazonclone.com/terms';
  static const String aboutUsUrl = 'https://amazonclone.com/about';

  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
  static const String permissionErrorMessage = 'Permission denied.';

  // Success Messages
  static const String itemAddedToCartMessage = 'Item added to cart successfully!';
  static const String itemRemovedFromCartMessage = 'Item removed from cart!';
  static const String orderPlacedMessage = 'Order placed successfully!';
  static const String profileUpdatedMessage = 'Profile updated successfully!';
  static const String addressAddedMessage = 'Address added successfully!';

  // Validation Messages
  static const String emailRequiredMessage = 'Email is required';
  static const String emailInvalidMessage = 'Please enter a valid email';
  static const String passwordRequiredMessage = 'Password is required';
  static const String passwordTooShortMessage = 'Password must be at least 6 characters';
  static const String nameRequiredMessage = 'Name is required';
  static const String phoneRequiredMessage = 'Phone number is required';
  static const String addressRequiredMessage = 'Address is required';

  // Regular Expressions
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const String passwordRegex = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{6,}$';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Image Placeholders
  static const String productPlaceholder = 'assets/images/product_placeholder.png';
  static const String userPlaceholder = 'assets/images/user_placeholder.png';
  static const String logoPath = 'assets/images/logo.png';

  // Lottie Animations
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String successAnimation = 'assets/animations/success.json';
  static const String errorAnimation = 'assets/animations/error.json';
  static const String emptyCartAnimation = 'assets/animations/empty_cart.json';
}

/// Color constants for the app theme
class AppColors {
  AppColors._();

  // Primary Colors (Amazon-like)
  static const Color primary = Color(0xFF232F3E);
  static const Color primaryLight = Color(0xFF37475A);
  static const Color primaryDark = Color(0xFF131A22);

  // Secondary Colors
  static const Color secondary = Color(0xFFFF9900);
  static const Color secondaryLight = Color(0xFFFFB84D);
  static const Color secondaryDark = Color(0xFFCC7700);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F8F8);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFFBDBDBD);

  // Rating Color
  static const Color rating = Color(0xFFFFB400);

  // Discount Color
  static const Color discount = Color(0xFFE53E3E);

  // Shipping Colors
  static const Color freeShipping = Color(0xFF22C55E);
  static const Color expressShipping = Color(0xFFEF4444);

  // Social Colors
  static const Color google = Color(0xFFDB4437);
  static const Color facebook = Color(0xFF4267B2);
  static const Color apple = Color(0xFF000000);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFFBB86FC);
}

/// Dimension constants for the app
class AppDimensions {
  AppDimensions._();

  // Padding
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Margin
  static const double marginXSmall = 4.0;
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;
  static const double marginXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusRound = 50.0;

  // Component Heights
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardHeight = 120.0;
  static const double productCardHeight = 280.0;
  static const double bannerHeight = 200.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Font Sizes
  static const double fontSmall = 12.0;
  static const double fontMedium = 14.0;
  static const double fontLarge = 16.0;
  static const double fontXLarge = 18.0;
  static const double fontTitle = 20.0;
  static const double fontHeading = 24.0;

  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Image Sizes
  static const double imageSmall = 64.0;
  static const double imageMedium = 120.0;
  static const double imageLarge = 200.0;
  static const double imageXLarge = 300.0;
} 