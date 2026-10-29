import 'dart:convert';

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

  /// Raw v2 block-record bytes (already base64-decoded), present only when
  /// this response used the compact binary protocol (`protocolVersion: 2`
  /// on the request) — see electrs-tweaks's `doc/tweaks_v2_protocol.md`.
  /// Hand these straight to `sp_scanner`'s `ScanSession.scanBlock`; do not
  /// attempt to parse them here — the decoder lives in `sp_scanner`, not
  /// this package (sp-scan-bench/docs/adr/0002-binary-protocol-decode-in-sp-scanner.md).
  /// When present, `blockTweaks` is empty and `block` is not derivable from
  /// this response alone (the height is inside the blob itself).
  final List<int>? tweaksV2Bytes;

  ElectrumTweaksSubscribeResponse({
    required this.block,
    required this.blockTweaks,
    this.message,
    this.tweaksV2Bytes,
  });

  static ElectrumTweaksSubscribeResponse? fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return null;
    }

    // Per-block (and per-message) notifications arrive already unwrapped to
    // `params[0]` by the RPC layer (`_findResult` in electrum_tcp_service.dart
    // returns `data["params"]?[0]` for method-matched, id-less messages) — so
    // a v2 block notification is `json` itself being `{"tweaks_v2": "..."}`,
    // the same way a v1 block notification is `json` itself being
    // `{"<height>": {...}}`. This must be checked before the `containsKey
    // ('params')` branch below, which instead detects the *terminal*
    // id-matched RPC result (the one message on this stream that still has
    // its outer `{jsonrpc, method, params}` envelope intact — see
    // electrs-tweaks's doc/tweaks_v2_protocol.md §4).
    final tweaksV2 = json['tweaks_v2'];
    if (tweaksV2 is String) {
      return ElectrumTweaksSubscribeResponse(
        block: 0,
        blockTweaks: const {},
        tweaksV2Bytes: base64Decode(tweaksV2),
      );
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
  ///
  /// [protocolVersion] is optional and omitted from the wire request by
  /// default, matching every caller before this field existed. Only pass it
  /// after negotiating (never blindly): `2` requests the compact binary
  /// protocol (see electrs-tweaks's `doc/tweaks_v2_protocol.md`) and the
  /// server hard-errors on a version it doesn't support rather than
  /// silently downgrading, so a caller must first confirm the server
  /// advertises `>= 2` (via `max_protocol_version` on a prior result) and
  /// that this build's `sp_scanner` decoder also supports it
  /// (`sp_scanner.maxWireVersion()`) before setting this.
  ElectrumTweaksSubscribe({
    required this.height,
    required this.count,
    required this.historicalMode,
    this.protocolVersion,
  });

  final int height;
  final int count;
  final bool historicalMode;
  final int? protocolVersion;

  @override
  String get method => ElectrumRequestMethods.tweaksSubscribe.method;

  @override
  List toParams() {
    if (protocolVersion == null) {
      return [height, count, historicalMode];
    }
    return [height, count, historicalMode, protocolVersion];
  }

  /// The header of the current block chain tip.
  @override
  ElectrumTweaksSubscribeResponse? onResponse(result) {
    return ElectrumTweaksSubscribeResponse.fromJson(result);
  }
}
