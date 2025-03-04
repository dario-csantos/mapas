import '../database.dart';

class TrakingDriverTable extends SupabaseTable<TrakingDriverRow> {
  @override
  String get tableName => 'trakingDriver';

  @override
  TrakingDriverRow createRow(Map<String, dynamic> data) =>
      TrakingDriverRow(data);
}

class TrakingDriverRow extends SupabaseDataRow {
  TrakingDriverRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TrakingDriverTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);

  bool? get driver => getField<bool>('driver');
  set driver(bool? value) => setField<bool>('driver', value);

  bool? get castomer => getField<bool>('castomer');
  set castomer(bool? value) => setField<bool>('castomer', value);

  bool? get status => getField<bool>('status');
  set status(bool? value) => setField<bool>('status', value);

  String? get userRef => getField<String>('userRef');
  set userRef(String? value) => setField<String>('userRef', value);

  int? get socioId => getField<int>('socio_id');
  set socioId(int? value) => setField<int>('socio_id', value);

  double? get kmh => getField<double>('kmh');
  set kmh(double? value) => setField<double>('kmh', value);

  DateTime? get timestamp => getField<DateTime>('timestamp');
  set timestamp(DateTime? value) => setField<DateTime>('timestamp', value);
}
