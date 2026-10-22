// =====================================================
// 001_schema.cypher — Constraints e índices (Neo4j 5 Community)
// Ejecutar ANTES de cargar datos. Se puede repetir sin problema.
// =====================================================

// ---------- Unicidad: estructura académica ----------
CREATE CONSTRAINT departamento_codigo IF NOT EXISTS FOR (n:Departamento) REQUIRE n.codigo IS UNIQUE;
CREATE CONSTRAINT facultad_codigo IF NOT EXISTS FOR (n:Facultad) REQUIRE n.codigo IS UNIQUE;
CREATE CONSTRAINT programa_codigo IF NOT EXISTS FOR (n:Programa) REQUIRE n.codigo IS UNIQUE;
CREATE CONSTRAINT actividad_codigo IF NOT EXISTS FOR (n:ActividadAcademica) REQUIRE n.codigo IS UNIQUE;

// ---------- Unicidad: PIAA y contenido ----------
CREATE CONSTRAINT piaa_codigo IF NOT EXISTS FOR (n:PIAA) REQUIRE n.codigo IS UNIQUE;
CREATE CONSTRAINT version_id IF NOT EXISTS FOR (n:Version) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT seccion_id IF NOT EXISTS FOR (n:Seccion) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT fragmento_id IF NOT EXISTS FOR (n:Fragmento) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT imagen_id IF NOT EXISTS FOR (n:Imagen) REQUIRE n.id IS UNIQUE;

// ---------- Unicidad: personas y órganos ----------
CREATE CONSTRAINT persona_id IF NOT EXISTS FOR (n:Persona) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT comite_id IF NOT EXISTS FOR (n:ComiteCurriculo) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT consejo_facultad_id IF NOT EXISTS FOR (n:ConsejoFacultad) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT consejo_academico_id IF NOT EXISTS FOR (n:ConsejoAcademico) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT politica_id IF NOT EXISTS FOR (n:PoliticaCurricular) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT oficina_calidad_id IF NOT EXISTS FOR (n:OficinaEvaluacionCalidad) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT oficina_admisiones_id IF NOT EXISTS FOR (n:OficinaAdmisionesRegistro) REQUIRE n.id IS UNIQUE;

// ---------- Unicidad: flujo de aprobación ----------
CREATE CONSTRAINT solicitud_id IF NOT EXISTS FOR (n:Solicitud) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT aprobacion_id IF NOT EXISTS FOR (n:Aprobacion) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT tramite_id IF NOT EXISTS FOR (n:TramiteRegistro) REQUIRE n.id IS UNIQUE;

// ---------- Unicidad: auditoría ----------
CREATE CONSTRAINT regla_codigo IF NOT EXISTS FOR (n:Regla) REQUIRE n.codigo IS UNIQUE;
CREATE CONSTRAINT antipatron_nombre IF NOT EXISTS FOR (n:Antipatron) REQUIRE n.nombre IS UNIQUE;
CREATE CONSTRAINT hallazgo_id IF NOT EXISTS FOR (n:Hallazgo) REQUIRE n.id IS UNIQUE;

// ---------- Unicidad: chat ----------
CREATE CONSTRAINT chat_id IF NOT EXISTS FOR (n:Chat) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT consulta_id IF NOT EXISTS FOR (n:Consulta) REQUIRE n.id IS UNIQUE;

// ---------- Índices de propiedad (filtros frecuentes) ----------
CREATE INDEX piaa_estado IF NOT EXISTS FOR (n:PIAA) ON (n.estado);
CREATE INDEX version_estado IF NOT EXISTS FOR (n:Version) ON (n.estado);
CREATE INDEX solicitud_estado IF NOT EXISTS FOR (n:Solicitud) ON (n.estado);
CREATE INDEX fragmento_chunking IF NOT EXISTS FOR (n:Fragmento) ON (n.estrategia_chunking, n.idioma);
CREATE INDEX consulta_fecha IF NOT EXISTS FOR (n:Consulta) ON (n.fecha);

// ---------- Índices compuestos (obligatorios en la plantilla) ----------
// Equivale a idx_fecha_idioma de "documentos": cada Version es un documento PIAA
CREATE INDEX version_fecha_idioma IF NOT EXISTS FOR (n:Version) ON (n.fecha, n.idioma);
// Fecha e idioma de los chunks, para filtrar junto con la similitud
CREATE INDEX fragmento_fecha_idioma IF NOT EXISTS FOR (n:Fragmento) ON (n.fecha_ingesta, n.idioma);

// ---------- Índice de texto completo (español) ----------
// Equivale a idx_texto de "documentos": texto completo de cada sección
CREATE FULLTEXT INDEX seccion_texto IF NOT EXISTS
FOR (n:Seccion) ON EACH [n.texto, n.titulo_original]
OPTIONS { indexConfig: { `fulltext.analyzer`: 'spanish' } };

// Texto completo de los fragmentos (unidad de búsqueda del RAG)
CREATE FULLTEXT INDEX fragmento_texto IF NOT EXISTS
FOR (n:Fragmento) ON EACH [n.texto]
OPTIONS { indexConfig: { `fulltext.analyzer`: 'spanish' } };

// ---------- Índices vectoriales ----------
CREATE VECTOR INDEX fragmento_emb_minilm_v1 IF NOT EXISTS
FOR (n:Fragmento) ON n.embedding
OPTIONS { indexConfig: { `vector.dimensions`: 384, `vector.similarity_function`: 'cosine' } };

CREATE VECTOR INDEX fragmento_emb_clip_v1 IF NOT EXISTS
FOR (n:Fragmento) ON n.embedding_clip
OPTIONS { indexConfig: { `vector.dimensions`: 512, `vector.similarity_function`: 'cosine' } };

CREATE VECTOR INDEX imagen_emb_clip_v1 IF NOT EXISTS
FOR (n:Imagen) ON n.embedding_clip
OPTIONS { indexConfig: { `vector.dimensions`: 512, `vector.similarity_function`: 'cosine' } };