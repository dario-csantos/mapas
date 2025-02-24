import '../database.dart';

class ViewTrajetoTable extends SupabaseTable<ViewTrajetoRow> {
  @override
  String get tableName => 'view_trajeto';

  @override
  ViewTrajetoRow createRow(Map<String, dynamic> data) => ViewTrajetoRow(data);
}

class ViewTrajetoRow extends SupabaseDataRow {
  ViewTrajetoRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewTrajetoTable();

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);

  String? get previousLocation => getField<String>('previous_location');
  set previousLocation(String? value) =>
      setField<String>('previous_location', value);
}
