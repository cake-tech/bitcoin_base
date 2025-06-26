// ignore_for_file: non_constant_identifier_names
part of 'package:bitcoin_base_old/src/bitcoin/silent_payments/silent_payments.dart';

class SilentPaymentOutput {
  final P2trAddress address;
  final int amount;

  SilentPaymentOutput(this.address, this.amount);
}

class SilentPaymentScanningOutput {
  final SilentPaymentOutput output;
  final String tweak;
  final String? label;

  SilentPaymentScanningOutput({required this.output, required this.tweak, this.label});
}

class ECPrivateInfo {
  final ECPrivate privkey;
  final bool isTaproot;
  final bool tweak;

  ECPrivateInfo(this.privkey, this.isTaproot, {this.tweak = false});
}

class SilentPaymentBuilder {
  final List<Outpoint> vinOutpoints;
  final List<ECPublic>? pubkeys;
  ECPublic? A_sum;
  List<int>? inputHash;
  String? receiverTweak;

  SilentPaymentBuilder({
    required this.vinOutpoints,
    this.pubkeys,
    this.receiverTweak,
  }) {
    if (receiverTweak == null && pubkeys != null) {
      _getAsum();
      _getInputHash();
    }
  }

  void _getAsum() {
    final head = pubkeys!.first;
    final tail = pubkeys!.sublist(1);

    A_sum =
        tail.fold<ECPublic>(head, (acc, item) => ECPublic.fromBip32(acc.publicKey).pubkeyAdd(item));
  }

  void _getInputHash() {
    final sortedOutpoints = <List<int>>[];

    for (final outpoint in vinOutpoints) {
      sortedOutpoints.add(BytesUtils.concatBytes([
        BytesUtils.fromHexString(outpoint.txid).reversed.toList(),
        BigintUtils.toBytes(BigInt.from(outpoint.index), length: 4, order: Endian.little)
      ]));
    }

    sortedOutpoints.sort(BytesUtils.compareBytes);
    final lowestOutpoint = sortedOutpoints.first;

    inputHash = taggedHash(
        BytesUtils.concatBytes([lowestOutpoint, A_sum!.toCompressedBytes()]), "BIP0352/Inputs");
  }

  Map<String, List<SilentPaymentOutput>> createOutputs(
    List<ECPrivateInfo> inputPrivKeyInfos,
    List<SilentPaymentDestination> silentPaymentDestinations,
  ) {
    ECPrivate? a_sum;

    for (final info in inputPrivKeyInfos) {
      var k = info.privkey;
      final isTaproot = info.isTaproot;

      if (isTaproot) {
        if (info.tweak) {
          k = k.toTweakedTaprootKey();
        }

        final xOnlyPubkey = k.getPublic();
        final isOdd = xOnlyPubkey.publicKey.point.y % BigInt.two != BigInt.zero;

        if (isOdd) {
          k = k.negate();
        }
      }

      if (a_sum == null) {
        a_sum = k;
      } else {
        a_sum = a_sum.tweakAdd(BigintUtils.fromBytes(k.toBytes()));
      }
    }

    A_sum = a_sum!.getPublic();
    _getInputHash();

    Map<String, Map<String, List<SilentPaymentDestination>>> silentPaymentGroups = {};

    for (final silentPaymentDestination in silentPaymentDestinations) {
      final B_scan = silentPaymentDestination.B_scan;
      final scanPubkey = B_scan.toHex();

      if (silentPaymentGroups.containsKey(scanPubkey)) {
        // Current key already in silentPaymentGroups, simply add up the new destination
        // with the already calculated ecdhSharedSecret
        final group = silentPaymentGroups[scanPubkey]!;
        final ecdhSharedSecret = group.keys.first;
        final recipients = group.values.first;

        silentPaymentGroups[scanPubkey] = {
          ecdhSharedSecret: [...recipients, silentPaymentDestination]
        };
      } else {
        final senderPartialSecret = a_sum.tweakMul(BigintUtils.fromBytes(inputHash!)).toBytes();
        final ecdhSharedSecret =
            B_scan.tweakMul(BigintUtils.fromBytes(senderPartialSecret)).toHex();

        silentPaymentGroups[scanPubkey] = {
          ecdhSharedSecret: [silentPaymentDestination]
        };
      }
    }

    Map<String, List<SilentPaymentOutput>> result = {};
    for (final group in silentPaymentGroups.entries) {
      final ecdhSharedSecret = group.value.keys.first;
      final destinations = group.value.values.first;

      int k = 0;
      for (final destination in destinations) {
        final t_k = taggedHash(
            BytesUtils.concatBytes([
              ECPublic.fromHex(ecdhSharedSecret).toCompressedBytes(),
              BigintUtils.toBytes(BigInt.from(k), length: 4)
            ]),
            "BIP0352/SharedSecret");

        final P_mn = destination.B_spend.tweakAdd(BigintUtils.fromBytes(t_k));
        final resOutput =
            SilentPaymentOutput(P_mn.toTaprootAddress(tweak: false), destination.amount);

        if (result.containsKey(destination.toString())) {
          result[destination.toString()]!.add(resOutput);
        } else {
          result[destination.toString()] = [resOutput];
        }

        k++;
      }
    }

    return result;
  }

  Map<String, SilentPaymentScanningOutput> scanOutputs(
    ECPrivate b_scan,
    ECPublic B_spend,
    List<BitcoinScriptOutput> outputsToCheck, {
    Map<String, String>? precomputedLabels,
  }) {
    final tweakDataForRecipient = receiverTweak != null
        ? ECPublic.fromHex(receiverTweak!)
        : A_sum!.tweakMul(BigintUtils.fromBytes(inputHash!));
    final ecdhSharedSecret = tweakDataForRecipient.tweakMul(b_scan.toBigInt());

    final matches = <String, SilentPaymentScanningOutput>{};
    var k = 0;

    do {
      final t_k = taggedHash(
          BytesUtils.concatBytes([
            ecdhSharedSecret.toCompressedBytes(),
            BigintUtils.toBytes(BigInt.from(k), length: 4, order: Endian.big)
          ]),
          "BIP0352/SharedSecret");

      final P_k = B_spend.tweakAdd(BigintUtils.fromBytes(t_k));
      final length = outputsToCheck.length;

      for (var i = 0; i < length; i++) {
        final output = outputsToCheck[i].script.toBytes().sublist(2);
        final outputPubkey = BytesUtils.toHexString(output);
        final outputAmount = outputsToCheck[i].value.toInt();

        if ((BytesUtils.compareBytes(output, P_k.toCompressedBytes().sublist(1)) == 0)) {
          matches[outputPubkey] = SilentPaymentScanningOutput(
            output: SilentPaymentOutput(P_k.toTaprootAddress(tweak: false), outputAmount),
            tweak: BytesUtils.toHexString(t_k),
          );
          outputsToCheck.removeAt(i);
          k++;
          break;
        }

        if (precomputedLabels != null && precomputedLabels.isNotEmpty) {
          var m_G_sub = ECPublic.fromBytes(output).pubkeyAdd(P_k.negate());
          var m_G = precomputedLabels[m_G_sub.toHex()];

          if (m_G == null) {
            m_G_sub = ECPublic.fromBytes(output).negate().pubkeyAdd(P_k.negate());
            m_G = precomputedLabels[m_G_sub.toHex()];
          }

          if (m_G != null) {
            final P_km = P_k.tweakAdd(BigintUtils.fromBytes(BytesUtils.fromHexString(m_G)));

            matches[outputPubkey] = SilentPaymentScanningOutput(
              output: SilentPaymentOutput(P_km.toTaprootAddress(tweak: false), outputAmount),
              tweak: ECPrivate.fromBytes(t_k)
                  .tweakAdd(BigintUtils.fromBytes(BytesUtils.fromHexString(m_G)))
                  .toHex(),
              label: m_G,
            );

            outputsToCheck.removeAt(i);
            k++;
            break;
          }
        }

        outputsToCheck.removeAt(i);

        if (i + 1 >= outputsToCheck.length) {
          break;
        }
      }
    } while (outputsToCheck.isNotEmpty);

    return matches;
  }
}

BitcoinScriptOutput getScriptFromOutput(String pubkey, int amount) {
  return BitcoinScriptOutput(
      script: Script(script: [BitcoinOpCodeConst.OP_1, pubkey]), value: BigInt.from(amount));
}
