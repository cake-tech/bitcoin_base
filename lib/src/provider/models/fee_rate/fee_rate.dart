import 'package:bitcoin_base/src/exception/exception.dart';

enum BitcoinFeeRateType { low, medium, high }

class BitcoinFee {
  BitcoinFee({int? satoshis, BigInt? bytes})
      : satoshis = satoshis ?? _parseKbFees(bytes!),
        bytes = bytes ?? _parseMempoolFees(satoshis!);

  final int satoshis;
  final BigInt bytes;

  @override
  String toString() {
    return 'satoshis: $satoshis, bytes: $bytes';
  }
}

class BitcoinFeeRate {
  BitcoinFeeRate({
    required this.high,
    required this.medium,
    required this.low,
    this.economyFee,
    this.minimumFee,
  });

  /// High fee rate in satoshis per kilobyte
  final BitcoinFee high;

  /// Medium fee rate in satoshis per kilobyte
  final BitcoinFee medium;

  /// low fee rate in satoshis per kilobyte
  final BitcoinFee low;

  /// only mnenpool api
  final BitcoinFee? economyFee;

  /// only mnenpool api
  final BitcoinFee? minimumFee;

  BitcoinFee _feeRate(BitcoinFeeRateType feeRateType) {
    switch (feeRateType) {
      case BitcoinFeeRateType.low:
        return low;
      case BitcoinFeeRateType.medium:
        return medium;
      default:
        return high;
    }
  }

  int toSat(BigInt feeRate) {
    return _parseKbFees(feeRate);
  }

  /// GetEstimate calculates the estimated fee in satoshis for a given transaction size
  /// and fee rate (in satoshis per kilobyte) using the formula:
  //
  /// EstimatedFee = (TransactionSize * FeeRate) / 1024
  //
  /// Parameters:
  /// - trSize: An integer representing the transaction size in bytes.
  /// - feeRate: A BigInt representing the fee rate in satoshis per kilobyte.
  //
  /// Returns:
  /// - BigInt: A BigInt containing the estimated fee in satoshis.
  BigInt getEstimate(int trSize,
      {BigInt? customFeeRatePerKb, BitcoinFeeRateType feeRateType = BitcoinFeeRateType.medium}) {
    BigInt feeRate = customFeeRatePerKb ?? _feeRate(feeRateType).bytes;
    final trSizeBigInt = BigInt.from(trSize);
    return (trSizeBigInt * feeRate) ~/ BigInt.from(1000);
  }

  @override
  String toString() {
    return 'high: ${high.toString()} medium: ${medium.toString()} low: ${low.toString()}, economyFee: $economyFee minimumFee: $minimumFee';
  }

  /// NewBitcoinFeeRateFromMempool creates a BitcoinFeeRate structure from JSON data retrieved
  /// from a mempool API response. The function parses the JSON map and extracts fee rate
  /// information for high, medium, and low fee levels.
  factory BitcoinFeeRate.fromMempool(Map<String, dynamic> json) {
    return BitcoinFeeRate(
      high: BitcoinFee(satoshis: json['fastestFee']),
      medium: BitcoinFee(satoshis: json['halfHourFee']),
      low: BitcoinFee(satoshis: json['hourFee']),
      economyFee: json['economyFee'] == null ? null : BitcoinFee(satoshis: json['economyFee']),
      minimumFee: json['minimumFee'] == null ? null : BitcoinFee(satoshis: json['minimumFee']),
    );
  }

  /// NewBitcoinFeeRateFromBlockCypher creates a BitcoinFeeRate structure from JSON data retrieved
  /// from a BlockCypher API response. The function parses the JSON map and extracts fee rate
  /// information for high, medium, and low fee levels.
  factory BitcoinFeeRate.fromBlockCypher(Map<String, dynamic> json) {
    return BitcoinFeeRate(
      high: BitcoinFee(bytes: BigInt.from((json['high_fee_per_kb'] as int))),
      medium: BitcoinFee(bytes: BigInt.from((json['medium_fee_per_kb'] as int))),
      low: BitcoinFee(bytes: BigInt.from((json['low_fee_per_kb'] as int))),
    );
  }
}

/// ParseMempoolFees takes a data dynamic and converts it to a BigInt representing
/// mempool fees in satoshis per kilobyte (sat/KB). The function performs the conversion
/// based on the type of the input data, which can be either a double (floating-point
/// fee rate) or an int (integer fee rate in satoshis per byte).
BigInt _parseMempoolFees(dynamic data) {
  const kb = 1024;

  if (data is double) {
    return BigInt.from((data * kb).toInt());
  } else if (data is int) {
    return BigInt.from((data * kb));
  } else {
    throw BitcoinBasePluginException(
        "cannot parse mempool fees excepted double, string got ${data.runtimeType}");
  }
}

/// ParseMempoolFees takes a data dynamic and converts it to a BigInt representing
/// mempool fees in satoshis per kilobyte (sat/KB). The function performs the conversion
/// based on the type of the input data, which can be either a double (floating-point
/// fee rate) or an int (integer fee rate in satoshis per byte).
int _parseKbFees(BigInt fee) {
  const kb = 1024;
  return (fee.toInt() / kb).round();
}
