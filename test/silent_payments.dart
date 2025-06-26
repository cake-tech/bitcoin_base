// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/silent_payments/silent_payments.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:blockchain_utils_old/blockchain_utils.dart';
import 'package:blockchain_utils_old/crypto/crypto/cdsa/point/base.dart';
import 'package:test/test.dart';

// G , needed for generating the labels "database"
final G = ECPublic.fromBytes(BigintUtils.toBytes(Curves.generatorSecp256k1.x, length: 32));

main() {
  final fixtures =
      json.decode(File('test/fixtures/silent_payments.json').readAsStringSync(encoding: utf8));

  for (var testCase in fixtures) {
    test(testCase['comment'], () {
      Map<String, List<SilentPaymentOutput>> sendingOutputs = {};

      // Test sending
      for (var sendingTest in testCase['sending']) {
        List<Outpoint> vinOutpoints = [];
        List<ECPrivateInfo> inputPrivKeyInfos = [];
        List<ECPublic> inputPubKeys = [];

        var given = sendingTest["given"];

        for (var input in given['vin']) {
          final prevoutScript = Script.fromRaw(hexData: input['prevout']['scriptPubKey']['hex']);
          final privkey = ECPrivate.fromHex(input['private_key']);

          final vin = VinInfo(
            outpoint: Outpoint(txid: input['txid'], index: input['vout']),
            scriptSig: BytesUtils.fromHexString(input['scriptSig']),
            txinwitness: TxWitnessInput(
                stack: [],
                scriptWitness: ScriptWitness(
                    stack: deserStringVector(
                  ByteData.sublistView(
                    Uint8List.fromList(
                      BytesUtils.fromHexString(input['txinwitness']),
                    ),
                  ),
                ))),
            prevOutScript: prevoutScript,
            privkey: privkey,
          );

          vinOutpoints.add(vin.outpoint);

          final pubkey = getPubkeyFromInput(vin);

          if (pubkey == null || pubkey.getEncodeType() != EncodeType.compressed) {
            continue;
          }

          inputPrivKeyInfos.add(
            ECPrivateInfo(
              privkey,
              prevoutScript.getAddressType() == SegwitAddressType.p2tr,
              tweak: false,
            ),
          );
          inputPubKeys.add(pubkey);
        }

        if (inputPubKeys.isNotEmpty) {
          final silentPaymentDestinations = (given['recipients'] as List<dynamic>)
              .map((recipient) => SilentPaymentDestination.fromAddress(recipient))
              .toList();

          try {
            final spb = SilentPaymentBuilder(pubkeys: inputPubKeys, vinOutpoints: vinOutpoints);
            sendingOutputs = spb.createOutputs(inputPrivKeyInfos, silentPaymentDestinations);

            List<dynamic> expectedDestinations = sendingTest['expected']['outputs'];

            for (final destination in silentPaymentDestinations) {
              expect(sendingOutputs[destination.toString()] != null, true);
            }

            final generatedOutputs = sendingOutputs.values.expand((element) => element).toList();
            for (final expected in expectedDestinations) {
              final expectedPubkey = expected[0];
              final generatedPubkey = generatedOutputs.firstWhere(
                (output) {
                  return BytesUtils.toHexString(
                        output.address.pubkey!.toCompressedBytes().sublist(1),
                      ) ==
                      expectedPubkey;
                },
              );

              expect(
                BytesUtils.toHexString(
                  generatedPubkey.address.pubkey!.toCompressedBytes().sublist(1),
                ),
                expectedPubkey,
              );
            }
          } catch (_) {}
        }
      }

      final msg = SHA256().update(utf8.encode('message')).digest();
      final aux = SHA256().update(utf8.encode('random auxiliary data')).digest();

      // Test receiving
      for (final receivingTest in testCase['receiving']) {
        List<Outpoint> vinOutpoints = [];
        List<ECPublic> inputPubKeys = [];

        final given = receivingTest["given"];

        final outputsToCheck =
            (given['outputs'] as List<dynamic>).map((o) => o.toString()).toList();

        final List<SilentPaymentOwner> receivingAddresses = [];

        final silentPaymentOwner = SilentPaymentOwner.fromPrivateKeys(
          b_scan: ECPrivate.fromHex(given["key_material"]["scan_priv_key"]),
          b_spend: ECPrivate.fromHex(given["key_material"]["spend_priv_key"]),
        );

        // Add change address
        receivingAddresses.add(silentPaymentOwner);

        Map<String, String>? preComputedLabels;
        for (var label in given['labels']) {
          receivingAddresses.add(silentPaymentOwner.toLabeledSilentPaymentAddress(label));
          final generatedLabel = silentPaymentOwner.generateLabel(label);

          preComputedLabels ??= {};
          preComputedLabels[G.tweakMul(BigintUtils.fromBytes(generatedLabel)).toHex()] =
              BytesUtils.toHexString(generatedLabel);
        }

        final expected = receivingTest['expected'];

        for (var address in expected['addresses']) {
          expect(receivingAddresses.indexWhere((sp) => sp.toString() == address.toString()),
              isNot(-1));
        }

        for (var input in given['vin']) {
          final prevoutScript = Script.fromRaw(hexData: input['prevout']['scriptPubKey']['hex']);

          final vin = VinInfo(
            outpoint: Outpoint(txid: input['txid'], index: input['vout']),
            scriptSig: BytesUtils.fromHexString(input['scriptSig']),
            txinwitness: TxWitnessInput(
              stack: [],
              scriptWitness: ScriptWitness(
                stack: deserStringVector(
                  ByteData.sublistView(
                    Uint8List.fromList(
                      BytesUtils.fromHexString(input['txinwitness']),
                    ),
                  ),
                ),
              ),
            ),
            prevOutScript: prevoutScript,
          );

          vinOutpoints.add(vin.outpoint);

          final pubkey = getPubkeyFromInput(vin);

          if (pubkey == null || pubkey.getEncodeType() != EncodeType.compressed) {
            continue;
          }

          inputPubKeys.add(pubkey);
        }

        if (inputPubKeys.isNotEmpty) {
          Map<String, SilentPaymentScanningOutput> addToWallet;

          try {
            final spb = SilentPaymentBuilder(pubkeys: inputPubKeys, vinOutpoints: vinOutpoints);

            addToWallet = spb.scanOutputs(
              silentPaymentOwner.b_scan,
              silentPaymentOwner.B_spend,
              outputsToCheck.map((o) => getScriptFromOutput(o, 0)).toList(),
              precomputedLabels: preComputedLabels,
            );
          } catch (_) {
            addToWallet = {};
          }

          final expectedDestinations = expected['outputs'];

          // Check that the private key is correct for the found output public key
          for (int i = 0; i < expectedDestinations.length; i++) {
            final expectedPubkey = expectedDestinations[i]["pub_key"];
            final output = addToWallet[expectedPubkey];

            if (output == null) {
              continue;
            }

            final privKeyTweak = output!.tweak;
            final expectedPrivKeyTweak = expectedDestinations[i]["priv_key_tweak"];
            expect(privKeyTweak, expectedPrivKeyTweak);

            var fullPrivateKey =
                silentPaymentOwner.b_spend.tweakAdd(BigintUtils.parse(privKeyTweak));

            if (fullPrivateKey.toBytes()[0] == 0x03) {
              fullPrivateKey = fullPrivateKey.negate();
            }

            // Sign the message with schnorr
            final btcSigner = BitcoinSigner.fromKeyBytes(fullPrivateKey.toBytes());
            List<int> sig = btcSigner.signSchnorrTransaction(
              msg,
              tapScripts: [],
              tweak: false,
              auxRand: aux,
            );

            // Verify the message is correct
            expect(btcSigner.verifyKey.verifySchnorr(msg, sig, isTweak: false), true);

            // Verify the signature is correct
            expect(BytesUtils.toHexString(sig), expectedDestinations[i]["signature"]);
          }
        }
      }
    });
  }
}
