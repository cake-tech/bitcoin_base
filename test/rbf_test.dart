import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

// Testnet keys reused from the existing suite.
final _nativeKey = ECPrivate.fromWif(
    'cRvyLwCPLU88jsyj94L7iJjQX5C2f8koG4G2gevN4BeSGcEvfKe9',
    netVersion: BitcoinNetwork.testnet.wifNetVer);
final _wrappedKey = ECPrivate.fromWif(
    'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
    netVersion: BitcoinNetwork.testnet.wifNetVer);

const _prevTxHash = '7db363d5a7fabb64ccce154e906588f1936f34481223ea8c1f2c935b0a0c945b';

UtxoWithAddress _nativeUtxo(int vout, BigInt value) {
  final pub = _nativeKey.getPublic();
  final address = pub.toP2wpkhAddress();
  return UtxoWithAddress(
    utxo: BitcoinUtxo(
      txHash: _prevTxHash,
      value: value,
      vout: vout,
      scriptType: SegwitAddresType.p2wpkh,
    ),
    ownerDetails: UtxoAddressDetails(publicKey: pub.toHex(), address: address),
  );
}

UtxoWithAddress _wrappedUtxo(int vout, BigInt value) {
  final pub = _wrappedKey.getPublic();
  final address = pub.toP2wpkhInP2sh();
  return UtxoWithAddress(
    utxo: BitcoinUtxo(
      txHash: _prevTxHash,
      value: value,
      vout: vout,
      scriptType: P2shAddressType.p2wpkhInP2sh,
    ),
    ownerDetails: UtxoAddressDetails(publicKey: pub.toHex(), address: address),
  );
}

BtcTransaction _signedBuild({
  required List<UtxoWithAddress> utxos,
  required BigInt sendValue,
  required BigInt fee,
  bool enableRBF = true,
}) {
  final destination = _nativeKey.getPublic().toP2wpkhAddress();
  final builder = BitcoinTransactionBuilder(
    outputs: [BitcoinOutput(address: destination, value: sendValue)],
    fee: fee,
    network: BitcoinNetwork.testnet,
    utxos: utxos,
    enableRBF: enableRBF,
    inputOrdering: BitcoinOrdering.none,
    outputOrdering: BitcoinOrdering.none,
  );
  return builder.buildTransaction((digest, utxo, publicKey, sighash) {
    if (publicKey == _nativeKey.getPublic().toHex()) {
      return _nativeKey.signInput(digest, sigHash: sighash);
    }
    if (publicKey == _wrappedKey.getPublic().toHex()) {
      return _wrappedKey.signInput(digest, sigHash: sighash);
    }
    throw StateError('no key for $publicKey');
  });
}

void main() {
  group('RBF sequence constant', () {
    test('uses BIP125 0xfffffffd, not the 1-block timelock value 0x01', () {
      expect(BitcoinOpCodeConst.REPLACE_BY_FEE_SEQUENCE, [0xfd, 0xff, 0xff, 0xff]);
    });

    test('Sequence helper emits the same RBF value as the constant', () {
      final seq = Sequence(seqType: BitcoinOpCodeConst.TYPE_REPLACE_BY_FEE, value: 0);
      expect(seq.forInputSequence(), BitcoinOpCodeConst.REPLACE_BY_FEE_SEQUENCE);
    });
  });

  group('BIP125 opt-in detection (sequenceSignalsRbf)', () {
    test('signals for 0x01 (sequences from transactions sent before the fix)', () {
      expect(BtcTransaction.sequenceSignalsRbf([0x01, 0x00, 0x00, 0x00]), isTrue);
    });

    test('signals for 0xfffffffd (PSBT / hardware wallet sends)', () {
      expect(BtcTransaction.sequenceSignalsRbf([0xfd, 0xff, 0xff, 0xff]), isTrue);
    });

    test('signals for 0x00000000', () {
      expect(BtcTransaction.sequenceSignalsRbf([0x00, 0x00, 0x00, 0x00]), isTrue);
    });

    test('does not signal for 0xfffffffe (locktime only, no RBF)', () {
      expect(BtcTransaction.sequenceSignalsRbf([0xfe, 0xff, 0xff, 0xff]), isFalse);
    });

    test('does not signal for 0xffffffff (final)', () {
      expect(BtcTransaction.sequenceSignalsRbf([0xff, 0xff, 0xff, 0xff]), isFalse);
    });

    test('rejects malformed sequences instead of reading past them', () {
      expect(BtcTransaction.sequenceSignalsRbf([0x01, 0x00]), isFalse);
      expect(BtcTransaction.sequenceSignalsRbf(const []), isFalse);
    });
  });

  group('canReplaceByFee after parsing a raw transaction', () {
    BtcTransaction unsignedWithSequences(List<List<int>> sequences) {
      return BtcTransaction(
        inputs: [
          for (var i = 0; i < sequences.length; i++)
            TxInput(txId: _prevTxHash, txIndex: i, sequence: sequences[i]),
        ],
        outputs: [
          TxOutput(
            amount: BigInt.from(50000),
            scriptPubKey: _nativeKey.getPublic().toP2wpkhAddress().toScriptPubKey(),
          ),
        ],
      );
    }

    test('detects a legacy 0x01 input', () {
      final raw = unsignedWithSequences([
        [0x01, 0x00, 0x00, 0x00]
      ]).serialize();
      expect(BtcTransaction.fromRaw(raw).canReplaceByFee, isTrue);
    });

    test('detects a PSBT-style 0xfffffffd input', () {
      final raw = unsignedWithSequences([
        [0xfd, 0xff, 0xff, 0xff]
      ]).serialize();
      expect(BtcTransaction.fromRaw(raw).canReplaceByFee, isTrue);
    });

    test('detects RBF when only one of several inputs signals', () {
      final raw = unsignedWithSequences([
        [0xff, 0xff, 0xff, 0xff],
        [0xfd, 0xff, 0xff, 0xff],
      ]).serialize();
      expect(BtcTransaction.fromRaw(raw).canReplaceByFee, isTrue);
    });

    test('does not flag a transaction where no input signals', () {
      final raw = unsignedWithSequences([
        [0xff, 0xff, 0xff, 0xff],
        [0xfe, 0xff, 0xff, 0xff],
      ]).serialize();
      expect(BtcTransaction.fromRaw(raw).canReplaceByFee, isFalse);
    });
  });

  group('signed builds', () {
    test('enableRBF sets 0xfffffffd on the signed input and is detected after parsing', () {
      final tx = _signedBuild(
        utxos: [_nativeUtxo(0, BigInt.from(100000))],
        sendValue: BigInt.from(99000),
        fee: BigInt.from(1000),
      );
      expect(tx.inputs.first.sequence, [0xfd, 0xff, 0xff, 0xff]);
      expect(BtcTransaction.fromRaw(tx.serialize()).canReplaceByFee, isTrue);
    });

    test('without enableRBF the input is final and not replaceable', () {
      final tx = _signedBuild(
        utxos: [_nativeUtxo(0, BigInt.from(100000))],
        sendValue: BigInt.from(99000),
        fee: BigInt.from(1000),
        enableRBF: false,
      );
      expect(BtcTransaction.fromRaw(tx.serialize()).canReplaceByFee, isFalse);
    });
  });

  group('witness parsing (BIP144)', () {
    test('round-trips a native P2WPKH input', () {
      final tx = _signedBuild(
        utxos: [_nativeUtxo(0, BigInt.from(100000))],
        sendValue: BigInt.from(99000),
        fee: BigInt.from(1000),
      );
      final raw = tx.serialize();
      final parsed = BtcTransaction.fromRaw(raw);
      expect(parsed.witnesses.length, 1);
      expect(parsed.serialize(), raw);
    });

    test('keeps each input aligned with its own witness when a P2SH-P2WPKH input is present', () {
      // The old parser skipped witnesses for inputs with a non-empty scriptSig, which
      // is exactly what P2SH-wrapped segwit inputs have. That shifted every later witness.
      final tx = _signedBuild(
        utxos: [
          _wrappedUtxo(0, BigInt.from(60000)),
          _nativeUtxo(1, BigInt.from(60000)),
        ],
        sendValue: BigInt.from(119000),
        fee: BigInt.from(1000),
      );
      final raw = tx.serialize();
      final parsed = BtcTransaction.fromRaw(raw);

      expect(parsed.inputs.length, 2);
      expect(parsed.witnesses.length, 2);
      for (var i = 0; i < 2; i++) {
        expect(parsed.witnesses[i].stack, tx.witnesses[i].stack, reason: 'witness $i');
      }
      expect(parsed.serialize(), raw);
    });

    test('a P2SH-P2WPKH input signed by the wallet keeps its witness after parsing', () {
      final tx = _signedBuild(
        utxos: [_wrappedUtxo(0, BigInt.from(100000))],
        sendValue: BigInt.from(99000),
        fee: BigInt.from(1000),
      );
      final parsed = BtcTransaction.fromRaw(tx.serialize());
      expect(parsed.witnesses.length, 1);
      expect(parsed.witnesses.first.stack.length, 2);
      expect(
        parsed.witnesses.first.stack.last,
        _wrappedKey.getPublic().toHex(),
      );
    });

    test('a legacy P2PKH input next to a native input keeps an empty witness slot', () {
      final legacyPub = _wrappedKey.getPublic();
      final legacyUtxo = UtxoWithAddress(
        utxo: BitcoinUtxo(
          txHash: _prevTxHash,
          value: BigInt.from(60000),
          vout: 0,
          scriptType: P2pkhAddressType.p2pkh,
        ),
        ownerDetails: UtxoAddressDetails(
          publicKey: legacyPub.toHex(),
          address: legacyPub.toP2pkhAddress(),
        ),
      );
      final tx = _signedBuild(
        utxos: [legacyUtxo, _nativeUtxo(1, BigInt.from(60000))],
        sendValue: BigInt.from(119000),
        fee: BigInt.from(1000),
      );
      final parsed = BtcTransaction.fromRaw(tx.serialize());
      expect(parsed.hasSegwit, isTrue);
      expect(parsed.witnesses.length, parsed.inputs.length);
      expect(parsed.witnesses.first.stack, isEmpty);
      expect(parsed.witnesses.last.stack.length, 2);
    });
  });
}
