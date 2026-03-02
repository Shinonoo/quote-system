class QuotationModel {
  final int id;
  final String referenceNo;
  final String companyName;
  final String projectName;
  final DateTime createdAt;

  QuotationModel({
    required this.id,
    required this.referenceNo,
    required this.companyName,
    required this.projectName,
    required this.createdAt,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id'],
      referenceNo: json['reference_no'],
      companyName: json['company_name'],
      projectName: json['customer_project'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
