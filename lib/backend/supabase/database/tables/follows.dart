import '../database.dart';

class FollowsTable extends SupabaseTable<FollowsRow> {
  @override
  String get tableName => 'follows';

  @override
  FollowsRow createRow(Map<String, dynamic> data) => FollowsRow(data);
}

class FollowsRow extends SupabaseDataRow {
  FollowsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FollowsTable();

  int get followId => getField<int>('follow_id')!;
  set followId(int value) => setField<int>('follow_id', value);

  DateTime get followCreatedAt => getField<DateTime>('follow_created_at')!;
  set followCreatedAt(DateTime value) =>
      setField<DateTime>('follow_created_at', value);

  int? get followerSocioId => getField<int>('follower_socio_id');
  set followerSocioId(int? value) => setField<int>('follower_socio_id', value);

  int? get followedSocioId => getField<int>('followed_socio_id');
  set followedSocioId(int? value) => setField<int>('followed_socio_id', value);
}
