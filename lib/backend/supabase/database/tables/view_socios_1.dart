import '../database.dart';

class ViewSocios1Table extends SupabaseTable<ViewSocios1Row> {
  @override
  String get tableName => 'view_socios_1';

  @override
  ViewSocios1Row createRow(Map<String, dynamic> data) => ViewSocios1Row(data);
}

class ViewSocios1Row extends SupabaseDataRow {
  ViewSocios1Row(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewSocios1Table();

  int? get socioId => getField<int>('socio_id');
  set socioId(int? value) => setField<int>('socio_id', value);

  String? get socioNome => getField<String>('socio_nome');
  set socioNome(String? value) => setField<String>('socio_nome', value);

  String? get socioApelido => getField<String>('socio_apelido');
  set socioApelido(String? value) => setField<String>('socio_apelido', value);

  String? get socioEmail => getField<String>('socio_email');
  set socioEmail(String? value) => setField<String>('socio_email', value);

  String? get socioTelefone1 => getField<String>('socio_telefone1');
  set socioTelefone1(String? value) =>
      setField<String>('socio_telefone1', value);

  int? get socioUnidadeId => getField<int>('socio_unidade_id');
  set socioUnidadeId(int? value) => setField<int>('socio_unidade_id', value);

  String? get socioImgPerfil => getField<String>('socio_img_perfil');
  set socioImgPerfil(String? value) =>
      setField<String>('socio_img_perfil', value);

  String? get subsede => getField<String>('subsede');
  set subsede(String? value) => setField<String>('subsede', value);

  String? get socioTextoPerfil => getField<String>('socio_texto_perfil');
  set socioTextoPerfil(String? value) =>
      setField<String>('socio_texto_perfil', value);
}
