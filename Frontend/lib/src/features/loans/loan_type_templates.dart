import 'loan_models.dart';

class LoanTypeTemplate {
  final String key;
  final String label;
  final Map<String, dynamic> schema;
  final List<String> requiredDocuments;

  const LoanTypeTemplate({
    required this.key,
    required this.label,
    required this.schema,
    required this.requiredDocuments,
  });
}

const List<LoanTypeTemplate> loanTypeTemplates = <LoanTypeTemplate>[
  LoanTypeTemplate(
    key: 'PERSONAL',
    label: 'Personal Loan',
    schema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'monthlyIncome': <String, dynamic>{
          'type': 'number',
          'description': 'Net monthly income',
        },
        'employmentType': <String, dynamic>{
          'type': 'string',
          'description': 'Salaried or self-employed',
        },
        'employerName': <String, dynamic>{
          'type': 'string',
          'description': 'Current employer/business name',
        },
        'existingEmi': <String, dynamic>{
          'type': 'number',
          'description': 'Existing monthly EMI (if any)',
        },
        'loanPurpose': <String, dynamic>{
          'type': 'string',
          'description': 'Purpose of loan',
        },
      },
      'required': <String>['monthlyIncome', 'loanPurpose'],
      'additionalProperties': true,
    },
    requiredDocuments: <String>['ID_PROOF', 'ADDRESS_PROOF', 'PAN_CARD'],
  ),
  LoanTypeTemplate(
    key: 'BUSINESS',
    label: 'Business Loan',
    schema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'businessName': <String, dynamic>{
          'type': 'string',
          'description': 'Registered business name',
        },
        'gstNumber': <String, dynamic>{
          'type': 'string',
          'description': 'GST registration number',
        },
        'annualTurnover': <String, dynamic>{
          'type': 'number',
          'description': 'Annual turnover',
        },
        'yearsInBusiness': <String, dynamic>{
          'type': 'integer',
          'description': 'Number of years in business',
        },
        'monthlyRevenue': <String, dynamic>{
          'type': 'number',
          'description': 'Average monthly revenue',
        },
        'businessAddress': <String, dynamic>{
          'type': 'string',
          'description': 'Business address',
        },
        'loanPurpose': <String, dynamic>{
          'type': 'string',
          'description': 'Working capital, expansion, etc.',
        },
      },
      'required': <String>[
        'businessName',
        'gstNumber',
        'annualTurnover',
        'yearsInBusiness',
        'loanPurpose',
      ],
      'additionalProperties': true,
    },
    requiredDocuments: <String>['PAN_CARD', 'BANK_STATEMENT', 'ID_PROOF', 'ADDRESS_PROOF'],
  ),
  LoanTypeTemplate(
    key: 'HOME',
    label: 'Home Loan',
    schema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'propertyValue': <String, dynamic>{
          'type': 'number',
          'description': 'Total property value',
        },
        'downPayment': <String, dynamic>{
          'type': 'number',
          'description': 'Expected down payment',
        },
        'propertyAddress': <String, dynamic>{
          'type': 'string',
          'description': 'Address of the property',
        },
        'propertyType': <String, dynamic>{
          'type': 'string',
          'description': 'Flat, house, plot, etc.',
        },
        'monthlyIncome': <String, dynamic>{
          'type': 'number',
          'description': 'Net monthly income',
        },
      },
      'required': <String>['propertyValue', 'propertyAddress', 'monthlyIncome'],
      'additionalProperties': true,
    },
    requiredDocuments: <String>['ID_PROOF', 'ADDRESS_PROOF', 'PAN_CARD', 'BANK_STATEMENT'],
  ),
  LoanTypeTemplate(
    key: 'VEHICLE',
    label: 'Vehicle Loan',
    schema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'vehicleType': <String, dynamic>{
          'type': 'string',
          'description': 'Car, bike, commercial vehicle, etc.',
        },
        'vehicleMakeModel': <String, dynamic>{
          'type': 'string',
          'description': 'Vehicle make and model',
        },
        'onRoadPrice': <String, dynamic>{
          'type': 'number',
          'description': 'On-road vehicle price',
        },
        'downPayment': <String, dynamic>{
          'type': 'number',
          'description': 'Expected down payment',
        },
        'dealerName': <String, dynamic>{
          'type': 'string',
          'description': 'Dealer name',
        },
      },
      'required': <String>['vehicleType', 'vehicleMakeModel', 'onRoadPrice'],
      'additionalProperties': true,
    },
    requiredDocuments: <String>['ID_PROOF', 'ADDRESS_PROOF', 'PAN_CARD'],
  ),
  LoanTypeTemplate(
    key: 'EDUCATION',
    label: 'Education Loan',
    schema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'courseName': <String, dynamic>{
          'type': 'string',
          'description': 'Name of course/program',
        },
        'institutionName': <String, dynamic>{
          'type': 'string',
          'description': 'College or institution',
        },
        'courseDurationMonths': <String, dynamic>{
          'type': 'integer',
          'description': 'Course duration in months',
        },
        'tuitionFee': <String, dynamic>{
          'type': 'number',
          'description': 'Total tuition fee',
        },
        'annualFamilyIncome': <String, dynamic>{
          'type': 'number',
          'description': 'Annual family income',
        },
      },
      'required': <String>[
        'courseName',
        'institutionName',
        'courseDurationMonths',
        'annualFamilyIncome',
      ],
      'additionalProperties': true,
    },
    requiredDocuments: <String>['ID_PROOF', 'ADDRESS_PROOF', 'PAN_CARD'],
  ),
];

LoanTypeTemplate? findLoanTypeTemplateByKey(String key) {
  final normalized = key.trim().toUpperCase();
  for (final template in loanTypeTemplates) {
    if (template.key == normalized) return template;
  }
  return null;
}

LoanTypeTemplate? inferLoanTypeTemplate({
  String? code,
  String? name,
  LoanTypeOption? loanType,
}) {
  final parts = <String>[
    if (code != null) code.toUpperCase(),
    if (name != null) name.toUpperCase(),
    if (loanType?.code != null) loanType!.code!.toUpperCase(),
    if (loanType?.name != null) loanType!.name.toUpperCase(),
  ];

  bool containsAny(String key, List<String> hints) {
    for (final p in parts) {
      if (p.contains(key)) return true;
      for (final hint in hints) {
        if (p.contains(hint)) return true;
      }
    }
    return false;
  }

  if (containsAny('BUSINESS', <String>['MSME', 'SHOP'])) {
    return findLoanTypeTemplateByKey('BUSINESS');
  }
  if (containsAny('PERSONAL', <String>['SALARY', 'SALARIED'])) {
    return findLoanTypeTemplateByKey('PERSONAL');
  }
  if (containsAny('HOME', <String>['HOUSE', 'PROPERTY', 'MORTGAGE'])) {
    return findLoanTypeTemplateByKey('HOME');
  }
  if (containsAny('VEHICLE', <String>['AUTO', 'CAR', 'BIKE'])) {
    return findLoanTypeTemplateByKey('VEHICLE');
  }
  if (containsAny('EDUCATION', <String>['STUDENT'])) {
    return findLoanTypeTemplateByKey('EDUCATION');
  }
  return null;
}
