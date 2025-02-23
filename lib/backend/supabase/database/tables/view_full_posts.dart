import '../database.dart';

class ViewFullPostsTable extends SupabaseTable<ViewFullPostsRow> {
  @override
  String get tableName => 'view_full_posts';

  @override
  ViewFullPostsRow createRow(Map<String, dynamic> data) =>
      ViewFullPostsRow(data);
}

class ViewFullPostsRow extends SupabaseDataRow {
  ViewFullPostsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewFullPostsTable();

  int? get postId => getField<int>('post_id');
  set postId(int? value) => setField<int>('post_id', value);

  String? get postTexto => getField<String>('post_texto');
  set postTexto(String? value) => setField<String>('post_texto', value);

  DateTime? get postCreatedAt => getField<DateTime>('post_created_at');
  set postCreatedAt(DateTime? value) =>
      setField<DateTime>('post_created_at', value);

  int? get socioId => getField<int>('socio_id');
  set socioId(int? value) => setField<int>('socio_id', value);

  String? get socioNome => getField<String>('socio_nome');
  set socioNome(String? value) => setField<String>('socio_nome', value);

  DateTime? get socioCreatedAt => getField<DateTime>('socio_created_at');
  set socioCreatedAt(DateTime? value) =>
      setField<DateTime>('socio_created_at', value);

  int? get imagemId => getField<int>('imagem_id');
  set imagemId(int? value) => setField<int>('imagem_id', value);

  List<String> get imagens => getListField<String>('imagens');
  set imagens(List<String>? value) => setListField<String>('imagens', value);

  DateTime? get imagemCreatedAt => getField<DateTime>('imagem_created_at');
  set imagemCreatedAt(DateTime? value) =>
      setField<DateTime>('imagem_created_at', value);
}
