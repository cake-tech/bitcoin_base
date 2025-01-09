/// ignore_for_file: constant_identifier_names, equal_keys_in_map, non_constant_identifier_names, camel_case_types
/// Constants and identifiers used in the Bitcoin-related code.
// ignore_for_file: constant_identifier_names, non_constant_identifier_names, equal_keys_in_map, camel_case_types

class BitcoinOpCodeConst {
  static const int opPushData1 = 0x4c;
  static const int opPushData2 = 0x4d;
  static const int opPushData4 = 0x4e;
  static bool isOpPushData(int byte) {
    return byte == BitcoinOpCodeConst.opPushData1 ||
        byte == BitcoinOpCodeConst.opPushData2 ||
        byte == BitcoinOpCodeConst.opPushData4;
  }

  static const OP_0 = "OP_0";
  static const OP_FALSE = "OP_FALSE";
  static const OP_PUSHDATA1 = "OP_PUSHDATA1";
  static const OP_PUSHDATA2 = "OP_PUSHDATA2";
  static const OP_PUSHDATA4 = "OP_PUSHDATA4";
  static const OP_1NEGATE = "OP_1NEGATE";
  static const OP_1 = "OP_1";
  static const OP_TRUE = "OP_TRUE";
  static const OP_2 = "OP_2";
  static const OP_3 = "OP_3";
  static const OP_4 = "OP_4";
  static const OP_5 = "OP_5";
  static const OP_6 = "OP_6";
  static const OP_7 = "OP_7";
  static const OP_8 = "OP_8";
  static const OP_9 = "OP_9";
  static const OP_10 = "OP_10";
  static const OP_11 = "OP_11";
  static const OP_12 = "OP_12";
  static const OP_13 = "OP_13";
  static const OP_14 = "OP_14";
  static const OP_15 = "OP_15";
  static const OP_16 = "OP_16";

  /// flow control
  static const OP_NOP = "OP_NOP";
  static const OP_IF = "OP_IF";
  static const OP_NOTIF = "OP_NOTIF";
  static const OP_ELSE = "OP_ELSE";
  static const OP_ENDIF = "OP_ENDIF";
  static const OP_VERIFY = "OP_VERIFY";
  static const OP_RETURN = "OP_RETURN";

  /// stack
  static const OP_TOALTSTACK = "OP_TOALTSTACK";
  static const OP_FROMALTSTACK = "OP_FROMALTSTACK";
  static const OP_IFDUP = "OP_IFDUP";
  static const OP_DEPTH = "OP_DEPTH";
  static const OP_DROP = "OP_DROP";
  static const OP_DUP = "OP_DUP";
  static const OP_NIP = "OP_NIP";
  static const OP_OVER = "OP_OVER";
  static const OP_PICK = "OP_PICK";
  static const OP_ROLL = "OP_ROLL";
  static const OP_ROT = "OP_ROT";
  static const OP_SWAP = "OP_SWAP";
  static const OP_TUCK = "OP_TUCK";
  static const OP_2DROP = "OP_2DROP";
  static const OP_2DUP = "OP_2DUP";
  static const OP_3DUP = "OP_3DUP";
  static const OP_2OVER = "OP_2OVER";
  static const OP_2ROT = "OP_2ROT";
  static const OP_2SWAP = "OP_2SWAP";

  /// splice
  /// 'OP_CAT': [0x7e],
  /// 'OP_SUBSTR': [0x7f],
  /// 'OP_LEFT': [0x80],
  /// 'OP_RIGHT': [0x81],
  static const OP_SIZE = "OP_SIZE";

  /// bitwise logic
  /// 'OP_INVERT': [0x83],
  /// 'OP_AND': [0x84],
  /// 'OP_OR': [0x85],
  /// 'OP_XOR': [0x86],
  static const OP_EQUAL = "OP_EQUAL";
  static const OP_EQUALVERIFY = "OP_EQUALVERIFY";

  /// arithmetic
  static const OP_1ADD = "OP_1ADD";
  static const OP_1SUB = "OP_1SUB";

  /// 'OP_2MUL': [0x8d],
  /// 'OP_2DIV': [0x8e],
  static const OP_NEGATE = "OP_NEGATE";
  static const OP_ABS = "OP_ABS";
  static const OP_NOT = "OP_NOT";
  static const OP_0NOTEQUAL = "OP_0NOTEQUAL";
  static const OP_ADD = "OP_ADD";
  static const OP_SUB = "OP_SUB";

  /// 'OP_MUL': [0x95],
  /// 'OP_DIV': [0x96],
  /// 'OP_MOD': [0x97],
  /// 'OP_LSHIFT': [0x98],
  /// 'OP_RSHIFT': [0x99],
  static const OP_BOOLAND = "OP_BOOLAND";
  static const OP_BOOLOR = "OP_BOOLOR";
  static const OP_NUMEQUAL = "OP_NUMEQUAL";
  static const OP_NUMEQUALVERIFY = "OP_NUMEQUALVERIFY";
  static const OP_NUMNOTEQUAL = "OP_NUMNOTEQUAL";
  static const OP_LESSTHAN = "OP_LESSTHAN";
  static const OP_GREATERTHAN = "OP_GREATERTHAN";
  static const OP_LESSTHANOREQUAL = "OP_LESSTHANOREQUAL";
  static const OP_GREATERTHANOREQUAL = "OP_GREATERTHANOREQUAL";
  static const OP_MIN = "OP_MIN";
  static const OP_MAX = "OP_MAX";
  static const OP_WITHIN = "OP_WITHIN";

  /// crypto
  static const OP_RIPEMD160 = "OP_RIPEMD160";
  static const OP_SHA1 = "OP_SHA1";
  static const OP_SHA256 = "OP_SHA256";
  static const OP_HASH160 = "OP_HASH160";
  static const OP_HASH256 = "OP_HASH256";
  static const OP_CODESEPARATOR = "OP_CODESEPARATOR";
  static const OP_CHECKSIG = "OP_CHECKSIG";
  static const OP_CHECKSIGVERIFY = "OP_CHECKSIGVERIFY";
  static const OP_CHECKMULTISIG = "OP_CHECKMULTISIG";
  static const OP_CHECKMULTISIGVERIFY = "OP_CHECKMULTISIGVERIFY";

  /// locktime
  static const OP_NOP2 = "OP_NOP2";
  static const OP_CHECKLOCKTIMEVERIFY = "OP_CHECKLOCKTIMEVERIFY";
  static const OP_NOP3 = "OP_NOP3";
  static const OP_CHECKSEQUENCEVERIFY = "OP_CHECKSEQUENCEVERIFY";

  static const Map<String, List<int>> OP_CODES = {
    'OP_0': [0x00],
    'OP_FALSE': [0x00],
    'OP_PUSHDATA1': [0x4c],
    'OP_PUSHDATA2': [0x4d],
    'OP_PUSHDATA4': [0x4e],
    'OP_1NEGATE': [0x4f],
    'OP_1': [0x51],
    'OP_TRUE': [0x51],
    'OP_2': [0x52],
    'OP_3': [0x53],
    'OP_4': [0x54],
    'OP_5': [0x55],
    'OP_6': [0x56],
    'OP_7': [0x57],
    'OP_8': [0x58],
    'OP_9': [0x59],
    'OP_10': [0x5a],
    'OP_11': [0x5b],
    'OP_12': [0x5c],
    'OP_13': [0x5d],
    'OP_14': [0x5e],
    'OP_15': [0x5f],
    'OP_16': [0x60],

    /// flow control
    'OP_NOP': [0x61],
    'OP_IF': [0x63],
    'OP_NOTIF': [0x64],
    'OP_ELSE': [0x67],
    'OP_ENDIF': [0x68],
    'OP_VERIFY': [0x69],
    'OP_RETURN': [0x6a],

    /// stack
    'OP_TOALTSTACK': [0x6b],
    'OP_FROMALTSTACK': [0x6c],
    'OP_IFDUP': [0x73],
    'OP_DEPTH': [0x74],
    'OP_DROP': [0x75],
    'OP_DUP': [0x76],
    'OP_NIP': [0x77],
    'OP_OVER': [0x78],
    'OP_PICK': [0x79],
    'OP_ROLL': [0x7a],
    'OP_ROT': [0x7b],
    'OP_SWAP': [0x7c],
    'OP_TUCK': [0x7d],
    'OP_2DROP': [0x6d],
    'OP_2DUP': [0x6e],
    'OP_3DUP': [0x6f],
    'OP_2OVER': [0x70],
    'OP_2ROT': [0x71],
    'OP_2SWAP': [0x72],

    /// splice
    /// 'OP_CAT': [0x7e],
    /// 'OP_SUBSTR': [0x7f],
    /// 'OP_LEFT': [0x80],
    /// 'OP_RIGHT': [0x81],
    'OP_SIZE': [0x82],

    /// bitwise logic
    /// 'OP_INVERT': [0x83],
    /// 'OP_AND': [0x84],
    /// 'OP_OR': [0x85],
    /// 'OP_XOR': [0x86],
    'OP_EQUAL': [0x87],
    'OP_EQUALVERIFY': [0x88],

    /// arithmetic
    'OP_1ADD': [0x8b],
    'OP_1SUB': [0x8c],

    /// 'OP_2MUL': [0x8d],
    /// 'OP_2DIV': [0x8e],
    'OP_NEGATE': [0x8f],
    'OP_ABS': [0x90],
    'OP_NOT': [0x91],
    'OP_0NOTEQUAL': [0x92],
    'OP_ADD': [0x93],
    'OP_SUB': [0x94],

    /// 'OP_MUL': [0x95],
    /// 'OP_DIV': [0x96],
    /// 'OP_MOD': [0x97],
    /// 'OP_LSHIFT': [0x98],
    /// 'OP_RSHIFT': [0x99],
    'OP_BOOLAND': [0x9a],
    'OP_BOOLOR': [0x9b],
    'OP_NUMEQUAL': [0x9c],
    'OP_NUMEQUALVERIFY': [0x9d],
    'OP_NUMNOTEQUAL': [0x9e],
    'OP_LESSTHAN': [0x9f],
    'OP_GREATERTHAN': [0xa0],
    'OP_LESSTHANOREQUAL': [0xa1],
    'OP_GREATERTHANOREQUAL': [0xa2],
    'OP_MIN': [0xa3],
    'OP_MAX': [0xa4],
    'OP_WITHIN': [0xa5],

    /// crypto
    'OP_RIPEMD160': [0xa6],
    'OP_SHA1': [0xa7],
    'OP_SHA256': [0xa8],
    'OP_HASH160': [0xa9],
    'OP_HASH256': [0xaa],
    'OP_CODESEPARATOR': [0xab],
    'OP_CHECKSIG': [0xac],
    'OP_CHECKSIGVERIFY': [0xad],
    'OP_CHECKMULTISIG': [0xae],
    'OP_CHECKMULTISIGVERIFY': [0xaf],

    /// locktime
    'OP_NOP2': [0xb1],
    'OP_CHECKLOCKTIMEVERIFY': [0xb1],
    'OP_NOP3': [0xb2],
    'OP_CHECKSEQUENCEVERIFY': [0xb2],
  };

  static final Map<int, String> CODE_OPS = {
    /// constants
    0: 'OP_0',
    76: 'OP_PUSHDATA1',
    77: 'OP_PUSHDATA2',
    78: 'OP_PUSHDATA4',
    79: 'OP_1NEGATE',
    81: 'OP_1',
    82: 'OP_2',
    83: 'OP_3',
    84: 'OP_4',
    85: 'OP_5',
    86: 'OP_6',
    87: 'OP_7',
    88: 'OP_8',
    89: 'OP_9',
    90: 'OP_10',
    91: 'OP_11',
    92: 'OP_12',
    93: 'OP_13',
    94: 'OP_14',
    95: 'OP_15',
    96: 'OP_16',

    /// flow control
    97: 'OP_NOP',
    99: 'OP_IF',
    100: 'OP_NOTIF',
    103: 'OP_ELSE',
    104: 'OP_ENDIF',
    105: 'OP_VERIFY',
    106: 'OP_RETURN',

    /// stack
    107: 'OP_TOALTSTACK',
    108: 'OP_FROMALTSTACK',
    115: 'OP_IFDUP',
    116: 'OP_DEPTH',
    117: 'OP_DROP',
    118: 'OP_DUP',
    119: 'OP_NIP',
    120: 'OP_OVER',
    121: 'OP_PICK',
    122: 'OP_ROLL',
    123: 'OP_ROT',
    124: 'OP_SWAP',
    125: 'OP_TUCK',
    109: 'OP_2DROP',
    110: 'OP_2DUP',
    111: 'OP_3DUP',
    112: 'OP_2OVER',
    113: 'OP_2ROT',
    114: 'OP_2SWAP',

    /// splice
    130: 'OP_SIZE',

    /// bitwise logic
    135: 'OP_EQUAL',
    136: 'OP_EQUALVERIFY',

    /// arithmetic
    139: 'OP_1ADD',
    140: 'OP_1SUB',
    143: 'OP_NEGATE',
    144: 'OP_ABS',
    145: 'OP_NOT',
    146: 'OP_0NOTEQUAL',
    147: 'OP_ADD',
    148: 'OP_SUB',
    154: 'OP_BOOLAND',
    155: 'OP_BOOLOR',
    156: 'OP_NUMEQUAL',
    157: 'OP_NUMEQUALVERIFY',
    158: 'OP_NUMNOTEQUAL',
    159: 'OP_LESSTHAN',
    160: 'OP_GREATERTHAN',
    161: 'OP_LESSTHANOREQUAL',
    162: 'OP_GREATERTHANOREQUAL',
    163: 'OP_MIN',
    164: 'OP_MAX',
    165: 'OP_WITHIN',

    /// crypto
    166: 'OP_RIPEMD160',
    167: 'OP_SHA1',
    168: 'OP_SHA256',
    169: 'OP_HASH160',
    170: 'OP_HASH256',
    171: 'OP_CODESEPARATOR',
    172: 'OP_CHECKSIG',
    173: 'OP_CHECKSIGVERIFY',
    174: 'OP_CHECKMULTISIG',
    175: 'OP_CHECKMULTISIGVERIFY',

    /// locktime
    177: 'OP_NOP2',
    178: 'OP_NOP3',
    177: 'OP_CHECKLOCKTIMEVERIFY',
    178: 'OP_CHECKSEQUENCEVERIFY',
  };

  /// SIGHASH types
  static const int SIGHASH_SINGLE = 0x03;
  static const int SIGHASH_ANYONECANPAY = 0x80;
  static const int SIGHASH_ALL = 0x01;
  static const int SIGHASH_FORKED = 0x40;
  static const int SIGHASH_Test = 0x00000041;
  static const int SIGHASH_NONE = 0x02;
  static const int TAPROOT_SIGHASH_ALL = 0x00;

  /// Transaction lock types
  static const int TYPE_ABSOLUTE_TIMELOCK = 0x101;
  static const int TYPE_RELATIVE_TIMELOCK = 0x201;
  static const int TYPE_REPLACE_BY_FEE = 0x301;

  /// Default values and sequences
  static const List<int> DEFAULT_TX_LOCKTIME = [0x00, 0x00, 0x00, 0x00];
  static const List<int> EMPTY_TX_SEQUENCE = [0x00, 0x00, 0x00, 0x00];
  static const List<int> DEFAULT_TX_SEQUENCE = [0xff, 0xff, 0xff, 0xff];
  static const List<int> ABSOLUTE_TIMELOCK_SEQUENCE = [0xfe, 0xff, 0xff, 0xff];
  static const List<int> REPLACE_BY_FEE_SEQUENCE = [0x01, 0x00, 0x00, 0x00];

  /// Script version and Bitcoin-related identifiers
  static const int LEAF_VERSION_TAPSCRIPT = 0xc0;
  static const List<int> DEFAULT_TX_VERSION = [0x02, 0x00, 0x00, 0x00];
  static const int SATOSHIS_PER_BITCOIN = 100000000;
  static const int NEGATIVE_SATOSHI = -1;

  /// Bitcoin address types
  static const String P2PKH_ADDRESS = 'p2pkh';
  static const String P2SH_ADDRESS = 'p2sh';
  static const String P2WPKH_ADDRESS_V0 = 'p2wpkhv0';
  static const String P2WSH_ADDRESS_V0 = 'p2wshv0';
  static const String P2TR_ADDRESS_V1 = 'p2trv1';
}
