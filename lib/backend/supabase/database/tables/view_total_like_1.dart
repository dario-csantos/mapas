import '../database.dart';

class ViewTotalLike1Table extends SupabaseTable<ViewTotalLike1Row> {
  @override
  String get tableName => 'view_total_like_1';

  @override
  ViewTotalLike1Row createRow(Map<String, dynamic> data) =>
      ViewTotalLike1Row(data);
}

class ViewTotalLike1Row extends SupabaseDataRow {
  ViewTotalLike1Row(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewTotalLike1Table();

  int? get postId => getField<int>('post_id');
  set postId(int? value) => setField<int>('post_id', value);

  int? get totalLikes => getField<int>('total_likes');
  set totalLikes(int? value) => setField<int>('total_likes', value);
}
