import '../database.dart';

class ViewLocationsDistinctOrderedTable
    extends SupabaseTable<ViewLocationsDistinctOrderedRow> {
  @override
  String get tableName => 'view_locations_distinct_ordered';

  @override
  ViewLocationsDistinctOrderedRow createRow(Map<String, dynamic> data) =>
      ViewLocationsDistinctOrderedRow(data);
}

class ViewLocationsDistinctOrderedRow extends SupabaseDataRow {
  ViewLocationsDistinctOrderedRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewLocationsDistinctOrderedTable();

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get location => getField<String>('location');
  set location(String? value) => setField<String>('location', value);
}
