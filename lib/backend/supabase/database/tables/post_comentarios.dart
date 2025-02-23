import '../database.dart';

class PostComentariosTable extends SupabaseTable<PostComentariosRow> {
  @override
  String get tableName => 'post_comentarios';

  @override
  PostComentariosRow createRow(Map<String, dynamic> data) =>
      PostComentariosRow(data);
}

class PostComentariosRow extends SupabaseDataRow {
  PostComentariosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PostComentariosTable();

  int get comentarioId => getField<int>('comentario_id')!;
  set comentarioId(int value) => setField<int>('comentario_id', value);

  DateTime get comentarioCreatedAt =>
      getField<DateTime>('comentario_created_at')!;
  set comentarioCreatedAt(DateTime value) =>
      setField<DateTime>('comentario_created_at', value);

  int? get comentarioPostId => getField<int>('comentario_post_id');
  set comentarioPostId(int? value) =>
      setField<int>('comentario_post_id', value);

  int? get comentarioSocioId => getField<int>('comentario_socio_id');
  set comentarioSocioId(int? value) =>
      setField<int>('comentario_socio_id', value);

  String? get comentarioTexto => getField<String>('comentario_texto');
  set comentarioTexto(String? value) =>
      setField<String>('comentario_texto', value);
}
