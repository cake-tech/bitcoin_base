// ignore_for_file: constant_identifier_names
// ignore_for_file: non_constant_identifier_names
part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

class BitcoinDerivationInfo {
  BitcoinDerivationInfo({
    required this.derivationType,
    required String derivationPath,
    required this.scriptType,
    this.description,
  }) : derivationPath = Bip32PathParser.parse(derivationPath);
  final BitcoinDerivationType derivationType;
  final Bip32Path derivationPath;
  final BitcoinAddressType scriptType;
  final String? description;

  static BitcoinDerivationInfo fromDerivationAndAddress(
    BitcoinDerivationType derivationType,
    String address,
    BasedUtxoNetwork network,
  ) {
    final derivations = BITCOIN_DERIVATIONS[derivationType]!;
    final scriptType = BitcoinAddressUtils.addressTypeFromStr(address, network);

    return derivations.firstWhere(
      (element) => element.scriptType == scriptType,
      orElse: () => derivations.first,
    );
  }

  factory BitcoinDerivationInfo.fromJSON(Map<String, dynamic> json) {
    return BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.values[json['derivationType']],
      derivationPath: json['derivationPath'],
      scriptType: BitcoinAddressType.values.firstWhere(
        (type) => type.toString() == json['scriptType'],
      ),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'derivationType': derivationType.index,
      'derivationPath': derivationPath.toString(),
      'scriptType': scriptType.toString(),
      'description': description,
    };
  }
}

enum BitcoinDerivationType { bip39, electrum }

// Define constant paths
abstract class BitcoinDerivationPaths {
  static const String ELECTRUM = "m/0'";
  static const String BIP44 = "m/44'/0'/0'";
  static const String BIP49 = "m/49'/0'/0'";
  static const String BIP84 = "m/84'/0'/0'";
  static const String BIP86 = "m/86'/0'/0'";
  static const String NON_STANDARD = "m/0'";

  static const String SILENT_PAYMENTS_SCAN = "m/352'/0'/0'/1'/0";
  static const String SILENT_PAYMENTS_SPEND = "m/352'/0'/0'/0'/0";

  static const String LITECOIN = "m/84'/2'/0'";

  static const String SAMOURAI_BAD_BANK = "m/84'/0'/2147483644'";
  static const String SAMOURAI_WHIRLPOOL_PREMIX = "m/84'/0'/2147483645'";
  static const String SAMOURAI_WHIRLPOOL_POSTMIX = "m/84'/0'/2147483646'";
  static const String SAMOURAI_RICOCHET_LEGACY = "m/44'/0'/2147483647'";
  static const String SAMOURAI_RICOCHET_COMPATIBILITY_SEGWIT = "m/49'/0'/2147483647'";
  static const String SAMOURAI_RICOCHET_NATIVE_SEGWIT = "m/84'/0'/2147483647'";
}

abstract class BitcoinDerivationInfos {
  static final BitcoinDerivationInfo ELECTRUM = BitcoinDerivationInfo(
    derivationType: BitcoinDerivationType.electrum,
    derivationPath: BitcoinDerivationPaths.ELECTRUM,
    description: "Electrum",
    scriptType: SegwitAddressType.p2wpkh,
  );

  static final BitcoinDerivationInfo BIP44 = BitcoinDerivationInfo(
    derivationType: BitcoinDerivationType.bip39,
    derivationPath: BitcoinDerivationPaths.BIP44,
    description: "Standard BIP44",
    scriptType: P2pkhAddressType.p2pkh,
  );
  static final BitcoinDerivationInfo BIP49 = BitcoinDerivationInfo(
    derivationType: BitcoinDerivationType.bip39,
    derivationPath: BitcoinDerivationPaths.BIP49,
    description: "Standard BIP49 compatibility segwit",
    scriptType: P2shAddressType.p2wpkhInP2sh,
  );
  static final BitcoinDerivationInfo BIP84 = BitcoinDerivationInfo(
    derivationType: BitcoinDerivationType.bip39,
    derivationPath: BitcoinDerivationPaths.BIP84,
    description: "Standard BIP84 native segwit",
    scriptType: SegwitAddressType.p2wpkh,
  );
  static final BitcoinDerivationInfo BIP86 = BitcoinDerivationInfo(
    derivationType: BitcoinDerivationType.bip39,
    derivationPath: BitcoinDerivationPaths.BIP86,
    description: "Standard BIP86 Taproot",
    scriptType: SegwitAddressType.p2tr,
  );

  static final BitcoinDerivationInfo LITECOIN = BitcoinDerivationInfo(
    derivationType: BitcoinDerivationType.bip39,
    derivationPath: BitcoinDerivationPaths.LITECOIN,
    description: "Default Litecoin",
    scriptType: SegwitAddressType.p2wpkh,
  );

  static final BitcoinDerivationInfo SILENT_PAYMENTS_SCAN = BitcoinDerivationInfo(
    derivationType: BitcoinDerivationType.bip39,
    derivationPath: BitcoinDerivationPaths.SILENT_PAYMENTS_SCAN,
    description: "Silent Payments Scan",
    scriptType: SilentPaymentsAddresType.p2sp,
  );

  static final BitcoinDerivationInfo SILENT_PAYMENTS_SPEND = BitcoinDerivationInfo(
    derivationType: BitcoinDerivationType.bip39,
    derivationPath: BitcoinDerivationPaths.SILENT_PAYMENTS_SPEND,
    description: "Silent Payments Spend",
    scriptType: SilentPaymentsAddresType.p2sp,
  );
}

final Map<BitcoinDerivationType, List<BitcoinDerivationInfo>> BITCOIN_DERIVATIONS = {
  BitcoinDerivationType.electrum: [BitcoinDerivationInfos.ELECTRUM],
  BitcoinDerivationType.bip39: [
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.BIP44,
      description: "Standard BIP44",
      scriptType: P2pkhAddressType.p2pkh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.BIP49,
      description: "Standard BIP49 compatibility segwit",
      scriptType: P2shAddressType.p2wpkhInP2sh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.BIP84,
      description: "Standard BIP84 native segwit",
      scriptType: SegwitAddressType.p2wpkh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.BIP86,
      description: "Standard BIP86 Taproot",
      scriptType: SegwitAddressType.p2tr,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.NON_STANDARD,
      description: "Non-standard legacy",
      scriptType: P2pkhAddressType.p2pkh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.NON_STANDARD,
      description: "Non-standard compatibility segwit",
      scriptType: P2shAddressType.p2wpkhInP2sh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.NON_STANDARD,
      description: "Non-standard native segwit",
      scriptType: SegwitAddressType.p2wpkh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.BIP44,
      description: "Samourai Deposit",
      scriptType: SegwitAddressType.p2wpkh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.BIP49,
      description: "Samourai Deposit",
      scriptType: SegwitAddressType.p2wpkh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.SAMOURAI_BAD_BANK,
      description: "Samourai Bad Bank (toxic change)",
      scriptType: SegwitAddressType.p2wpkh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.SAMOURAI_WHIRLPOOL_PREMIX,
      description: "Samourai Whirlpool Pre Mix",
      scriptType: SegwitAddressType.p2wpkh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.SAMOURAI_WHIRLPOOL_POSTMIX,
      description: "Samourai Whirlpool Post Mix",
      scriptType: SegwitAddressType.p2wpkh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.SAMOURAI_RICOCHET_LEGACY,
      description: "Samourai Ricochet legacy",
      scriptType: P2pkhAddressType.p2pkh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.SAMOURAI_RICOCHET_COMPATIBILITY_SEGWIT,
      description: "Samourai Ricochet compatibility segwit",
      scriptType: P2shAddressType.p2wpkhInP2sh,
    ),
    BitcoinDerivationInfo(
      derivationType: BitcoinDerivationType.bip39,
      derivationPath: BitcoinDerivationPaths.SAMOURAI_RICOCHET_NATIVE_SEGWIT,
      description: "Samourai Ricochet native segwit",
      scriptType: SegwitAddressType.p2wpkh,
    ),
    BitcoinDerivationInfos.LITECOIN,
    BitcoinDerivationInfos.SILENT_PAYMENTS_SCAN,
    BitcoinDerivationInfos.SILENT_PAYMENTS_SPEND,
  ],
};

const String ELECTRUM_PATH = BitcoinDerivationPaths.ELECTRUM;
