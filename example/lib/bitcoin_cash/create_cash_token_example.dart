import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:example/services_examples/electrum/electrum_websocket_service.dart';

/// please make sure read this before create transaction on mainnet
/// https://github.com/cashtokens/cashtokens
void main() async {
  /// connect to electrum service with websocket
  /// please see `services_examples` folder for how to create electrum websocket service
  final service = await ElectrumWebSocketService.connect(
      "wss://chipnet.imaginary.cash:50004");

  /// create provider with service
  final provider = ElectrumApiProvider(service);

  /// initialize private key
  final privateKey = ECPrivate.fromBytes(BytesUtils.fromHexString(
      "f9061c5cb343c6b6a73900ee29509bb0bd2213319eea46d2f2a431068c9da06b"));

  /// public key
  final publicKey = privateKey.getPublic();

  /// network
  const network = BitcoinCashNetwork.testnet;

  /// Derives a P2PKH address from the given public key and converts it to a Bitcoin Cash address
  /// for enhanced accessibility within the network.
  final p2pkhAddress = publicKey.toP2pkhAddress();

  /// Reads all UTXOs (Unspent Transaction outputs) associated with the account.
  /// We does not need tokens utxo and we set to false.
  final elctrumUtxos = await provider.request(ElectrumScriptHashListUnspent(
    scriptHash: p2pkhAddress.pubKeyHash(),
    includeTokens: false,
  ));

  /// Converts all UTXOs to a list of UtxoWithAddress, containing UTXO information along with address details.
  final List<UtxoWithAddress> utxos = elctrumUtxos
      .map((e) => UtxoWithAddress(
          utxo: e.toUtxo(p2pkhAddress.type),
          ownerDetails: UtxoAddressDetails(
              publicKey: publicKey.toHex(), address: p2pkhAddress)))
      .toList();

  /// som of utxos in satoshi
  final sumOfUtxo = utxos.sumOfUtxosValue();

  // return;

  /// Every token category ID is a transaction ID:
  /// the ID must be selected from the inputs of its genesis transaction,
  /// and only token genesis inputs – inputs which spend output 0 of their
  /// parent transaction – are eligible
  /// (i.e. outpoint transaction hashes of inputs with an outpoint index of 0).
  /// As such, implementations can locate the genesis transaction of any category
  /// by identifying the transaction that spent the 0th output of the transaction referenced by the category ID.
  String? vout0Hash;
  try {
    // Retrieve the transaction hash of the 0th output UTXO
    vout0Hash =
        utxos.firstWhere((element) => element.utxo.vout == 0).utxo.txHash;
  } on StateError {
    /// if we dont have utxos with index 0 we must create them with some estimate transaction before create transaction
    return;
  }
  // print("vout $vout0Hash");
  // return;
  final bchTransaction = ForkedTransactionBuilder(
      outputs: [
        BitcoinTokenOutput(
            address: p2pkhAddress,

            /// for a token-bearing output (600-700) satoshi
            /// hard-coded value which is expected to be enough to allow
            /// all conceivable token-bearing UTXOs (1000 satoshi)
            value: BtcUtils.toSatoshi("0.00001"),
            token: CashToken(
                category: vout0Hash,

                /// The commitment contents of the NFT held in this output (0 to 40 bytes). T
                /// his field is omitted if no NFT is present. In this case, it is null as it is not an NFT.
                commitment: null,

                /// The number of fungible tokens held in this output (an integer between 1 and 9223372036854775807).
                /// This field is omitted if no fungible tokens are present.
                amount: BigInt.from(800000000000000000),
                bitfield: CashTokenUtils.buildBitfield(
                    hasAmount: true,

                    /// nfts field
                    capability: null,
                    hasCommitmentLength: false,
                    hasNFT: false))),

        /// change address- back amount to account exclude fee and token input value
        BitcoinOutput(
          address: p2pkhAddress,
          value: sumOfUtxo -
              (BtcUtils.toSatoshi("0.00001") + BtcUtils.toSatoshi("0.00003")),
        ),

        /// add token meta data to transaction
        /// see https://cashtokens.org/docs/bcmr/chip/ how to create BCMR
        /// also you can use Registery class for create BCMR
        BCMR(
            uris: [
              "ipfs://bafkreihfrxykireezlcp2jstp7cjwx5nl7of3nuul3qnubxygwvwcjun44"
            ],
            hash:
                "e58df0a44484cac4fd26537fc49b5fad5fdc5db6945ee0da06f835ab61268de7")
      ],
      fee: BtcUtils.toSatoshi("0.00003"),
      network: network,

      /// Bitcoin Cash Metadata Registries
      /// pleas see https://cashtokens.org/docs/bcmr/chip/ for how to create cash metadata
      /// we does not create metadata for this token
      memo: null,
      utxos: utxos,

      /// disable ordering
      outputOrdering: BitcoinOrdering.none);
  final transaaction =
      bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
    return privateKey.signInput(trDigest, sigHash: sighash);
  });

  /// transaction ID
  transaaction.txId();

  /// for calculation fee
  transaaction.getSize();

  /// raw of encoded transaction in hex
  final transactionRaw = transaaction.toHex();

  /// send transaction to network
  await provider
      .request(ElectrumBroadCastTransaction(transactionRaw: transactionRaw));

  /// done! check the transaction in block explorer
  ///  https://chipnet.imaginary.cash/tx/fe0f9f84bd8782b8037160c09a515d39a9cc5bbeda6dcca6fb8a89e952bc9dea
}
