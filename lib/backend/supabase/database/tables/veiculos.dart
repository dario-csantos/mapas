import '../database.dart';

class VeiculosTable extends SupabaseTable<VeiculosRow> {
  @override
  String get tableName => 'veiculos';

  @override
  VeiculosRow createRow(Map<String, dynamic> data) => VeiculosRow(data);
}

class VeiculosRow extends SupabaseDataRow {
  VeiculosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VeiculosTable();

  int get veiculoId => getField<int>('veiculo_id')!;
  set veiculoId(int value) => setField<int>('veiculo_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get veiculoTipo => getField<String>('veiculo_tipo');
  set veiculoTipo(String? value) => setField<String>('veiculo_tipo', value);

  String? get veiculoMarca => getField<String>('veiculo_marca');
  set veiculoMarca(String? value) => setField<String>('veiculo_marca', value);

  String? get veiculoModelo => getField<String>('veiculo_modelo');
  set veiculoModelo(String? value) => setField<String>('veiculo_modelo', value);

  int? get veiculoAno => getField<int>('veiculo_ano');
  set veiculoAno(int? value) => setField<int>('veiculo_ano', value);

  int? get veiculoCilindrada => getField<int>('veiculo_cilindrada');
  set veiculoCilindrada(int? value) =>
      setField<int>('veiculo_cilindrada', value);

  int? get veiculoQuilometragem => getField<int>('veiculo_quilometragem');
  set veiculoQuilometragem(int? value) =>
      setField<int>('veiculo_quilometragem', value);

  int? get veiculoSocioId => getField<int>('veiculo_socio_id');
  set veiculoSocioId(int? value) => setField<int>('veiculo_socio_id', value);

  String? get veiculoFoto => getField<String>('veiculo_foto');
  set veiculoFoto(String? value) => setField<String>('veiculo_foto', value);
}
