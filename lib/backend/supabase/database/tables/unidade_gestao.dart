import '../database.dart';

class UnidadeGestaoTable extends SupabaseTable<UnidadeGestaoRow> {
  @override
  String get tableName => 'unidade_gestao';

  @override
  UnidadeGestaoRow createRow(Map<String, dynamic> data) =>
      UnidadeGestaoRow(data);
}

class UnidadeGestaoRow extends SupabaseDataRow {
  UnidadeGestaoRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UnidadeGestaoTable();

  int get unidDirId => getField<int>('unid_dir_id')!;
  set unidDirId(int value) => setField<int>('unid_dir_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  int? get unidId => getField<int>('unid_id');
  set unidId(int? value) => setField<int>('unid_id', value);

  String? get unidAnoGestao => getField<String>('unid_ano_gestao');
  set unidAnoGestao(String? value) =>
      setField<String>('unid_ano_gestao', value);

  DateTime? get unidDtPosse => getField<DateTime>('unid_dt_posse');
  set unidDtPosse(DateTime? value) =>
      setField<DateTime>('unid_dt_posse', value);

  int? get unidIdCoordenador => getField<int>('unid_id_coordenador');
  set unidIdCoordenador(int? value) =>
      setField<int>('unid_id_coordenador', value);

  int? get unidIdAdjunto => getField<int>('unid_id_adjunto');
  set unidIdAdjunto(int? value) => setField<int>('unid_id_adjunto', value);

  int? get unidIdSecretario => getField<int>('unid_id_secretario');
  set unidIdSecretario(int? value) =>
      setField<int>('unid_id_secretario', value);
}
