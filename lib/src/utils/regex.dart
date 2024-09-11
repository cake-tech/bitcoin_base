import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/silent_payments/silent_payments.dart';
import 'package:bitcoin_base/src/models/network.dart';

class RegexUtils {
  static bool stringIsAddress(String string, RegExp addressRegex) {
    return RegExp("^${addressRegex.pattern}\$").hasMatch(string);
  }

  static bool addressInString(String string, RegExp addressRegex) {
    return RegExp("(^|\\s)${addressRegex.pattern}(\$|\\s)").hasMatch(string);
  }

  static BitcoinBaseAddress addressTypeFromStr(String address, BasedUtxoNetwork network) {
    if (network is BitcoinCashNetwork) {
      if (!address.startsWith("bitcoincash:") &&
          (address.startsWith("q") || address.startsWith("p"))) {
        address = "bitcoincash:$address";
      }

      return BitcoinCashAddress(address).baseAddress;
    }

    if (stringIsAddress(address, P2pkhAddress.regex)) {
      return P2pkhAddress.fromAddress(address: address, network: network);
    } else if (stringIsAddress(address, P2shAddress.regex)) {
      return P2shAddress.fromAddress(address: address, network: network);
    } else if (stringIsAddress(address, P2wshAddress.regex)) {
      return P2wshAddress.fromAddress(address: address, network: network);
    } else if (stringIsAddress(address, P2trAddress.regex)) {
      return P2trAddress.fromAddress(address: address, network: network);
    } else if (stringIsAddress(address, SilentPaymentAddress.regex)) {
      return SilentPaymentAddress.fromAddress(address);
    } else if (stringIsAddress(address, MwebAddress.regex)) {
      return MwebAddress.fromAddress(address: address, network: network);
    } else {
      return P2wpkhAddress.fromAddress(address: address, network: network);
    }
  }
}
