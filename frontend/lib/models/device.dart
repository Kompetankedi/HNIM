class Device {
  final int id;
  final String name;
  final String? ip;
  final String? category;
  final String? serialNumber;
  final String? details;
  final String status;
  final DateTime? lastSeen;
  final DateTime createdAt;

  Device({
    required this.id,
    required this.name,
    this.ip,
    this.category,
    this.serialNumber,
    this.details,
    required this.status,
    this.lastSeen,
    required this.createdAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['ID'],
      name: json['Name'],
      ip: json['IP'],
      category: json['Category'],
      serialNumber: json['SerialNumber'],
      details: json['Details'],
      status: json['Status'] ?? 'unknown',
      lastSeen: json['LastSeen'] != null ? DateTime.parse(json['LastSeen']) : null,
      createdAt: json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Name': name,
      'IP': ip,
      'Category': category,
      'SerialNumber': serialNumber,
      'Details': details,
      'Status': status,
      'LastSeen': lastSeen?.toIso8601String(),
      'CreatedAt': createdAt.toIso8601String(),
    };
  }
}
