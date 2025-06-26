// Library for Bitcoin addresses handling in the bitcoin_base package.
//
// The library includes essential components such as:
// - Core address functionality.
// - encode/decode Legacy address support.
// - Utility functions for address manipulation.
// - encode/decode Segregated Witness (SegWit) address implementation.
// - Enhanced functionality for improved handling of addresses across diverse networks.
library;

import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/bitcoin/silent_payments/silent_payments.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/crypto/keypair/ec_public.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/utils/enumerate.dart';
import 'package:blockchain_utils_old/blockchain_utils.dart';
import 'package:bitcoin_base/src/utils/script.dart';
import 'util.dart';
part 'core.dart';
part 'legacy_address.dart';
part 'utils/address_utils.dart';
part 'segwit_address.dart';
part 'network_address.dart';
part 'derivations.dart';
