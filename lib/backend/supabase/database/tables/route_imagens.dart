import '../database.dart';

class RouteImagensTable extends SupabaseTable<RouteImagensRow> {
  @override
  String get tableName => 'route_imagens';

  @override
  RouteImagensRow createRow(Map<String, dynamic> data) => RouteImagensRow(data);
}

class RouteImagensRow extends SupabaseDataRow {
  RouteImagensRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RouteImagensTable();

  int get routeImagemId => getField<int>('route_imagem_id')!;
  set routeImagemId(int value) => setField<int>('route_imagem_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  int? get routeId => getField<int>('route_id');
  set routeId(int? value) => setField<int>('route_id', value);

  String? get routeImagemUrl => getField<String>('route_imagem_url');
  set routeImagemUrl(String? value) =>
      setField<String>('route_imagem_url', value);
}
