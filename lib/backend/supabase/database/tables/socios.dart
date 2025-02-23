import '../database.dart';

class SociosTable extends SupabaseTable<SociosRow> {
  @override
  String get tableName => 'socios';

  @override
  SociosRow createRow(Map<String, dynamic> data) => SociosRow(data);
}

class SociosRow extends SupabaseDataRow {
  SociosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SociosTable();

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  int get socioId => getField<int>('socio_id')!;
  set socioId(int value) => setField<int>('socio_id', value);

  String get socioCpf => getField<String>('socio_cpf')!;
  set socioCpf(String value) => setField<String>('socio_cpf', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get socioNome => getField<String>('socio_nome');
  set socioNome(String? value) => setField<String>('socio_nome', value);

  String? get socioApelido => getField<String>('socio_apelido');
  set socioApelido(String? value) => setField<String>('socio_apelido', value);

  String? get socioDtNascimento => getField<String>('socio_dt_nascimento');
  set socioDtNascimento(String? value) =>
      setField<String>('socio_dt_nascimento', value);

  String? get socioDtColetamento => getField<String>('socio_dt_coletamento');
  set socioDtColetamento(String? value) =>
      setField<String>('socio_dt_coletamento', value);

  String? get socioGrauMaconico => getField<String>('socio_grau_maconico');
  set socioGrauMaconico(String? value) =>
      setField<String>('socio_grau_maconico', value);

  String? get socioEmail => getField<String>('socio_email');
  set socioEmail(String? value) => setField<String>('socio_email', value);

  String? get socioTelefone1 => getField<String>('socio_telefone1');
  set socioTelefone1(String? value) =>
      setField<String>('socio_telefone1', value);

  String? get socioTelefone2 => getField<String>('socio_telefone2');
  set socioTelefone2(String? value) =>
      setField<String>('socio_telefone2', value);

  String? get socioEndereco => getField<String>('socio_endereco');
  set socioEndereco(String? value) => setField<String>('socio_endereco', value);

  String? get socioCidade => getField<String>('socio_cidade');
  set socioCidade(String? value) => setField<String>('socio_cidade', value);

  String? get socioEstado => getField<String>('socio_estado');
  set socioEstado(String? value) => setField<String>('socio_estado', value);

  String? get socioBairro => getField<String>('socio_bairro');
  set socioBairro(String? value) => setField<String>('socio_bairro', value);

  String? get socioCodigoPostal => getField<String>('socio_codigo_postal');
  set socioCodigoPostal(String? value) =>
      setField<String>('socio_codigo_postal', value);

  String? get socioPais => getField<String>('socio_pais');
  set socioPais(String? value) => setField<String>('socio_pais', value);

  String? get socioCnh => getField<String>('socio_cnh');
  set socioCnh(String? value) => setField<String>('socio_cnh', value);

  String? get socioCnhCategoria => getField<String>('socio_cnh_categoria');
  set socioCnhCategoria(String? value) =>
      setField<String>('socio_cnh_categoria', value);

  String? get socioProfissao => getField<String>('socio_profissao');
  set socioProfissao(String? value) =>
      setField<String>('socio_profissao', value);

  bool? get socioCasado => getField<bool>('socio_casado');
  set socioCasado(bool? value) => setField<bool>('socio_casado', value);

  String? get socioNomeEsposa => getField<String>('socio_nome_esposa');
  set socioNomeEsposa(String? value) =>
      setField<String>('socio_nome_esposa', value);

  DateTime? get socioEsposaDtNascimento =>
      getField<DateTime>('socio_esposa_dt_nascimento');
  set socioEsposaDtNascimento(DateTime? value) =>
      setField<DateTime>('socio_esposa_dt_nascimento', value);

  String? get socioEsposaDtTelefone =>
      getField<String>('socio_esposa_dt_telefone');
  set socioEsposaDtTelefone(String? value) =>
      setField<String>('socio_esposa_dt_telefone', value);

  String? get socioEsposaEmail => getField<String>('socio_esposa_email');
  set socioEsposaEmail(String? value) =>
      setField<String>('socio_esposa_email', value);

  String? get socioObs => getField<String>('socio_obs');
  set socioObs(String? value) => setField<String>('socio_obs', value);

  bool? get socioCoordenador => getField<bool>('socio_coordenador');
  set socioCoordenador(bool? value) =>
      setField<bool>('socio_coordenador', value);

  bool? get socioAdjunto => getField<bool>('socio_adjunto');
  set socioAdjunto(bool? value) => setField<bool>('socio_adjunto', value);

  bool? get socioSecretario => getField<bool>('socio_secretario');
  set socioSecretario(bool? value) => setField<bool>('socio_secretario', value);

  bool? get socioDirPresidente => getField<bool>('socio_dir_presidente');
  set socioDirPresidente(bool? value) =>
      setField<bool>('socio_dir_presidente', value);

  bool? get socioDirSecretario => getField<bool>('socio_dir_secretario');
  set socioDirSecretario(bool? value) =>
      setField<bool>('socio_dir_secretario', value);

  bool? get socioDirTesoureiro => getField<bool>('socio_dir_tesoureiro');
  set socioDirTesoureiro(bool? value) =>
      setField<bool>('socio_dir_tesoureiro', value);

  String? get socioSosPessoa1Nome => getField<String>('socio_sos_pessoa1_nome');
  set socioSosPessoa1Nome(String? value) =>
      setField<String>('socio_sos_pessoa1_nome', value);

  String? get socioSosPessoa1Telefone =>
      getField<String>('socio_sos_pessoa1_telefone');
  set socioSosPessoa1Telefone(String? value) =>
      setField<String>('socio_sos_pessoa1_telefone', value);

  String? get socioSosPessoa2Nome => getField<String>('socio_sos_pessoa2_nome');
  set socioSosPessoa2Nome(String? value) =>
      setField<String>('socio_sos_pessoa2_nome', value);

  String? get socioSosPessoa2Telefone =>
      getField<String>('socio_sos_pessoa2_telefone');
  set socioSosPessoa2Telefone(String? value) =>
      setField<String>('socio_sos_pessoa2_telefone', value);

  int? get socioLojaId => getField<int>('socio_loja_id');
  set socioLojaId(int? value) => setField<int>('socio_loja_id', value);

  String? get socioFatorRh => getField<String>('socio_fator_rh');
  set socioFatorRh(String? value) => setField<String>('socio_fator_rh', value);

  String? get socioImgPerfil => getField<String>('socio_img_perfil');
  set socioImgPerfil(String? value) =>
      setField<String>('socio_img_perfil', value);

  int? get socioUnidadeId => getField<int>('socio_unidade_id');
  set socioUnidadeId(int? value) => setField<int>('socio_unidade_id', value);

  String? get socioTextoPerfil => getField<String>('socio_texto_perfil');
  set socioTextoPerfil(String? value) =>
      setField<String>('socio_texto_perfil', value);
}
