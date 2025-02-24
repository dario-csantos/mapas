import '../database.dart';

class ViewLocationsTable extends SupabaseTable<ViewLocationsRow> {
  @override
  String get tableName => 'view_locations';

  @override
  ViewLocationsRow createRow(Map<String, dynamic> data) =>
      ViewLocationsRow(data);
}

class ViewLocationsRow extends SupabaseDataRow {
  ViewLocationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewLocationsTable();

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);

  bool? get customers => getField<bool>('customers');
  set customers(bool? value) => setField<bool>('customers', value);

  bool? get driverStatus => getField<bool>('driver_status');
  set driverStatus(bool? value) => setField<bool>('driver_status', value);
}
