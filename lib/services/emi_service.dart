import 'dart:math';

class EMIService {
  static List<Map<String, dynamic>> getEMIOptions(double amount) {
    return [
      {
        'bank': 'HDFC Bank Credit Card',
        'tenures': [
          {'months': 3, 'interest': 0}, // No cost EMI
          {'months': 6, 'interest': 0}, // No cost EMI
          {'months': 9, 'interest': 12}, // With interest
          {'months': 12, 'interest': 12}, // With interest
        ],
      },
      {
        'bank': 'ICICI Bank Credit Card',
        'tenures': [
          {'months': 3, 'interest': 0}, // No cost EMI
          {'months': 6, 'interest': 0}, // No cost EMI
          {'months': 9, 'interest': 13}, // With interest
          {'months': 12, 'interest': 13}, // With interest
        ],
      },
      {
        'bank': 'SBI Card',
        'tenures': [
          {'months': 3, 'interest': 0}, // No cost EMI
          {'months': 6, 'interest': 12}, // With interest
          {'months': 9, 'interest': 12}, // With interest
          {'months': 12, 'interest': 12}, // With interest
        ],
      },
    ];
  }

  static List<Map<String, dynamic>> getBankOffers() {
    return [
      {
        'bank': 'HDFC Bank',
        'type': 'Credit Card',
        'discount': 1000,
        'minPurchase': 10000,
        'description': '10% instant discount up to ₹1,000 on HDFC Bank Credit Card transactions',
      },
      {
        'bank': 'ICICI Bank',
        'type': 'Credit Card',
        'discount': 750,
        'minPurchase': 7500,
        'description': '10% instant discount up to ₹750 on ICICI Bank Credit Card transactions',
      },
      {
        'bank': 'SBI',
        'type': 'Credit Card',
        'discount': 500,
        'minPurchase': 5000,
        'description': '10% instant discount up to ₹500 on SBI Credit Card transactions',
      },
      {
        'bank': 'Axis Bank',
        'type': 'Credit Card',
        'discount': 750,
        'minPurchase': 7500,
        'description': '10% instant discount up to ₹750 on Axis Bank Credit Card transactions',
      },
      {
        'bank': 'Bank of Baroda',
        'type': 'Credit Card',
        'discount': 500,
        'minPurchase': 5000,
        'description': '10% instant discount up to ₹500 on Bank of Baroda Credit Card transactions',
      },
    ];
  }

  static List<Map<String, dynamic>> getPartnerOffers() {
    return [
      {
        'partner': 'GST Invoice',
        'discount': 28,
        'description': 'Get GST invoice and save up to 28% on business purchases',
      },
    ];
  }

  static Map<String, dynamic> getCashbackOffers() {
    return {
      'type': 'UPI Cashback',
      'amount': 23,
      'description': 'Get flat ₹23 cashback on paying using Amazon UPI',
      'terms': 'Min. transaction value ₹100',
    };
  }

  static double calculateEMI(double amount, int months, double interestRate) {
    if (interestRate == 0) {
      return amount / months;
    }
    
    double monthlyInterest = (interestRate / 12) / 100;
    double emi = amount * monthlyInterest * 
                 (pow(1 + monthlyInterest, months)) / 
                 (pow(1 + monthlyInterest, months) - 1);
    return emi;
  }
} 