import '../database.dart';

class RoutePointsTable extends SupabaseTable<RoutePointsRow> {
  @override
  String get tableName => 'route_points';

  @override
  RoutePointsRow createRow(Map<String, dynamic> data) => RoutePointsRow(data);
}

class RoutePointsRow extends SupabaseDataRow {
  RoutePointsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RoutePointsTable();

  int get routePointId => getField<int>('route_point_id')!;
  set routePointId(int value) => setField<int>('route_point_id', value);

  int? get routeId => getField<int>('route_id');
  set routeId(int? value) => setField<int>('route_id', value);

  double? get latitude => getField<double>('latitude');
  set latitude(double? value) => setField<double>('latitude', value);

  double? get longitude => getField<double>('longitude');
  set longitude(double? value) => setField<double>('longitude', value);

  double? get speed => getField<double>('speed');
  set speed(double? value) => setField<double>('speed', value);

  String? get timestamp => getField<String>('timestamp');
  set timestamp(String? value) => setField<String>('timestamp', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
