import 'dart:convert';
import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/provider/models/models.dart';
import 'package:bitcoin_base/src/provider/services/explorer.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class ApiProvider {
  ApiProvider({required this.api, Map<String, String>? header, required this.service})
      : _header = header ?? {'Content-Type': 'application/json'};
  factory ApiProvider.fromMempool(
    BasedUtxoNetwork network, {
    Map<String, String>? header,
    String? baseUrl,
  }) {
    final api = APIConfig.mempool(network, baseUrl);
    return ApiProvider(api: api, header: header, service: BitcoinApiService());
  }
  factory ApiProvider.fromBlocCypher(BasedUtxoNetwork network, ApiService service,
      {Map<String, String>? header}) {
    final api = APIConfig.fromBlockCypher(network);
    return ApiProvider(api: api, header: header, service: service);
  }
  final APIConfig api;
  final ApiService service;

  final Map<String, String> _header;

  Future<T> _getRequest<T>(String url, {Map<String, String> queryParameters = const {}}) async {
    if (queryParameters.isNotEmpty) {
      Uri uri = Uri.parse(url);
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParameters,
      });
      url = uri.normalizePath().toString();
    }
    final response = await service.get<T>(url);
    return response;
  }

  Future<T> _postRequest<T>(String url, Object? data) async {
    final response = await service.post<T>(url, body: data, headers: _header);
    return response;
  }

  Future<Map<String, dynamic>> testmempool(List<dynamic> params) async {
    final data = <String, dynamic>{
      'jsonrpc': '2.0',
      'method': 'testmempoolaccept',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'params': params
    };
    final response = await _postRequest<Map<String, dynamic>>(
        'https://btc.getblock.io/786c97b8-f53f-427b-80f7-9af7bd5bdb84/testnet/', json.encode(data));
    return response;
  }

  Future<List<UtxoWithAddress>> getAccountUtxo(UtxoAddressDetails owner,
      {String Function(String)? tokenize}) async {
    final apiUrl = api.getUtxoUrl(owner.address.toAddress(api.network));
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    final response = await _getRequest(url);
    switch (api.apiType) {
      case APIType.mempool:
        final utxos = (response as List).map((e) => MempolUtxo.fromJson(e)).toList();
        return utxos.toUtxoWithOwnerList(owner);
      default:
        final blockCypherUtxo = BlockCypherUtxo.fromJson(response);
        return blockCypherUtxo.toUtxoWithOwner(owner);
    }
  }

  Future<String> sendRawTransaction(String txDigest, {String Function(String)? tokenize}) async {
    final apiUrl = api.sendTransaction;
    final url = tokenize?.call(apiUrl) ?? apiUrl;

    switch (api.apiType) {
      case APIType.mempool:
        final response = await _postRequest<String>(url, txDigest);
        return response;
      default:
        final digestData = <String, dynamic>{'tx': txDigest};
        final response = await _postRequest<Map<String, dynamic>>(url, json.encode(digestData));
        BlockCypherTransaction? tr;
        if (response['tx'] != null) {
          tr = BlockCypherTransaction.fromJson(response['tx']);
        }

        tr ??= BlockCypherTransaction.fromJson(response);
        return tr.hash;
    }
  }

  Future<BitcoinFeeRate> getRecommendedFeeRate({String Function(String)? tokenize}) async {
    final apiUrl = api.getFeeApiUrl();
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    final response = await _getRequest<Map<String, dynamic>>(url);
    switch (api.apiType) {
      case APIType.mempool:
        return BitcoinFeeRate.fromMempool(response);
      default:
        return BitcoinFeeRate.fromBlockCypher(response);
    }
  }

  Future<T> getTransaction<T>(String transactionId, {String Function(String)? tokenize}) async {
    final apiUrl = api.getTransactionUrl(transactionId);
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    final response = await _getRequest<Map<String, dynamic>>(url);
    switch (api.apiType) {
      case APIType.mempool:
        return MempoolTransaction.fromJson(response) as T;
      default:
        return BlockCypherTransaction.fromJson(response) as T;
    }
  }

  Future<List<T>> getAccountTransactions<T>(String address,
      {String Function(String)? tokenize}) async {
    final apiUrl = api.getTransactionsUrl(address);
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    final response = await _getRequest(url);
    switch (api.apiType) {
      case APIType.mempool:
        final transactions =
            (response as List).map((e) => MempoolTransaction.fromJson(e) as T).toList();
        return transactions;
      default:
        if (response is Map) {
          if (response.containsKey('txs')) {
            final transactions = (response['txs'] as List)
                .map((e) => BlockCypherTransaction.fromJson(e) as T)
                .toList();
            return transactions;
          }
          return [];
        }
        final transactions =
            (response as List).map((e) => BlockCypherTransaction.fromJson(e) as T).toList();
        return transactions;
    }
  }

  Future<Map<String, dynamic>> getBlock(
    String blockHash, {
    String Function(String)? tokenize,
  }) async {
    final apiUrl = api.getBlockUrl(blockHash);
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    return await _getRequest<Map<String, dynamic>>(url);
  }

  Future<Map<String, dynamic>> getBlockTimestamp(
    DateTime date, {
    String Function(String)? tokenize,
  }) async {
    final apiUrl = api.getBlockTimestampUrl((date.millisecondsSinceEpoch / 1000).round());
    final url = tokenize?.call(apiUrl) ?? apiUrl;
    return await _getRequest<Map<String, dynamic>>(url);
  }

  Future<String> getBlockHeight(int height) async {
    final url = api.getBlockHeight(height);
    final response = await _getRequest<String>(url);
    switch (api.apiType) {
      case APIType.mempool:
        return response;
      default:
        final toJson = StringUtils.toJson<Map<String, dynamic>>(response);
        return toJson['hash'];
    }
  }

  Future<String> genesis() async {
    return getBlockHeight(0);
  }

  Future<BtcTransaction> getRawTransaction(String transactionId,
      {String Function(String)? tokenize}) async {
    final apiUrl = api.getRawTransactionUrl(transactionId);
    final url = tokenize?.call(apiUrl) ?? apiUrl;

    switch (api.apiType) {
      case APIType.mempool:
        final response = await _getRequest<String>(url);
        final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(response));
        assert(tx.serialize() == StringUtils.strip0x(response.toLowerCase()));
        return tx;
      default:
        final response =
            await _getRequest<Map<String, dynamic>>(url, queryParameters: {"includeHex": 'true'});
        final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(response["hex"]));
        assert(tx.serialize() == StringUtils.strip0x(response["hex"].toLowerCase()));
        return tx;
    }
  }
}
