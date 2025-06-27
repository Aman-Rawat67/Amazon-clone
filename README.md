# Amazon Clone - Flutter E-commerce App

A comprehensive Amazon-like e-commerce application built with Flutter and Firebase, featuring multi-role user management, complete shopping experience, and modern UI/UX.

## 🚀 Features

### 🔐 Authentication & User Management
- **Multi-role Authentication**: Customer, Vendor, and Admin roles
- **Email & Password Authentication** with Firebase Auth
- **Google Sign-In** integration
- **User Profile Management** with customizable profiles
- **Role-based Access Control** with secure navigation

### 🛍️ Customer Features
- **Product Catalog** with categories and search functionality
- **Advanced Product Search** with filters and sorting
- **Shopping Cart** with quantity management
- **Wishlist** functionality
- **Checkout Process** with multiple payment options
- **Order Tracking** with real-time status updates
- **Order History** with detailed order information
- **Address Management** for delivery locations
- **Product Reviews & Ratings**

### 👨‍💼 Vendor Features
- **Vendor Dashboard** with sales analytics
- **Product Management** (Add, Edit, Delete products)
- **Inventory Management** with stock tracking
- **Order Management** for vendor-specific orders
- **Sales Analytics** with detailed reports
- **Product Performance** metrics

### 👑 Admin Features
- **Admin Dashboard** with comprehensive analytics
- **Product Approval** system for vendor products
- **User Management** with role assignment
- **Order Management** across all vendors
- **System Analytics** and reporting
- **Content Moderation** tools

### 💳 Payment Integration
- **Razorpay** payment gateway
- **Stripe** payment processing
- **Cash on Delivery** option
- **Secure Payment** handling

### 📱 Technical Features
- **Responsive Design** for all screen sizes
- **Offline Support** with local storage
- **Push Notifications** via Firebase Cloud Messaging
- **Real-time Updates** with Firestore
- **Image Upload** with Firebase Storage
- **State Management** with Riverpod
- **Navigation** with GoRouter
- **Modern UI** with Material Design 3

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── constants/               # App constants and configurations
│   └── app_constants.dart
├── models/                  # Data models
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── cart_model.dart
│   └── order_model.dart
├── services/                # Business logic services
│   ├── auth_service.dart
│   └── firestore_service.dart
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   └── cart_provider.dart
├── screens/                 # UI screens
│   ├── auth/               # Authentication screens
│   ├── customer/           # Customer-specific screens
│   ├── vendor/             # Vendor-specific screens
│   └── admin/              # Admin-specific screens
├── widgets/                 # Reusable widgets
│   └── common/
└── utils/                   # Utility functions
```

### State Management
- **Riverpod** for dependency injection and state management
- **AsyncValue** for handling loading, data, and error states
- **StateNotifier** for complex state operations

### Database Schema (Firestore)
```
users/
  ├── {userId}/
      ├── name: String
      ├── email: String
      ├── role: String
      └── profileImageUrl: String?

products/
  ├── {productId}/
      ├── name: String
      ├── description: String
      ├── price: Number
      ├── vendorId: String
      ├── category: String
      ├── isApproved: Boolean
      └── images: Array

orders/
  ├── {orderId}/
      ├── userId: String
      ├── items: Array
      ├── total: Number
      ├── status: String
      └── shippingAddress: Object

carts/
  ├── {userId}/
      ├── items: Array
      ├── subtotal: Number
      └── total: Number
```

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (>=3.8.1)
- Dart SDK
- Android Studio / Xcode
- Firebase project

### Firebase Setup

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project named "amazon-clone-app"

2. **Enable Firebase Services**
   - Authentication (Email/Password, Google)
   - Firestore Database
   - Firebase Storage
   - Firebase Cloud Messaging

3. **Configure Firebase for Android**
   - Add Android app to Firebase project
   - Download `google-services.json`
   - Replace the template file in `android/app/google-services.json`
   - Update `android/app/build.gradle`

4. **Configure Firebase for iOS**
   - Add iOS app to Firebase project
   - Download `GoogleService-Info.plist`
   - Replace the template file in `ios/Runner/GoogleService-Info.plist`
   - Update `ios/Runner.xcodeproj`

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd amazon_clone
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Update Firebase configuration**
   - Replace template Firebase config files with your actual project files
   - Update package names in configuration files

4. **Run the app**
   ```bash
   flutter run
   ```

### Environment Configuration

Create a `.env` file in the root directory:
```env
# Razorpay Configuration
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
STRIPE_SECRET_KEY=your_stripe_secret_key

# API Configuration
API_BASE_URL=your_api_base_url
```

## 🎨 UI/UX Design

### Design System
- **Color Scheme**: Amazon-inspired orange and blue theme
- **Typography**: Custom Amazon Ember font family
- **Components**: Material Design 3 components
- **Responsive Layout**: Adaptive design for different screen sizes

### Key UI Features
- **Modern Card-based Design**
- **Smooth Animations** with Flutter's animation framework
- **Loading States** with shimmer effects
- **Error Handling** with user-friendly messages
- **Bottom Navigation** for easy access
- **Search Interface** with suggestions

## 📱 Screenshots

| Login Screen | Home Screen | Product Detail | Cart Screen |
|-------------|-------------|----------------|-------------|
| ![Login](screenshots/login.png) | ![Home](screenshots/home.png) | ![Product](screenshots/product.png) | ![Cart](screenshots/cart.png) |

| Vendor Dashboard | Admin Panel | Orders | Profile |
|-----------------|-------------|---------|---------|
| ![Vendor](screenshots/vendor.png) | ![Admin](screenshots/admin.png) | ![Orders](screenshots/orders.png) | ![Profile](screenshots/profile.png) |

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Test Coverage
- Authentication flows
- Product management
- Cart functionality
- Order processing
- Payment integration

## 🚀 Deployment

### Android Release
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS Release
```bash
flutter build ios --release
```

### Firebase Hosting (Web)
```bash
flutter build web
firebase deploy
```

## 📦 Dependencies

### Core Dependencies
- `flutter`: UI framework
- `firebase_core`: Firebase SDK
- `firebase_auth`: Authentication
- `cloud_firestore`: Database
- `firebase_storage`: File storage
- `firebase_messaging`: Push notifications

### State Management
- `flutter_riverpod`: State management
- `riverpod_annotation`: Code generation

### UI & Navigation
- `go_router`: Navigation
- `cached_network_image`: Image caching
- `carousel_slider`: Image carousels
- `shimmer`: Loading animations
- `lottie`: Advanced animations

### Payment
- `razorpay_flutter`: Razorpay integration
- `stripe_payment`: Stripe integration

### Utilities
- `shared_preferences`: Local storage
- `image_picker`: Image selection
- `url_launcher`: External links
- `intl`: Internationalization

## 🔄 CI/CD

### GitHub Actions
- Automated testing on pull requests
- Code quality checks with Flutter analyze
- Build verification for Android and iOS

### Firebase App Distribution
- Automatic beta builds distribution
- Crash reporting with Firebase Crashlytics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow Flutter/Dart style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent indentation

### Commit Messages
Use conventional commit format:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `style:` for formatting
- `refactor:` for code refactoring

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Email: support@amazonclone.com
- Documentation: [Wiki](https://github.com/username/amazon_clone/wiki)

## 🎯 Roadmap

### Version 2.0
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Video product reviews
- [ ] AR try-on features
- [ ] Voice search
- [ ] Live chat support

### Version 3.0
- [ ] Machine learning recommendations
- [ ] Advanced analytics dashboard
- [ ] Subscription services
- [ ] Multi-currency support
- [ ] Advanced inventory management

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for backend services
- Material Design for UI guidelines
- Amazon for design inspiration
- Open source community for various packages

---

**Built with ❤️ using Flutter and Firebase**
