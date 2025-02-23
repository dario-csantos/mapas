import '../database.dart';

class UnidadesTable extends SupabaseTable<UnidadesRow> {
  @override
  String get tableName => 'unidades';

  @override
  UnidadesRow createRow(Map<String, dynamic> data) => UnidadesRow(data);
}

class UnidadesRow extends SupabaseDataRow {
  UnidadesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UnidadesTable();

  int get unidadeId => getField<int>('unidade_id')!;
  set unidadeId(int value) => setField<int>('unidade_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get unidadeNome => getField<String>('unidade_nome');
  set unidadeNome(String? value) => setField<String>('unidade_nome', value);

  String? get unidadeEndereco => getField<String>('unidade_endereco');
  set unidadeEndereco(String? value) =>
      setField<String>('unidade_endereco', value);

  String? get unidadeCidade => getField<String>('unidade_cidade');
  set unidadeCidade(String? value) => setField<String>('unidade_cidade', value);

  String? get unidadeUf => getField<String>('unidade_uf');
  set unidadeUf(String? value) => setField<String>('unidade_uf', value);

  String? get unidadeCep => getField<String>('unidade_cep');
  set unidadeCep(String? value) => setField<String>('unidade_cep', value);

  String? get unidadeLongitude => getField<String>('unidade_longitude');
  set unidadeLongitude(String? value) =>
      setField<String>('unidade_longitude', value);

  String? get unidadeLatitude => getField<String>('unidade_latitude');
  set unidadeLatitude(String? value) =>
      setField<String>('unidade_latitude', value);

  String? get unidadeAlfinete => getField<String>('unidade_alfinete');
  set unidadeAlfinete(String? value) =>
      setField<String>('unidade_alfinete', value);

  String? get unidadeIdCoordenador =>
      getField<String>('unidade_id_coordenador');
  set unidadeIdCoordenador(String? value) =>
      setField<String>('unidade_id_coordenador', value);

  String? get unidadeTelefone => getField<String>('unidade_telefone');
  set unidadeTelefone(String? value) =>
      setField<String>('unidade_telefone', value);

  String? get unidadeEmail => getField<String>('unidade_email');
  set unidadeEmail(String? value) => setField<String>('unidade_email', value);

  String? get unidadeFoto1 => getField<String>('unidade_foto1');
  set unidadeFoto1(String? value) => setField<String>('unidade_foto1', value);

  String? get unidadeFoto2 => getField<String>('unidade_foto2');
  set unidadeFoto2(String? value) => setField<String>('unidade_foto2', value);

  DateTime? get unidadeDtFundacao => getField<DateTime>('unidade_dt_fundacao');
  set unidadeDtFundacao(DateTime? value) =>
      setField<DateTime>('unidade_dt_fundacao', value);

  String? get unidadeHistoria => getField<String>('unidade_historia');
  set unidadeHistoria(String? value) =>
      setField<String>('unidade_historia', value);
}
