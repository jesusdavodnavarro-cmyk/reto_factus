class Consumo {
  final double valor;
  final String unidad; // 'COP' o 'kWh'

  Consumo({required this.valor, required this.unidad});

  factory Consumo.fromJson(Map<String, dynamic> json) =>
      Consumo(valor: (json['valor'] as num).toDouble(), unidad: json['unidad']);

  Map<String, dynamic> toJson() => {'valor': valor, 'unidad': unidad};
}

class Contacto {
  final String nombre;
  final String email;
  final String telefono;

  Contacto({required this.nombre, required this.email, required this.telefono});

  factory Contacto.fromJson(Map<String, dynamic> json) => Contacto(
    nombre: json['nombre'],
    email: json['email'],
    telefono: json['telefono'],
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'email': email,
    'telefono': telefono,
  };
}

class Facturacion {
  final String tipoPersona; // 'natural' o 'juridica'
  final String tipoDocumento; // 'CC', 'NIT', etc.
  final String numeroDocumento;
  final String direccion;
  final String email;
  final String telefono;

  // Campos opcionales dependiendo de si es Pyme o Persona Natural
  final String? nombres;
  final String? razonSocial;
  final String? dv;
  final String? municipioCodigo;

  Facturacion({
    required this.tipoPersona,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.direccion,
    required this.email,
    required this.telefono,
    this.nombres,
    this.razonSocial,
    this.dv,
    this.municipioCodigo,
  });

  factory Facturacion.fromJson(Map<String, dynamic> json) => Facturacion(
    tipoPersona: json['tipoPersona'],
    tipoDocumento: json['tipoDocumento'],
    numeroDocumento: json['numeroDocumento'],
    direccion: json['direccion'],
    email: json['email'],
    telefono: json['telefono'],
    nombres: json['nombres'],
    razonSocial: json['razonSocial'],
    dv: json['dv'],
    municipioCodigo: json['municipioCodigo'],
  );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'tipoPersona': tipoPersona,
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
      'direccion': direccion,
      'email': email,
      'telefono': telefono,
    };

    // Solo enviamos al backend los campos que no sean nulos
    if (nombres != null) data['nombres'] = nombres;
    if (razonSocial != null) data['razonSocial'] = razonSocial;
    if (dv != null) data['dv'] = dv;
    if (municipioCodigo != null) data['municipioCodigo'] = municipioCodigo;

    return data;
  }
}

class InformeSolarEntity {
  final String? id; // Ejemplo: SOL-001 (Lo asigna el backend al consultar)
  final Consumo consumo;
  final double presupuestoCop;
  final double areaDisponibleM2;
  final Contacto contacto;
  final Facturacion facturacion;

  InformeSolarEntity({
    this.id,
    required this.consumo,
    required this.presupuestoCop,
    required this.areaDisponibleM2,
    required this.contacto,
    required this.facturacion,
  });

  factory InformeSolarEntity.fromJson(Map<String, dynamic> json) {
    return InformeSolarEntity(
      id: json['id'],
      consumo: Consumo.fromJson(json['consumo']),
      presupuestoCop: (json['presupuestoCop'] as num).toDouble(),
      areaDisponibleM2: (json['areaDisponibleM2'] as num).toDouble(),
      contacto: Contacto.fromJson(json['contacto']),
      facturacion: Facturacion.fromJson(json['facturacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // El id no se envía en el POST, se obvia
      'consumo': consumo.toJson(),
      'presupuestoCop': presupuestoCop,
      'areaDisponibleM2': areaDisponibleM2,
      'contacto': contacto.toJson(),
      'facturacion': facturacion.toJson(),
    };
  }
}
