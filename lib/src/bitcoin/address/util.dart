import 'package:convert/convert.dart';
import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/models/network.dart';

bool validateAddress({required String address, required BasedUtxoNetwork network}) {
  try {
    addressToOutputScript(address: address, network: network);
    return true;
  } catch (_) {
    return false;
  }
}

List<int> addressToOutputScript({required String address, required BasedUtxoNetwork network}) {
  if (P2pkhAddress.regex.hasMatch(address)) {
    return P2pkhAddress.fromAddress(address: address, network: network).toScriptPubKey().toBytes();
  }

  if (P2shAddress.regex.hasMatch(address)) {
    return P2shAddress.fromAddress(address: address, network: network).toScriptPubKey().toBytes();
  }

  if (P2wpkhAddress.regex.hasMatch(address)) {
    return P2wpkhAddress.fromAddress(address: address, network: network).toScriptPubKey().toBytes();
  }

  if (P2wshAddress.regex.hasMatch(address)) {
    return P2wshAddress.fromAddress(address: address, network: network).toScriptPubKey().toBytes();
  }

  if (P2trAddress.regex.hasMatch(address)) {
    return P2trAddress.fromAddress(address: address, network: network).toScriptPubKey().toBytes();
  }

  if (MwebAddress.regex.hasMatch(address)) {
    return hex.decode(MwebAddress.fromAddress(address: address, network: network).addressProgram);
  }

  return P2wpkhAddress.fromAddress(address: address, network: network).toScriptPubKey().toBytes();
}
