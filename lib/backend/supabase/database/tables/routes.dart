import '../database.dart';

class RoutesTable extends SupabaseTable<RoutesRow> {
  @override
  String get tableName => 'routes';

  @override
  RoutesRow createRow(Map<String, dynamic> data) => RoutesRow(data);
}

class RoutesRow extends SupabaseDataRow {
  RoutesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RoutesTable();

  int get routeId => getField<int>('route_id')!;
  set routeId(int value) => setField<int>('route_id', value);

  int get socioId => getField<int>('socio_id')!;
  set socioId(int value) => setField<int>('socio_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  double? get avgSpeed => getField<double>('avg_speed');
  set avgSpeed(double? value) => setField<double>('avg_speed', value);

  int? get totalDuration => getField<int>('total_duration');
  set totalDuration(int? value) => setField<int>('total_duration', value);

  double? get totalDistance => getField<double>('total_distance');
  set totalDistance(double? value) => setField<double>('total_distance', value);

  String? get region => getField<String>('region');
  set region(String? value) => setField<String>('region', value);

  bool? get florestaSn => getField<bool>('floresta_sn');
  set florestaSn(bool? value) => setField<bool>('floresta_sn', value);

  bool? get costaSn => getField<bool>('costa_sn');
  set costaSn(bool? value) => setField<bool>('costa_sn', value);

  bool? get offRoadSn => getField<bool>('off_road_sn');
  set offRoadSn(bool? value) => setField<bool>('off_road_sn', value);

  bool? get cidadeSn => getField<bool>('cidade_sn');
  set cidadeSn(bool? value) => setField<bool>('cidade_sn', value);

  bool? get montanhaSn => getField<bool>('montanha_sn');
  set montanhaSn(bool? value) => setField<bool>('montanha_sn', value);

  bool? get curvasSn => getField<bool>('curvas_sn');
  set curvasSn(bool? value) => setField<bool>('curvas_sn', value);

  int? get diversao => getField<int>('diversao');
  set diversao(int? value) => setField<int>('diversao', value);

  int? get cenario => getField<int>('cenario');
  set cenario(int? value) => setField<int>('cenario', value);

  int? get condicaoEstrada => getField<int>('condicao_estrada');
  set condicaoEstrada(int? value) => setField<int>('condicao_estrada', value);

  bool? get rotaPrivadaSn => getField<bool>('rota_privada_sn');
  set rotaPrivadaSn(bool? value) => setField<bool>('rota_privada_sn', value);
}
