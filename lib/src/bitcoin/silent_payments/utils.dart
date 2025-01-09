// ignore_for_file: non_constant_identifier_names
part of 'package:bitcoin_base/src/bitcoin/silent_payments/silent_payments.dart';

final NUMS_H = BigInt.parse("0x50929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0");

int deserCompactSize(ByteData f) {
  final view = f.buffer;
  int nbytes = view.lengthInBytes;
  if (nbytes == 0) {
    return 0; // end of stream
  }

  int nit = f.getUint8(0);
  if (nit == 253) {
    nit = f.getUint16(1, Endian.little);
  } else if (nit == 254) {
    nit = f.getUint32(3, Endian.little);
  } else if (nit == 255) {
    nit = f.getUint64(7, Endian.little);
  }
  return nit;
}

ByteData deserString(ByteData f) {
  final nit = deserCompactSize(f);
  int offset = 1;
  return ByteData.sublistView(f.buffer.asUint8List().sublist(offset, nit + offset));
}

List<ByteData> deserStringVector(ByteData f) {
  int offset = 0;

  final nit = deserCompactSize(f);
  offset += 1;

  List<ByteData> result = [];
  for (int i = 0; i < nit; i++) {
    final t = deserString(ByteData.sublistView(f.buffer.asUint8List().sublist(offset)));

    result.add(t);
    offset += t.lengthInBytes + 1;
  }
  return result;
}

class VinInfo {
  final Outpoint outpoint;
  final List<int> scriptSig;
  final TxWitnessInput txinwitness;
  final Script prevOutScript;
  final ECPrivate? privkey;

  VinInfo({
    required this.outpoint,
    required this.scriptSig,
    required this.txinwitness,
    required this.prevOutScript,
    this.privkey,
  });
}

ECPublic? getPubkeyFromInput(VinInfo vin) {
  switch (vin.prevOutScript.getAddressType()) {
    case P2pkhAddressType.p2pkh:
      for (var i = vin.scriptSig.length; i > 0; i--) {
        if (i - 33 >= 0) {
          final pubkeyBytes = vin.scriptSig.sublist(i - 33, i);
          final pubkeyHash = BytesUtils.toHexString(QuickCrypto.hash160(pubkeyBytes));
          if (pubkeyHash ==
              P2pkhAddress.fromScriptPubkey(script: vin.prevOutScript).addressProgram) {
            return ECPublic.fromBytes(pubkeyBytes);
          }
        }
      }
      break;
    case P2shAddressType.p2pkhInP2sh:
      final redeemScript = vin.scriptSig.sublist(1);
      if (Script.fromRaw(bytes: redeemScript).getAddressType() == SegwitAddressType.p2wpkh) {
        return ECPublic.fromBytes(vin.txinwitness.scriptWitness.stack.last.buffer.asUint8List());
      }
      break;
    case SegwitAddressType.p2wpkh:
      return ECPublic.fromBytes(vin.txinwitness.scriptWitness.stack.last.buffer.asUint8List());
    case SegwitAddressType.p2tr:
      final witnessStack = vin.txinwitness.scriptWitness.stack;
      if (witnessStack.isNotEmpty) {
        if (witnessStack.length > 1 && witnessStack.last.buffer.asUint8List()[0] == 0x50) {
          witnessStack.removeLast();
        }

        if (witnessStack.length > 1) {
          final controlBlock = witnessStack.last.buffer.asUint8List();
          final internalKey = controlBlock.sublist(1, 33);
          if (BytesUtils.compareBytes(
                  internalKey, BigintUtils.toBytes(NUMS_H, length: 32, order: Endian.big)) ==
              0) {
            return null;
          }
        }
        return ECPublic.fromBytes(vin.prevOutScript.toBytes().sublist(2));
      }
      break;
    default:
      return null;
  }

  return null;
}

List<int> serUint32(int n) {
  return BigintUtils.toBytes(BigInt.from(n), length: 4);
}
