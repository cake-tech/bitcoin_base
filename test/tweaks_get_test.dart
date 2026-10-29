// Tests for `blockchain.tweaks.get` (ElectrumTweaksGet), the two-pass
// amount fetch's second pass (ADR-0015) added for the sp-scan-bench Silent
// Payments scan-speed effort. Request/response shape verified against the
// real server implementation (electrs-tweaks's `src/electrum/server.rs`,
// `blockchain_tweaks_get`), not guessed: params `[txid, vout, height]`,
// response `{"amount": <u64>, "spent": <bool>}`.
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

void main() {
  group('ElectrumTweaksGet request params', () {
    test('sends txid, vout, height in that order', () {
      final req = ElectrumTweaksGet(
        txid: '38088f720c1f30e5c54a56e385984ebd11d6855b14d6158f8833771501709e68',
        vout: 0,
        height: 112,
      );

      expect(req.toParams(),
          ['38088f720c1f30e5c54a56e385984ebd11d6855b14d6158f8833771501709e68', 0, 112]);
    });

    test('method is blockchain.tweaks.get', () {
      final req = ElectrumTweaksGet(txid: 'ab' * 32, vout: 1, height: 500);
      expect(req.method, 'blockchain.tweaks.get');
    });
  });

  group('ElectrumTweaksGetResponse.fromJson', () {
    test('parses a real unspent response shape', () {
      final response = ElectrumTweaksGetResponse.fromJson({'amount': 99990000, 'spent': false});
      expect(response.amount, 99990000);
      expect(response.spent, false);
    });

    test('parses a spent response shape', () {
      final response = ElectrumTweaksGetResponse.fromJson({'amount': 1234, 'spent': true});
      expect(response.amount, 1234);
      expect(response.spent, true);
    });
  });
}
