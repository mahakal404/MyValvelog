class HeartValveEntry {
  final int? id;
  final String model;
  final String serialNo;
  final String batchNo;
  final String jobCardNo;
  final String size;
  final int quantity;
  final String status;
  final String sign;
  final String assembly;
  final String section;
  final String? borrowedFromAssembly;
  final DateTime takeTime;
  final DateTime submitTime;
  final DateTime timestamp;

  HeartValveEntry({
    this.id,
    required this.model,
    required this.serialNo,
    required this.batchNo,
    required this.jobCardNo,
    required this.size,
    this.quantity = 1,
    this.status = 'IN PROCESS',
    required this.sign,
    required this.assembly,
    required this.section,
    this.borrowedFromAssembly,
    required this.takeTime,
    required this.submitTime,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model': model,
      'serialNo': serialNo,
      'batchNo': batchNo,
      'jobCardNo': jobCardNo,
      'size': size,
      'quantity': quantity,
      'status': status,
      'sign': sign,
      'assembly': assembly,
      'section': section,
      'borrowedFromAssembly': borrowedFromAssembly,
      'takeTime': takeTime.toIso8601String(),
      'submitTime': submitTime.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HeartValveEntry.fromMap(Map<String, dynamic> map) {
    return HeartValveEntry(
      id: map['id'],
      model: map['model'],
      serialNo: map['serialNo'],
      batchNo: map['batchNo'],
      jobCardNo: map['jobCardNo'] ?? map['cardNoDate'] ?? '',
      size: map['size'],
      quantity: map['quantity'],
      status: map['status'],
      sign: map['sign'],
      assembly: map['assembly'] ?? '',
      section: map['section'] ?? '',
      borrowedFromAssembly: map['borrowedFromAssembly'],
      takeTime: map['takeTime'] != null ? DateTime.parse(map['takeTime']) : DateTime.parse(map['timestamp']),
      submitTime: map['submitTime'] != null ? DateTime.parse(map['submitTime']) : DateTime.parse(map['timestamp']),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
