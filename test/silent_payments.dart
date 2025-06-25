// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bitcoin_base/src/bitcoin/script/outpoint.dart';
import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/silent_payments/silent_payments.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/base.dart';
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

          inputPrivKeyInfos.add(ECPrivateInfo(
            privkey,
            prevoutScript.getAddressType() == SegwitAddresType.p2tr,
            tweak: false,
          ));
          inputPubKeys.add(pubkey);
        }

        if (inputPubKeys.isNotEmpty) {
          List<SilentPaymentDestination> silentPaymentDestinations =
              (given['recipients'] as List<dynamic>)
                  .map((recipient) =>
                      SilentPaymentDestination.fromAddress(recipient[0], recipient[1].floor()))
                  .toList();

          final spb = SilentPaymentBuilder(pubkeys: inputPubKeys, vinOutpoints: vinOutpoints);
          sendingOutputs = spb.createOutputs(inputPrivKeyInfos, silentPaymentDestinations);

          List<dynamic> expectedDestinations = sendingTest['expected']['outputs'];

          for (final destination in silentPaymentDestinations) {
            expect(sendingOutputs[destination.toString()] != null, true);
          }

          final generatedOutputs = sendingOutputs.values.expand((element) => element).toList();
          for (final expected in expectedDestinations) {
            final expectedPubkey = expected[0];
            final generatedPubkey = generatedOutputs.firstWhere((output) =>
                BytesUtils.toHexString(output.address.pubkey!.toCompressedBytes().sublist(1)) ==
                expectedPubkey);

            expect(
                BytesUtils.toHexString(
                    generatedPubkey.address.pubkey!.toCompressedBytes().sublist(1)),
                expectedPubkey);
          }
        }
      }

      final msg = SHA256().update(utf8.encode('message')).digest();
      final aux = SHA256().update(utf8.encode('random auxiliary data')).digest();

      // Test receiving
      for (final receivingTest in testCase['receiving']) {
        List<Outpoint> vinOutpoints = [];
        List<ECPublic> inputPubKeys = [];

        final given = receivingTest["given"];
        final expected = receivingTest['expected'];

        List<String> outputsToCheck =
            (given['outputs'] as List<dynamic>).map((output) => output.toString()).toList();

        final List<SilentPaymentOwner> receivingAddresses = [];

        final silentPaymentOwner = SilentPaymentOwner.fromPrivateKeys(
            b_scan: ECPrivate.fromHex(given["key_material"]["scan_priv_key"]),
            b_spend: ECPrivate.fromHex(given["key_material"]["spend_priv_key"]));

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
                ))),
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
          final spb = SilentPaymentBuilder(pubkeys: inputPubKeys, vinOutpoints: vinOutpoints);

          final addToWallet = spb.scanOutputs(silentPaymentOwner.b_scan, silentPaymentOwner.B_spend,
              outputsToCheck.map((o) => getScriptFromOutput(o, 0)).toList(),
              precomputedLabels: preComputedLabels);

          final expectedDestinations = expected['outputs'];

          // Check that the private key is correct for the found output public key
          for (int i = 0; i < expectedDestinations.length; i++) {
            final output = addToWallet.entries.elementAt(i);
            final pubkey = output.key;
            final expectedPubkey = expectedDestinations[i]["pub_key"];
            expect(pubkey, expectedPubkey);

            final privKeyTweak = output.value.tweak;
            final expectedPrivKeyTweak = expectedDestinations[i]["priv_key_tweak"];
            expect(privKeyTweak, expectedPrivKeyTweak);

            var fullPrivateKey =
                silentPaymentOwner.b_spend.tweakAdd(BigintUtils.parse(privKeyTweak));

            if (fullPrivateKey.toBytes()[0] == 0x03) {
              fullPrivateKey = fullPrivateKey.negate();
            }

            // Sign the message with schnorr
            final btcSigner = BitcoinSigner.fromKeyBytes(fullPrivateKey.toBytes());
            List<int> sig =
                btcSigner.signSchnorrTransaction(msg, tapScripts: [], tweak: false, aux: aux);

            // Verify the message is correct
            expect(btcSigner.verifyKey.verifySchnorr(msg, sig, isTweak: false), true);

            // Verify the signature is correct
            expect(BytesUtils.toHexString(sig), expectedDestinations[i]["signature"]);

            i++;
          }
        }
      }
    });
  }
}
