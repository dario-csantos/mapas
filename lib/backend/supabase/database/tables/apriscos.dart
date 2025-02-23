import '../database.dart';

class ApriscosTable extends SupabaseTable<ApriscosRow> {
  @override
  String get tableName => 'apriscos';

  @override
  ApriscosRow createRow(Map<String, dynamic> data) => ApriscosRow(data);
}

class ApriscosRow extends SupabaseDataRow {
  ApriscosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ApriscosTable();

  int get apriscoId => getField<int>('aprisco_id')!;
  set apriscoId(int value) => setField<int>('aprisco_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  int? get apriscoUnidadeId => getField<int>('aprisco_unidade_id');
  set apriscoUnidadeId(int? value) =>
      setField<int>('aprisco_unidade_id', value);

  String? get apriscoTelefone => getField<String>('aprisco_telefone');
  set apriscoTelefone(String? value) =>
      setField<String>('aprisco_telefone', value);

  String? get apriscoEmail => getField<String>('aprisco_email');
  set apriscoEmail(String? value) => setField<String>('aprisco_email', value);

  String? get apriscoEndereco => getField<String>('aprisco_endereco');
  set apriscoEndereco(String? value) =>
      setField<String>('aprisco_endereco', value);

  String? get apriscoCidade => getField<String>('aprisco_cidade');
  set apriscoCidade(String? value) => setField<String>('aprisco_cidade', value);

  String? get apriscoEstado => getField<String>('aprisco_estado');
  set apriscoEstado(String? value) => setField<String>('aprisco_estado', value);

  String? get apriscoCodigoPostal => getField<String>('aprisco_codigo_postal');
  set apriscoCodigoPostal(String? value) =>
      setField<String>('aprisco_codigo_postal', value);

  String? get apriscoDescricao => getField<String>('aprisco_descricao');
  set apriscoDescricao(String? value) =>
      setField<String>('aprisco_descricao', value);

  String? get apriscoReunioes => getField<String>('aprisco_reunioes');
  set apriscoReunioes(String? value) =>
      setField<String>('aprisco_reunioes', value);
}
