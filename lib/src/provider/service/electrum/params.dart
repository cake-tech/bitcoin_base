import 'package:blockchain_utils/blockchain_utils.dart';

/// Abstract class representing parameters for Electrum requests.
abstract class BaseElectrumRequestParams {
  abstract final String method;
}

abstract class ElectrumRequestParams implements BaseElectrumRequestParams {
  List<dynamic> toParams();
}

/// Represents details of an Electrum request, including id, method, and parameters.
abstract class BaseElectrumRequestDetails {
  const BaseElectrumRequestDetails({required this.method, required this.params});

  final String method;
  final dynamic params;

  List<int> toTCPParams();
  List<int> toWebSocketParams();
}

class ElectrumRequestDetails implements BaseElectrumRequestDetails {
  const ElectrumRequestDetails({
    required this.id,
    required this.method,
    required this.params,
  });

  final int id;
  @override
  final String method;

  @override
  final Map<String, dynamic> params;

  @override
  List<int> toTCPParams() {
    final param = "${StringUtils.fromJson(params)}\n";
    return StringUtils.encode(param);
  }

  @override
  List<int> toWebSocketParams() {
    return StringUtils.encode(StringUtils.fromJson(params));
  }
}

/// Abstract class representing an Electrum request with generic result and response types.
abstract class BaseElectrumRequest<RESULT, RESPONSE> implements BaseElectrumRequestParams {
  String? get validate => null;

  BaseElectrumRequestDetails toRequest(int requestId);
}

abstract class ElectrumRequest<RESULT, RESPONSE> extends BaseElectrumRequest<RESULT, RESPONSE>
    implements ElectrumRequestParams {
  RESULT onResponse(RESPONSE result) {
    return result as RESULT;
  }

  @override
  ElectrumRequestDetails toRequest(int requestId) {
    final params = toParams();
    params.removeWhere((v) => v == null);
    final json = {
      "jsonrpc": "2.0",
      "method": method,
      "params": params,
      "id": requestId,
    };
    return ElectrumRequestDetails(id: requestId, params: json, method: method);
  }
}

abstract class ElectrumBatchRequestParams implements BaseElectrumRequestParams {
  List<List<dynamic>> toParams();
}

class ElectrumBatchRequestDetails implements BaseElectrumRequestDetails {
  const ElectrumBatchRequestDetails({
    required this.paramsById,
    required this.method,
    required this.params,
  });

  final Map<int, List<dynamic>> paramsById;

  @override
  final String method;

  @override
  final List<Map<String, dynamic>> params;

  @override
  List<int> toTCPParams() {
    final param = "${StringUtils.fromJson(params)}\n";
    return StringUtils.encode(param);
  }

  @override
  List<int> toWebSocketParams() {
    return StringUtils.encode(StringUtils.fromJson(params));
  }
}

class ElectrumBatchRequestResult<RESULT> {
  final ElectrumBatchRequestDetails request;
  final RESULT result;
  final int id;

  List<dynamic>? get paramForRequest => request.paramsById[id];

  ElectrumBatchRequestResult({
    required this.request,
    required this.id,
    required this.result,
  });
}

abstract class ElectrumBatchRequest<RESULT, RESPONSE> extends BaseElectrumRequest<RESULT, RESPONSE>
    implements ElectrumBatchRequestParams {
  ElectrumBatchRequestResult<RESULT> onResponse(
    RESPONSE result,
    ElectrumBatchRequestDetails request,
  ) {
    throw UnimplementedError();
  }

  int finalId = 0;

  @override
  BaseElectrumRequestDetails toRequest(int requestId) {
    List<List<dynamic>> params = toParams();
    final paramsById = <int, List<dynamic>>{};

    final json = params.map((e) {
      final json = {
        "jsonrpc": "2.0",
        "method": method,
        "params": e,
        "id": requestId,
      };
      paramsById[requestId] = e;

      requestId++;
      return json;
    }).toList();

    finalId = requestId;

    return ElectrumBatchRequestDetails(paramsById: paramsById, params: json, method: method);
  }
}
