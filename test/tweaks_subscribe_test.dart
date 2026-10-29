// Tests for the blockchain.tweaks.subscribe v1/v2 request+response plumbing
// added for the sp-scan-bench Silent Payments scan-speed effort. The v2
// fixture bytes below are the real capture from electrs-tweaks's regtest
// build (electrs-tweaks/doc/tweaks_v2_fixture.md — a genuine BIP-352
// payment, not synthesized), byte-layout spec in
// electrs-tweaks/doc/tweaks_v2_protocol.md. This package only needs to
// recognize and pass through the `tweaks_v2` blob unparsed — the decoder
// itself lives in `sp_scanner`
// (sp-scan-bench/docs/adr/0002-binary-protocol-decode-in-sp-scanner.md).
//
// IMPORTANT on JSON shapes used here: `fromJson` is called with whatever
// `ElectrumTcpService._findResult` (electrum_tcp_service.dart) hands the
// subscription's stream. That layer already unwraps every per-block/
// per-message *notification* to `params[0]` before it reaches here (so a
// real v1 block notification arrives as `{"<height>": {...}}` directly, not
// wrapped in `{jsonrpc, method, params}`) — EXCEPT the one terminal
// id-matched RPC result for the original subscribe call, which keeps its
// full envelope intact and lands on the same stream. Both shapes are
// exercised below; getting this wrong silently breaks the corresponding
// `fromJson` branch without any test noticing.
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:test/test.dart';

void main() {
  group('ElectrumTweaksSubscribe request params', () {
    test('omits protocolVersion from the wire request when not set', () {
      final req = ElectrumTweaksSubscribe(height: 1, count: 1000, historicalMode: true);
      expect(req.toParams(), [1, 1000, true]);
    });

    test('includes protocolVersion when explicitly negotiated', () {
      final req = ElectrumTweaksSubscribe(
          height: 1, count: 1000, historicalMode: true, protocolVersion: 2);
      expect(req.toParams(), [1, 1000, true, 2]);
    });
  });

  group('ElectrumTweaksSubscribeResponse.fromJson — v1 unchanged', () {
    test('parses a real v1 block notification (electrs-tweaks fixture, height 112), unwrapped', () {
      // Unwrapped: this is what actually arrives on the subscription stream
      // for a per-block push — see the file-level note above.
      final json = {
        '112': {
          '38088f720c1f30e5c54a56e385984ebd11d6855b14d6158f8833771501709e68': {
            'output_pubkeys': {
              '0': ['46db9bd8d491531b2e783d32e07acb0624093fcdad75573e7e6da39ac21d0c13', 99990000]
            },
            'tweak': '0302cc2a75db0e06919f9d3312c17c831b68ff1ead95498a529fd366d64921e3c0',
          }
        }
      };

      final response = ElectrumTweaksSubscribeResponse.fromJson(json);
      expect(response, isNotNull);
      expect(response!.block, 112);
      expect(response.message, isNull);
      expect(response.tweaksV2Bytes, isNull);
      final tx = response
          .blockTweaks['38088f720c1f30e5c54a56e385984ebd11d6855b14d6158f8833771501709e68']!;
      expect(tx.tweak, '0302cc2a75db0e06919f9d3312c17c831b68ff1ead95498a529fd366d64921e3c0');
      expect(
        tx.outputPubkeys['46db9bd8d491531b2e783d32e07acb0624093fcdad75573e7e6da39ac21d0c13']!
            .amount,
        99990000,
      );
    });

    test('the mid-stream "done" notification (unwrapped) yields a message-bearing, non-null response', () {
      // This is the per-response-cycle "no more blocks in this batch" signal
      // — the caller checks `response.message != null`, not `response ==
      // null`, to detect it (electrum_wallet.dart's listenFn: `noData =
      // response.message != null`).
      final response = ElectrumTweaksSubscribeResponse.fromJson({'message': 'done'});
      expect(response, isNotNull);
      expect(response!.message, 'done');
    });

    test('the terminal id-matched RPC result (still envelope-wrapped) yields null', () {
      // Unlike every notification, the one response that completes the
      // original subscribe call's own id keeps its outer envelope intact
      // when it lands on the same subscription stream (see the file-level
      // note). This is the shape electrs-tweaks's doc/tweaks_v2_protocol.md
      // §4 describes for `max_protocol_version`'s home — fromJson discards
      // it as a harmless echo of the same "done" the mid-stream notification
      // already delivered.
      final json = {
        'jsonrpc': '2.0',
        'method': 'blockchain.tweaks.subscribe',
        'params': [
          {'max_protocol_version': 2, 'message': 'done'}
        ],
      };
      expect(ElectrumTweaksSubscribeResponse.fromJson(json), isNull);
    });
  });

  group('ElectrumTweaksSubscribeResponse.fromJson — v2 pass-through', () {
    test('decodes the tweaks_v2 base64 field to raw bytes, unparsed', () {
      // electrs-tweaks/doc/tweaks_v2_fixture.md blob 2 (height 112, the
      // genuine BIP-352 payment) — raw hex, reproduced here as the base64
      // that was actually captured on the wire. Unwrapped, matching how a
      // real v2 block notification arrives (see file-level note).
      const v2Base64 =
          'cAAAAAFonnABFXcziI8V1hRbhdYRvU6YheNWSsXlMB8Mco8IOAMCzCp12w4GkZ+dMxLBfIMbaP8erZVJilKf02bWSSHjwAEARtub2NSRUxsueD0y4HrLBiQJP82tdVc+fm2jmsIdDBM=';
      const expectedHex =
          '7000000001689e7001157733888f15d6145b85d611bd4e9885e3564ac5e5301f0c728f0838'
          '0302cc2a75db0e06919f9d3312c17c831b68ff1ead95498a529fd366d64921e3c0'
          '010046db9bd8d491531b2e783d32e07acb0624093fcdad75573e7e6da39ac21d0c13';

      final response = ElectrumTweaksSubscribeResponse.fromJson({'tweaks_v2': v2Base64});

      expect(response, isNotNull);
      expect(response!.tweaksV2Bytes, isNotNull);
      expect(response.blockTweaks, isEmpty);

      final actualHex =
          response.tweaksV2Bytes!.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(actualHex, expectedHex);
    });

    test('decodes the zero-tx empty-tail bookmark blob (height 1), unwrapped', () {
      const v2Base64 = 'AQAAAAA='; // height=1 (u32 LE), tx_count=0
      final response = ElectrumTweaksSubscribeResponse.fromJson({'tweaks_v2': v2Base64});
      expect(response, isNotNull);
      expect(response!.tweaksV2Bytes, [0x01, 0x00, 0x00, 0x00, 0x00]);
    });
  });
}
