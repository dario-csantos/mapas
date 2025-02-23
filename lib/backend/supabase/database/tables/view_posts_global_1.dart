import '../database.dart';

class ViewPostsGlobal1Table extends SupabaseTable<ViewPostsGlobal1Row> {
  @override
  String get tableName => 'view_posts_global_1';

  @override
  ViewPostsGlobal1Row createRow(Map<String, dynamic> data) =>
      ViewPostsGlobal1Row(data);
}

class ViewPostsGlobal1Row extends SupabaseDataRow {
  ViewPostsGlobal1Row(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewPostsGlobal1Table();

  int? get postId => getField<int>('post_id');
  set postId(int? value) => setField<int>('post_id', value);

  String? get legenda => getField<String>('legenda');
  set legenda(String? value) => setField<String>('legenda', value);

  String? get titulo => getField<String>('titulo');
  set titulo(String? value) => setField<String>('titulo', value);

  DateTime? get dataPost => getField<DateTime>('data_post');
  set dataPost(DateTime? value) => setField<DateTime>('data_post', value);

  int? get socioId => getField<int>('socio_id');
  set socioId(int? value) => setField<int>('socio_id', value);

  String? get socioNome => getField<String>('socio_nome');
  set socioNome(String? value) => setField<String>('socio_nome', value);

  String? get socioTextoPerfil => getField<String>('socio_texto_perfil');
  set socioTextoPerfil(String? value) =>
      setField<String>('socio_texto_perfil', value);

  String? get socioApelido => getField<String>('socio_apelido');
  set socioApelido(String? value) => setField<String>('socio_apelido', value);

  String? get socioEmail => getField<String>('socio_email');
  set socioEmail(String? value) => setField<String>('socio_email', value);

  int? get socioUnidadeId => getField<int>('socio_unidade_id');
  set socioUnidadeId(int? value) => setField<int>('socio_unidade_id', value);

  String? get socioImgPerfil => getField<String>('socio_img_perfil');
  set socioImgPerfil(String? value) =>
      setField<String>('socio_img_perfil', value);

  String? get subsede => getField<String>('subsede');
  set subsede(String? value) => setField<String>('subsede', value);
}
