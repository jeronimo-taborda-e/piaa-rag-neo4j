// =====================================================
// 002_example_data.cypher — Datos de ejemplo (un nodo por etiqueta)
// Ejecutar DESPUÉS de 001_schema.cypher. Se puede repetir sin problema (MERGE).
// Los vectores (embedding, embedding_clip) los calcula la ingesta en Python
// con MiniLM (384) y CLIP (512) y se validan con validation/models.py.
// =====================================================

// ---------- Estructura académica ----------
MERGE (dep:Departamento {codigo: "DEP-SIS"})  SET dep.nombre = "Departamento de Sistemas"
MERGE (fac:Facultad {codigo: "FING"})         SET fac.nombre = "Facultad de Ingeniería"
MERGE (prog:Programa {codigo: "ISIS"})        SET prog.nombre = "Ingeniería de Sistemas"
MERGE (act:ActividadAcademica {codigo: "ISIS-204"})
  SET act.nombre = "Bases de Datos", act.semestre = 4, act.creditos = 3
MERGE (fac)-[:TIENE]->(prog)
MERGE (prog)-[:TIENE]->(act)
MERGE (dep)-[:OFERTA]->(act)

// ---------- PIAA y versiones ----------
MERGE (piaa:PIAA {codigo: "PIAA-ISIS-204"})
  SET piaa.estado = "VIGENTE", piaa.origen = "migracion", piaa.completitud = 0.9
MERGE (v1:Version {id: "PIAA-ISIS-204-v1"})
  SET v1.numero = 1, v1.estado = "VIGENTE", v1.es_publica = true,
      v1.fecha = date("2026-01-15"), v1.idioma = "es",
      v1.creada_en = date("2025-11-20"), v1.aprobada_en = date("2026-01-15"),
      v1.fuente = "PIAS/2026/01/S03/ISIS-204/PIAA-ISIS-204.pdf",
      v1.hash = "sha256:3f9a1c0e7b2d4a6f8e1c5b9d0a7e3f2c4b6d8a1e9f0c3b5d7a2e4f6c8b0d1a3e"
MERGE (v2:Version {id: "PIAA-ISIS-204-v2"})
  SET v2.numero = 2, v2.estado = "BORRADOR", v2.es_publica = false,
      v2.fecha = date("2026-10-15"), v2.idioma = "es",
      v2.creada_en = date("2026-10-15")
MERGE (piaa)-[:PROGRAMA_DE]->(act)
MERGE (piaa)-[:TIENE_VERSION]->(v1)
MERGE (piaa)-[:TIENE_VERSION]->(v2)
MERGE (piaa)-[:VIGENTE]->(v1)

// ---------- Contenido: secciones y fragmentos ----------
MERGE (sec:Seccion {id: "PIAA-ISIS-204-v1-contenidos"})
  SET sec.tipo = "contenidos", sec.titulo_original = "Contenidos", sec.orden = 3,
      sec.texto = "1. Modelo relacional y álgebra relacional. 2. Lenguaje SQL: DDL, DML y consultas. 3. Normalización hasta tercera forma normal. 4. Transacciones y control de concurrencia."
MERGE (frag:Fragmento {id: "PIAA-ISIS-204-v1-contenidos-0"})
  SET frag.chunk_index = 0,
      frag.estrategia_chunking = "sentence-aware",
      frag.texto = "Modelo relacional y álgebra relacional. Lenguaje SQL: DDL, DML y consultas.",
      frag.texto_con_contexto = "Facultad de Ingeniería > Ingeniería de Sistemas > Bases de Datos > Contenidos. Modelo relacional y álgebra relacional. Lenguaje SQL: DDL, DML y consultas.",
      frag.idioma = "es",
      frag.modelo_embedding = "paraphrase-multilingual-MiniLM-L12-v2",
      frag.version_embedding = 1,
      frag.modelo_embedding_clip = "clip-ViT-B-32-multilingual-v1",
      frag.fecha_ingesta = date("2026-10-19")
MERGE (v1)-[:TIENE_SECCION]->(sec)
MERGE (sec)-[:TIENE_FRAGMENTO]->(frag)

// ---------- Imágenes ----------
// El embedding_clip se calcula sobre el contenido visual del archivo, no sobre la ruta.
MERGE (img:Imagen {id: "IMG-ISIS-204-0001"})
  SET img.ruta_archivo = "PIAS/2026/01/S03/ISIS-204/diagrama_er.png",
      img.formato = "png",
      img.descripcion = "Diagrama entidad-relación del caso de estudio de la asignatura",
      img.etiquetas = ["diagrama", "entidad-relacion", "modelado"],
      img.requirio_ocr = false,
      img.modelo_embedding = "clip-ViT-B-32",
      img.version_embedding = 1,
      img.fecha_ingesta = date("2026-10-19")
MERGE (sec)-[:TIENE_IMAGEN]->(img)

// ---------- Personas y órganos ----------
MERGE (prof:Persona {id: "P-001"})  SET prof.nombre = "Ana Pérez",  prof.roles = ["PROFESOR"]
MERGE (dec:Persona  {id: "P-002"})  SET dec.nombre  = "Luis Gómez", dec.roles  = ["DECANO"]
MERGE (comite:ComiteCurriculo {id: "CC-FING"})   SET comite.nombre = "Comité de Currículo FING"
MERGE (cfac:ConsejoFacultad {id: "CF-FING"})     SET cfac.nombre = "Consejo de Facultad FING"
MERGE (cacad:ConsejoAcademico {id: "CA-1"})      SET cacad.nombre = "Consejo Académico"
MERGE (pol:PoliticaCurricular {id: "POL-1"})     SET pol.nombre = "Política Curricular"
MERGE (prof)-[:AUTOR_DE]->(piaa)
MERGE (prof)-[:MIEMBRO_DE]->(comite)
MERGE (dec)-[:PRESIDE]->(cfac)
MERGE (dec)-[:DIRIGE]->(fac)
MERGE (dec)-[:MIEMBRO_DE]->(cacad)
MERGE (cacad)-[:ACTUALIZA]->(pol)

// ---------- Solicitud y aprobaciones ----------
MERGE (sol:Solicitud {id: "SOL-0001"})
  SET sol.estado = "EN_REVISION_COMITE", sol.creada_en = date("2026-10-15")
MERGE (g1:Aprobacion {id: "APR-0001"})  SET g1.nivel = "COMITE", g1.estado = "PENDIENTE"
MERGE (g2:Aprobacion {id: "APR-0002"})  SET g2.nivel = "CONSEJO_FACULTAD", g2.estado = "PENDIENTE"
MERGE (prof)-[:ENVIA]->(sol)
MERGE (sol)-[:PROPONE_CAMBIO_A]->(piaa)
MERGE (sol)-[:PROPONE]->(v2)
MERGE (comite)-[:RECOMIENDA]->(g1)
MERGE (cfac)-[:DECIDE]->(g2)
MERGE (g1)-[:SOBRE]->(sol)
MERGE (g2)-[:SOBRE]->(sol)
MERGE (g2)-[:REQUIERE_RECOMENDACION_PREVIA]->(g1)

// ---------- Trámite de registro (sobre la versión aprobada) ----------
MERGE (ofcal:OficinaEvaluacionCalidad {id: "OEC"})
MERGE (ofadm:OficinaAdmisionesRegistro {id: "OAR"})
MERGE (tr:TramiteRegistro {id: "TR-0001"})  SET tr.reporta_men = true
MERGE (ofcal)-[:TRAMITA]->(tr)
MERGE (ofadm)-[:AUTORIZA]->(tr)
MERGE (tr)-[:SOBRE]->(v1)

// ---------- Hallazgos de la IA ----------
MERGE (reg:Regla {codigo: "REG-01"})
  SET reg.descripcion = "Los objetivos deben ser medibles"
MERGE (ant:Antipatron {nombre: "Objetivo no medible"})
  SET ant.definicion = "Objetivo sin verbo observable ni criterio de logro"
MERGE (h:Hallazgo {id: "H-0001"})
  SET h.severidad = 3, h.evidencia = "Dice 'conocer' bases de datos", h.confianza = 0.82
MERGE (ant)-[:INCUMPLE]->(reg)
MERGE (v1)-[:TIENE_HALLAZGO]->(h)
MERGE (h)-[:DE_TIPO]->(ant)
MERGE (h)-[:EN]->(frag)

// ---------- Chat y consultas ----------
MERGE (chat:Chat {id: "CHAT-0001"})
MERGE (cons:Consulta {id: "CONS-0001"})
  SET cons.pregunta = "¿Qué materias enseñan bases de datos?", cons.fecha = date("2026-10-15")
MERGE (prof)-[:TIENE]->(chat)
MERGE (chat)-[:GENERA]->(cons)
MERGE (cons)-[:SOBRE]->(piaa)
MERGE (cons)-[:RESPONDIDA_CON]->(frag);
