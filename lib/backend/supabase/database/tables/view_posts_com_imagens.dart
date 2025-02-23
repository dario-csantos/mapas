import '../database.dart';

class ViewPostsComImagensTable extends SupabaseTable<ViewPostsComImagensRow> {
  @override
  String get tableName => 'view_posts_com_imagens';

  @override
  ViewPostsComImagensRow createRow(Map<String, dynamic> data) =>
      ViewPostsComImagensRow(data);
}

class ViewPostsComImagensRow extends SupabaseDataRow {
  ViewPostsComImagensRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewPostsComImagensTable();

  int? get postId => getField<int>('post_id');
  set postId(int? value) => setField<int>('post_id', value);

  String? get legenda => getField<String>('legenda');
  set legenda(String? value) => setField<String>('legenda', value);

  String? get titulo => getField<String>('titulo');
  set titulo(String? value) => setField<String>('titulo', value);

  DateTime? get dataPost => getField<DateTime>('data_post');
  set dataPost(DateTime? value) => setField<DateTime>('data_post', value);

  int? get imagemPostId => getField<int>('imagem_post_id');
  set imagemPostId(int? value) => setField<int>('imagem_post_id', value);

  String? get urlImagem => getField<String>('url_imagem');
  set urlImagem(String? value) => setField<String>('url_imagem', value);
}
