import 'package:blockchain_utils_old/blockchain_utils.dart';

class Outpoint {
  Outpoint({required this.txid, required this.index, this.value});

  String txid;
  int index;
  int? value;

  factory Outpoint.fromBytes(List<int> txid, int index, {int? value}) {
    return Outpoint(txid: BytesUtils.toHexString(txid), index: index, value: value);
  }

  @override
  String toString() {
    return 'Outpoint{txid: $txid, index: $index, value: $value}';
  }
}
