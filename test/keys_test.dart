import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  group("TestPrivateKeys", () {
    const keyWifc = "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn";
    const keyWif = "5HpHagT65TZzG1PH3CSu63k8DbpvD8s5ip4nEB3kEsreAnchuDf";
    final keyBytes = [
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
    ];

    test("test1", () {
      final p = ECPrivate.fromWif(keyWifc,
          netVersion: BitcoinNetwork.mainnet.wifNetVer);

      expect(p.toBytes(), keyBytes);
      expect(p.toWif(compressed: false), keyWif);
    });
  });

  group("TestPublicKeys", () {
    const String publicKeyHex =
        '0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8';
    final List<int> publicKeyBytes = List<int>.from([
      121,
      190,
      102,
      126,
      249,
      220,
      187,
      172,
      85,
      160,
      98,
      149,
      206,
      135,
      11,
      7,
      2,
      155,
      252,
      219,
      45,
      206,
      40,
      217,
      89,
      242,
      129,
      91,
      22,
      248,
      23,
      152,
      72,
      58,
      218,
      119,
      38,
      163,
      196,
      101,
      93,
      164,
      251,
      252,
      14,
      17,
      8,
      168,
      253,
      23,
      180,
      72,
      166,
      133,
      84,
      25,
      156,
      71,
      208,
      143,
      251,
      16,
      212,
      184
    ]);
    const String unCompressedAddress = '1EHNa6Q4Jz2uvNExL497mE43ikXhwF6kZm';

    test("testPubkeyCreation", () {
      final pub1 = ECPublic.fromHex(publicKeyHex);
      expect(
          pub1.toP2pkhAddress(compressed: false).toAddress(BitcoinNetwork.mainnet),
          unCompressedAddress);
      expect(pub1.toBytes(whitPrefix: false), publicKeyBytes);
      expect(pub1.toHash160(), pub1.toP2pkhAddress(compressed: true).addressProgram);
    });
  });

  group("TestP2pkhAddresses", () {
    const String hash160 = '91b24bf9f5288532960ac687abb035127b1d28a5';
    const String hash160c = '751e76e8199196d454941c45d1b3a323f1433bd6';
    const String address = '1EHNa6Q4Jz2uvNExL497mE43ikXhwF6kZm';
    const String addressc = '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH';
    test("test1", () {
      final p1 = P2pkhAddress.fromHash160(h160: hash160);
      final p2 = P2pkhAddress.fromHash160(h160: hash160c);
      expect(p1.toAddress(BitcoinNetwork.mainnet), address);
      expect(p2.toAddress(BitcoinNetwork.mainnet), addressc);
    });
    test("test2", () {
      final p1 = P2pkhAddress.fromAddress(
          address: address, network: BitcoinNetwork.mainnet);
      final p2 = P2pkhAddress.fromAddress(
          address: addressc, network: BitcoinNetwork.mainnet);
      expect(p1.addressProgram, hash160);
      expect(p2.addressProgram, hash160c);
    });
  });

  group("TestSignAndVerify", () {
    const String message = "The test!";
    const String keyWifc =
        "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn";
    final ECPrivate priv = ECPrivate.fromWif(keyWifc,
        netVersion: BitcoinNetwork.mainnet.wifNetVer);
    final ECPublic pub = priv.getPublic();

    test("test1", () {
      final sign = priv.signMessage(StringUtils.encode(message));
      pub.verify(StringUtils.encode(message), BytesUtils.fromHexString(sign));

      expect(
          pub.verify(
              StringUtils.encode(message), BytesUtils.fromHexString(sign)),
          true);
    });

    test("test2", () {});
  });

  group("TestP2pkhAddresses", () {
    final ECPrivate priv = ECPrivate.fromWif(
        'cTALNpTpRbbxTCJ2A5Vq88UxT44w1PE2cYqiB3n4hRvzyCev1Wwo',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    ECPublic pub = priv.getPublic();
    const String p2shaddress = '2NDkr9uD2MSY5em3rsjkff8fLZcJzCfY3W1';
    test("test create", () {
      final script = Script(script: [pub.toHex(), 'OP_CHECKSIG']);
      final addr = P2shAddress.fromRedeemScript(
          script: script, type: P2shAddressType.p2pkInP2sh);
      expect(addr.toAddress(BitcoinNetwork.testnet), p2shaddress);
    });
  });

  group("TestP2pkhAddresses", () {
    final ECPrivate priv = ECPrivate.fromWif(
        'cVdte9ei2xsVjmZSPtyucG43YZgNkmKTqhwiUA8M4Fc3LdPJxPmZ',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    ECPublic pub = priv.getPublic();
    const String correctP2wpkhAddress =
        'tb1qxmt9xgewg6mxc4mvnzvrzu4f2v0gy782fydg0w';
    const String correctP2shP2wpkhAddress =
        '2N8Z5t3GyPW1hSAEJZqQ1GUkZ9ofoGhgKPf';
    const String correctP2wshAddress =
        'tb1qy4kdfavhluvnhpwcqmqrd8x0ge2ynnsl7mv2mdmdskx4g3fc6ckq8f44jg';
    const String correctP2shP2wshAddress =
        '2NC2DBZd3WfEF9cZcpBRDYxCTGCVCfPUf7Q';
    test("test1", () {
      final address = P2wpkhAddress.fromProgram(
          program: pub.toP2wpkhAddress().addressProgram);
      expect(correctP2wpkhAddress, address.toAddress(BitcoinNetwork.testnet));
    });
    test("test2", () {
      final addr = ECPrivate.fromWif(
              "cTmyBsxMQ3vyh4J3jCKYn2Au7AhTKvqeYuxxkinsg6Rz3BBPrYKK",
              netVersion: BitcoinNetwork.testnet.wifNetVer)
          .getPublic()
          .toP2wpkhAddress();
      final p2sh = P2shAddress.fromRedeemScript(
          script: addr.toScriptPubKey(), type: P2shAddressType.p2pkInP2sh);
      expect(correctP2shP2wpkhAddress, p2sh.toAddress(BitcoinNetwork.testnet));
    });
    test("test3", () {
      final prive = ECPrivate.fromWif(
          "cNn8itYxAng4xR4eMtrPsrPpDpTdVNuw7Jb6kfhFYZ8DLSZBCg37",
          netVersion: BitcoinNetwork.testnet.wifNetVer);
      final script = Script(script: [
        'OP_1',
        prive.getPublic().toHex(),
        'OP_1',
        'OP_CHECKMULTISIG'
      ]);
      final pw = P2wshAddress.fromRedeemScript(script: script);
      expect(pw.toAddress(BitcoinNetwork.testnet), correctP2wshAddress);
    });
    test("test4", () {
      final prive = ECPrivate.fromWif(
          "cNn8itYxAng4xR4eMtrPsrPpDpTdVNuw7Jb6kfhFYZ8DLSZBCg37",
          netVersion: BitcoinNetwork.testnet.wifNetVer);
      final script = Script(script: [
        'OP_1',
        prive.getPublic().toHex(),
        'OP_1',
        'OP_CHECKMULTISIG'
      ]);
      final pw = P2wshAddress.fromRedeemScript(script: script);
      final p2sh = P2shAddress.fromRedeemScript(
          script: pw.toScriptPubKey(), type: P2shAddressType.p2pkInP2sh);
      expect(p2sh.toAddress(BitcoinNetwork.testnet), correctP2shP2wshAddress);
    });
  });

  group("TestP2trAddresses", () {
    final privEven = ECPrivate.fromWif(
        'cTLeemg1bCXXuRctid7PygEn7Svxj4zehjTcoayrbEYPsHQo248w',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    const String correctEvenPk =
        '0271fe85f75e97d22e74c2dd6425e843def8b662b928f24f724ae6a2fd0c4e0419';
    const String correctEvenTrAddr =
        'tb1pk426x6qvmncj5vzhtp5f2pzhdu4qxsshszswga8ea6sycj9nulmsu7syz0';
    const String correctEvenTweakedPk =
        'b555a3680cdcf12a305758689504576f2a03421780a0e474f9eea04c48b3e7f7';

    final privOdd = ECPrivate.fromWif(
        'cRPxBiKrJsH94FLugmiL4xnezMyoFqGcf4kdgNXGuypNERhMK6AT',
        netVersion: BitcoinNetwork.testnet.wifNetVer);
    const String correctOddPk =
        '03a957ff7ead882e4c95be2afa684ab0e84447149883aba60c067adc054472785b';
    const String correctOddTrAddr =
        'tb1pdr8q4tuqqeglxxhkxl3trxt0dy5jrnaqvg0ddwu7plraxvntp8dqv8kvyq';
    const String correctOddTweakedPk =
        '68ce0aaf800651f31af637e2b1996f692921cfa0621ed6bb9e0fc7d3326b09da';
    test("test1", () {
      final pub = privEven.getPublic();
      expect(pub.toHex(), correctEvenPk);
    });
    test("test2", () {
      final pub = privEven.getPublic();
      final addr = pub.toTaprootAddress().toAddress(BitcoinNetwork.testnet);
      expect(addr, correctEvenTrAddr);
    });
    test("test3", () {
      final pub = privEven.getPublic();
      final addr = pub.toTaprootAddress();
      expect(addr.addressProgram, correctEvenTweakedPk);
    });
    test("test4", () {
      final pub = privOdd.getPublic();
      expect(pub.toHex(), correctOddPk);
    });
    test("test5", () {
      final pub = privOdd.getPublic();
      final addr = pub.toTaprootAddress().toAddress(BitcoinNetwork.testnet);
      expect(addr, correctOddTrAddr);
    });
    test("test6", () {
      final pub = privOdd.getPublic();
      final addr = pub.toTaprootAddress();
      expect(addr.addressProgram, correctOddTweakedPk);
    });
  });
}
