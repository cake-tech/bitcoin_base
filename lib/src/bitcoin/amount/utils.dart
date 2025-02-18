part of 'package:bitcoin_base/src/bitcoin/amount/amount.dart';

class BitcoinAmountUtils {
  static const bitcoinAmountLength = 8;
  static const bitcoinAmountDivider = 100000000;
  static final bitcoinAmountFormat = NumberFormat()
    ..maximumFractionDigits = bitcoinAmountLength
    ..minimumFractionDigits = 1;

  static double cryptoAmountToDouble({required num amount, required num divider}) =>
      amount / divider;

  static String bitcoinAmountToString({required int amount}) =>
      bitcoinAmountFormat.format(cryptoAmountToDouble(
        amount: amount,
        divider: bitcoinAmountDivider,
      ));

  static double bitcoinAmountToDouble({required int amount}) =>
      cryptoAmountToDouble(amount: amount, divider: bitcoinAmountDivider);

  static int stringDoubleToBitcoinAmount(String amount) {
    int result = 0;

    try {
      result = (double.parse(amount) * bitcoinAmountDivider).round();
    } catch (e) {
      result = 0;
    }

    return result;
  }
}
