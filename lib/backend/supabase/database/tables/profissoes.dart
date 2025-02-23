import '../database.dart';

class ProfissoesTable extends SupabaseTable<ProfissoesRow> {
  @override
  String get tableName => 'profissoes';

  @override
  ProfissoesRow createRow(Map<String, dynamic> data) => ProfissoesRow(data);
}

class ProfissoesRow extends SupabaseDataRow {
  ProfissoesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProfissoesTable();

  String get profissaoId => getField<String>('profissao_id')!;
  set profissaoId(String value) => setField<String>('profissao_id', value);

  String? get profissaoDescricao => getField<String>('profissao_descricao');
  set profissaoDescricao(String? value) =>
      setField<String>('profissao_descricao', value);
}
