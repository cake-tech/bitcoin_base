import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

class TweakOutputData {
  final int vout;
  final int amount;
  final dynamic spendingInput;

  TweakOutputData({
    required this.vout,
    required this.amount,
    this.spendingInput,
  });
}

class TweakData {
  final String tweak;
  final Map<String, TweakOutputData> outputPubkeys;

  TweakData({required this.tweak, required this.outputPubkeys});
}

class ElectrumTweaksSubscribeResponse {
  final String? message;
  final int block;
  final Map<String, TweakData> blockTweaks;

  ElectrumTweaksSubscribeResponse({
    required this.block,
    required this.blockTweaks,
    this.message,
  });

  static ElectrumTweaksSubscribeResponse? fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return null;
    }

    if (json.containsKey('params')) {
      final params = json['params'] as List<dynamic>;
      final message = params.first["message"];

      if (message != null) {
        return null;
      }
    }

    late int block;
    final blockTweaks = <String, TweakData>{};

    try {
      for (final key in json.keys) {
        block = int.parse(key);
        final txs = json[key] as Map<String, dynamic>;

        for (final txid in txs.keys) {
          final tweakResponseData = txs[txid] as Map<String, dynamic>;

          final tweakHex = tweakResponseData["tweak"].toString();
          final outputPubkeys = (tweakResponseData["output_pubkeys"] as Map<dynamic, dynamic>);

          final tweakOutputData = <String, TweakOutputData>{};

          for (final vout in outputPubkeys.keys) {
            final outputData = outputPubkeys[vout];
            tweakOutputData[outputData[0]] = TweakOutputData(
              vout: int.parse(vout.toString()),
              amount: outputData[1],
              spendingInput: outputData.length > 2 ? outputData[2] : null,
            );
          }

          final tweakData = TweakData(tweak: tweakHex, outputPubkeys: tweakOutputData);
          blockTweaks[txid] = tweakData;
        }
      }
    } catch (_) {
      return ElectrumTweaksSubscribeResponse(
        message: json.containsKey('message') ? json['message'] : null,
        block: 0,
        blockTweaks: {},
      );
    }

    return ElectrumTweaksSubscribeResponse(
      message: json.containsKey('message') ? json['message'] : null,
      block: block,
      blockTweaks: blockTweaks,
    );
  }
}

/// Subscribe to receive block headers when a new block is found.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumTweaksSubscribe
    extends ElectrumRequest<ElectrumTweaksSubscribeResponse?, Map<String, dynamic>> {
  /// blockchain.tweaks.subscribe
  ElectrumTweaksSubscribe({
    required this.height,
    required this.count,
    required this.historicalMode,
  });

  final int height;
  final int count;
  final bool historicalMode;

  @override
  String get method => ElectrumRequestMethods.tweaksSubscribe.method;

  @override
  List toJson() {
    return [height, count, historicalMode];
  }

  /// The header of the current block chain tip.
  @override
  ElectrumTweaksSubscribeResponse? onResponse(result) {
    return ElectrumTweaksSubscribeResponse.fromJson(result);
  }
}
