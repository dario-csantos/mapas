import '../database.dart';

class LikesTable extends SupabaseTable<LikesRow> {
  @override
  String get tableName => 'likes';

  @override
  LikesRow createRow(Map<String, dynamic> data) => LikesRow(data);
}

class LikesRow extends SupabaseDataRow {
  LikesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LikesTable();

  int get likeId => getField<int>('like_id')!;
  set likeId(int value) => setField<int>('like_id', value);

  DateTime get likeCreatedAt => getField<DateTime>('like_created_at')!;
  set likeCreatedAt(DateTime value) =>
      setField<DateTime>('like_created_at', value);

  int? get likePostId => getField<int>('like_post_id');
  set likePostId(int? value) => setField<int>('like_post_id', value);

  int? get likeSocioId => getField<int>('like_socio_id');
  set likeSocioId(int? value) => setField<int>('like_socio_id', value);
}
