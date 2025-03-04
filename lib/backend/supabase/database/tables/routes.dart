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
}
