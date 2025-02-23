import '../database.dart';

class ImagensTable extends SupabaseTable<ImagensRow> {
  @override
  String get tableName => 'imagens';

  @override
  ImagensRow createRow(Map<String, dynamic> data) => ImagensRow(data);
}

class ImagensRow extends SupabaseDataRow {
  ImagensRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ImagensTable();

  int get imagemId => getField<int>('imagem_id')!;
  set imagemId(int value) => setField<int>('imagem_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  List<String> get imagens => getListField<String>('imagens');
  set imagens(List<String>? value) => setListField<String>('imagens', value);

  int? get imagemPostId => getField<int>('imagem_post_id');
  set imagemPostId(int? value) => setField<int>('imagem_post_id', value);
}
