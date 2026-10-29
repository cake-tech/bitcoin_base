import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

class ElectrumTweaksGetResponse {
  final int amount;
  final bool spent;

  ElectrumTweaksGetResponse({required this.amount, required this.spent});

  static ElectrumTweaksGetResponse fromJson(Map<String, dynamic> json) {
    return ElectrumTweaksGetResponse(
      amount: json['amount'] as int,
      spent: json['spent'] as bool,
    );
  }
}

/// Single-shot lookup of one Silent Payments output's resolved amount and
/// spent status — the two-pass amount fetch's second pass (ADR-0015),
/// issued once a `blockchain.tweaks.subscribe` match is found (v1's
/// `blockTweaks` and v2's decoded records both carry the output pubkey and
/// vout, but never an amount).
///
/// blockchain.tweaks.get
/// https://github.com/Blockstream/electrs (electrs-tweaks fork,
/// `src/electrum/server.rs`'s `blockchain_tweaks_get`)
class ElectrumTweaksGet extends ElectrumRequest<ElectrumTweaksGetResponse, Map<String, dynamic>> {
  ElectrumTweaksGet({required this.txid, required this.vout, required this.height});

  /// The funding transaction's txid, as conventional display (big-endian)
  /// hex — same convention as every other JSON-carried txid in this
  /// codebase (unlike the v2 *binary* wire protocol, which uses
  /// internal/reversed order; this is a plain JSON-RPC call, not that
  /// format).
  final String txid;
  final int vout;

  /// The funding transaction's block height (the height the match was
  /// found at, `tweakHeight` in `_handleScanSilentPayments`) — NOT the
  /// spending transaction's height if this output was later spent. The
  /// server keys its lookup by `(height, txid)` exactly, so passing the
  /// wrong height here fails with a "no tweak row" error even when the
  /// txid/vout are correct.
  final int height;

  @override
  String get method => ElectrumRequestMethods.tweaksGet.method;

  @override
  List toParams() => [txid, vout, height];

  /// Throws `RPCError` (from `package:blockchain_utils`) on a server-side
  /// JSON-RPC error — e.g. no tweak row at this (txid, height), or an
  /// ineligible vout. That is a structural, permanent failure for this
  /// specific match (a malformed/incorrect call), not a transient
  /// connection problem — callers must not fold it into ADR-0015's
  /// indefinite connection-retry loop, or a single unresolvable match
  /// wedges the worker's range advancement forever.
  @override
  ElectrumTweaksGetResponse onResponse(Map<String, dynamic> result) {
    return ElectrumTweaksGetResponse.fromJson(result);
  }
}
