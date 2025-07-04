import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/provider/models/utxo_details.dart';

typedef BitcoinSignerCallBack = String Function(
    List<int> trDigest, UtxoWithAddress utxo, String publicKey, int sighash);
typedef BitcoinSignerCallBackAsync = Future<String> Function(
    List<int> trDigest, UtxoWithAddress utxo, String publicKey, int sighash);

abstract class BasedBitcoinTransacationBuilder {
  BtcTransaction buildTransaction(BitcoinSignerCallBack sign);
  Future<BtcTransaction> buildTransactionAsync(BitcoinSignerCallBackAsync sign);

  /// how many signature we need for each publicKey (utxo)
  Map<String, int> getSignatureCount();
}

enum BitcoinOrdering { bip69, shuffle, none }
