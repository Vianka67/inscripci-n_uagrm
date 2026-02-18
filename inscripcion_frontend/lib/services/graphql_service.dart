import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLService {
  // IP de tu computadora en la red WiFi (obtenida con 'ipconfig')
  static const String _localNetworkIp = '192.168.50.109';
  
  static String get _graphqlEndpoint {
    // Si es web (Chrome), usa localhost
    if (kIsWeb) {
      return 'http://localhost:8000/graphql/';
    }
    // Si es móvil, usa la IP de la red local
    return 'http://$_localNetworkIp:8000/graphql/';
  }

  static final HttpLink httpLink = HttpLink(_graphqlEndpoint);

  static ValueNotifier<GraphQLClient> initClient() {
    return ValueNotifier(
      GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(store: InMemoryStore()),
      ),
    );
  }
}
