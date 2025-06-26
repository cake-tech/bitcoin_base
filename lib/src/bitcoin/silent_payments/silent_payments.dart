// Library for Bitcoin Silent Payments handling in the bitcoin_base package.
//
// The library includes essential components such as:
// - Core address functionality.
// - encode/decode address support.
// - Utility functions for address manipulation.
// - Generate labeled addresses.
// - Scan transactions.
// - Generate payment outputs.
library bitcoin_base.silent_payments;

import 'dart:typed_data';

import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/crypto/crypto.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils_old/blockchain_utils.dart';

part 'address.dart';
part 'payment.dart';
part 'utils.dart';
