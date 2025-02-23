import '../database.dart';

class PostsTable extends SupabaseTable<PostsRow> {
  @override
  String get tableName => 'posts';

  @override
  PostsRow createRow(Map<String, dynamic> data) => PostsRow(data);
}

class PostsRow extends SupabaseDataRow {
  PostsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PostsTable();

  int get postId => getField<int>('post_id')!;
  set postId(int value) => setField<int>('post_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  int? get postSocioId => getField<int>('post_socio_id');
  set postSocioId(int? value) => setField<int>('post_socio_id', value);

  String? get postTexto => getField<String>('post_texto');
  set postTexto(String? value) => setField<String>('post_texto', value);

  List<int> get postLike => getListField<int>('post_like');
  set postLike(List<int>? value) => setListField<int>('post_like', value);

  String? get postTitulo => getField<String>('post_titulo');
  set postTitulo(String? value) => setField<String>('post_titulo', value);
}
