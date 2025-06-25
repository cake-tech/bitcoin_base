// ignore_for_file: constant_identifier_names
// ignore_for_file: non_constant_identifier_names
part of 'package:bitcoin_base/src/bitcoin/silent_payments/silent_payments.dart';

const SCAN_PATH = "m/352'/1'/0'/1'/0";

const SPEND_PATH = "m/352'/1'/0'/0'/0";

class SilentPaymentOwner extends SilentPaymentAddress {
  final ECPrivate b_scan;
  final ECPrivate b_spend;

  SilentPaymentOwner({
    required super.version,
    required super.B_scan,
    required super.B_spend,
    required this.b_scan,
    required this.b_spend,
    super.network,
  }) : super();

  factory SilentPaymentOwner.fromPrivateKeys({
    required ECPrivate b_scan,
    required ECPrivate b_spend,
    required BasedUtxoNetwork network,
    int? version,
  }) {
    return SilentPaymentOwner(
      b_scan: b_scan,
      b_spend: b_spend,
      B_scan: b_scan.getPublic(),
      B_spend: b_spend.getPublic(),
      network: network,
      version: version ?? 0,
    );
  }

  factory SilentPaymentOwner.fromHd(Bip32Slip10Secp256k1 bip32, {String? hrp, int? version}) {
    final scanDerivation = bip32.derivePath(SCAN_PATH);
    final spendDerivation = bip32.derivePath(SPEND_PATH);

    return SilentPaymentOwner(
      b_scan: ECPrivate(scanDerivation.privateKey),
      b_spend: ECPrivate(spendDerivation.privateKey),
      B_scan: ECPublic.fromBip32(scanDerivation.publicKey),
      B_spend: ECPublic.fromBip32(spendDerivation.publicKey),
      network: hrp == "tsp" ? BitcoinNetwork.testnet : BitcoinNetwork.mainnet,
      version: version ?? 0,
    );
  }

  factory SilentPaymentOwner.fromMnemonic(String mnemonic, {String? hrp, int? version}) {
    return SilentPaymentOwner.fromHd(
        Bip32Slip10Secp256k1.fromSeed(
          Bip39MnemonicDecoder().decode(mnemonic),
          hrp == "tsp" ? Bip32Const.testNetKeyNetVersions : Bip32Const.mainNetKeyNetVersions,
        ),
        hrp: hrp,
        version: version);
  }

  List<int> generateLabel(int m) {
    return taggedHash(BytesUtils.concatBytes([b_scan.toBytes(), serUint32(m)]), "BIP0352/Label");
  }

  SilentPaymentOwner toLabeledSilentPaymentAddress(int m) {
    final B_m = B_spend.tweakAdd(BigintUtils.fromBytes(generateLabel(m)));
    return SilentPaymentOwner(
      b_scan: b_scan,
      b_spend: b_spend,
      B_scan: B_scan,
      B_spend: B_m,
      network: network,
      version: version,
    );
  }
}

class SilentPaymentDestination extends SilentPaymentAddress {
  SilentPaymentDestination({
    required super.version,
    required ECPublic scanPubkey,
    required ECPublic spendPubkey,
    super.network,
    required this.amount,
  }) : super(B_scan: scanPubkey, B_spend: spendPubkey);

  int amount;

  factory SilentPaymentDestination.fromAddress(String address, int amount) {
    final receiver = SilentPaymentAddress.fromAddress(address);

    return SilentPaymentDestination(
      scanPubkey: receiver.B_scan,
      spendPubkey: receiver.B_spend,
      network: receiver.network,
      version: receiver.version,
      amount: amount,
    );
  }
}

class SilentPaymentAddress implements BitcoinBaseAddress {
  static RegExp get regex => RegExp(r'(tsp|sp|sprt)1[0-9a-zA-Z]{113}');

  final int version;
  final ECPublic B_scan;
  final ECPublic B_spend;
  BasedUtxoNetwork? network;
  final String hrp;

  SilentPaymentAddress({
    required this.B_scan,
    required this.B_spend,
    this.network = BitcoinNetwork.mainnet,
    this.version = 0,
  }) : hrp = (network == BitcoinNetwork.testnet ? "tsp" : "sp") {
    if (version != 0) {
      throw Exception("Can't have other version than 0 for now");
    }
  }

  factory SilentPaymentAddress.fromAddress(String address) {
    final decoded = Bech32DecoderBase.decodeBech32(
      address,
      SegwitBech32Const.separator,
      SegwitBech32Const.checksumStrLen,
      (hrp, data) => Bech32Utils.verifyChecksum(hrp, data, Bech32Encodings.bech32m),
    );
    final prefix = decoded.item1;
    final words = decoded.item2;

    if (prefix != 'sp' && prefix != 'sprt' && prefix != 'tsp') {
      throw Exception('Invalid prefix: $prefix');
    }

    final version = words[0];
    if (version != 0) throw ArgumentError('Invalid version');

    final key = Bech32BaseUtils.convertFromBase32(words.sublist(1));

    return SilentPaymentAddress(
      B_scan: ECPublic.fromBytes(key.sublist(0, 33)),
      B_spend: ECPublic.fromBytes(key.sublist(33)),
      network: prefix == 'tsp' ? BitcoinNetwork.testnet : BitcoinNetwork.mainnet,
      version: version,
    );
  }

  @override
  String toAddress([BasedUtxoNetwork? network]) {
    return toString(network: network);
  }

  @override
  String toString({BasedUtxoNetwork? network}) {
    return Bech32EncoderBase.encodeBech32(
      hrp,
      [
        version,
        ...Bech32BaseUtils.convertToBase32(
            [...B_scan.toCompressedBytes(), ...B_spend.toCompressedBytes()])
      ],
      SegwitBech32Const.separator,
      (hrp, data) => Bech32Utils.computeChecksum(hrp, data, Bech32Encodings.bech32m),
    );
  }

  @override
  BitcoinAddressType get type => SilentPaymentsAddresType.p2sp;

  @override
  Script toScriptPubKey() {
    throw UnimplementedError();
  }

  @override
  String pubKeyHash() {
    throw UnimplementedError();
  }

  @override
  String get addressProgram => "";
}

class Bech32U5 {
  final int value;

  Bech32U5(this.value) {
    if (value < 0 || value > 31) {
      throw Exception('Value is outside the valid range.');
    }
  }

  static Bech32U5 tryFromInt(int value) {
    if (value < 0 || value > 31) {
      throw Exception('Value is outside the valid range.');
    }
    return Bech32U5(value);
  }
}
