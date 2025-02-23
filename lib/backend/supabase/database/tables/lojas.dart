import '../database.dart';

class LojasTable extends SupabaseTable<LojasRow> {
  @override
  String get tableName => 'lojas';

  @override
  LojasRow createRow(Map<String, dynamic> data) => LojasRow(data);
}

class LojasRow extends SupabaseDataRow {
  LojasRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LojasTable();

  int get lojaId => getField<int>('loja_id')!;
  set lojaId(int value) => setField<int>('loja_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  int? get lojaNumero => getField<int>('loja_numero');
  set lojaNumero(int? value) => setField<int>('loja_numero', value);

  String? get lojaNome => getField<String>('loja_nome');
  set lojaNome(String? value) => setField<String>('loja_nome', value);

  String? get lojaPotencia => getField<String>('loja_potencia');
  set lojaPotencia(String? value) => setField<String>('loja_potencia', value);

  String? get lojaRito => getField<String>('loja_rito');
  set lojaRito(String? value) => setField<String>('loja_rito', value);

  DateTime? get lojaFundacao => getField<DateTime>('loja_fundacao');
  set lojaFundacao(DateTime? value) =>
      setField<DateTime>('loja_fundacao', value);

  String? get lojaDescricao => getField<String>('loja_descricao');
  set lojaDescricao(String? value) => setField<String>('loja_descricao', value);

  String? get lojaEndereco => getField<String>('loja_endereco');
  set lojaEndereco(String? value) => setField<String>('loja_endereco', value);

  String? get lojaEnderecoCidade => getField<String>('loja_endereco_cidade');
  set lojaEnderecoCidade(String? value) =>
      setField<String>('loja_endereco_cidade', value);

  String? get lojaEnderecoEstado => getField<String>('loja_endereco_estado');
  set lojaEnderecoEstado(String? value) =>
      setField<String>('loja_endereco_estado', value);

  String? get lojaEnderecoCodigoPostal =>
      getField<String>('loja_endereco_codigo_postal');
  set lojaEnderecoCodigoPostal(String? value) =>
      setField<String>('loja_endereco_codigo_postal', value);

  String? get lojaTelefone => getField<String>('loja_telefone');
  set lojaTelefone(String? value) => setField<String>('loja_telefone', value);

  String? get lojaEmail => getField<String>('loja_email');
  set lojaEmail(String? value) => setField<String>('loja_email', value);

  String? get lojaDiaSessao => getField<String>('loja_dia_sessao');
  set lojaDiaSessao(String? value) =>
      setField<String>('loja_dia_sessao', value);
}
