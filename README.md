# piaa-rag-neo4j

Base de datos en grafo y embeddings para el sistema RAG de PIAAs (Programa Institucional de Actividad Académica) de la Universidad de Caldas, construida sobre **Neo4j 5 Community**.

El grafo guarda la estructura académica (facultades, programas, actividades), los PIAAs con sus versiones, secciones y fragmentos, el flujo de aprobación, los hallazgos de auditoría y el historial de consultas. Los fragmentos y las imágenes llevan embeddings para búsqueda semántica:

| Modelo | Dimensiones | Uso | Índice |
| --- | --- | --- | --- |
| MiniLM multilingüe (`paraphrase-multilingual-MiniLM-L12-v2`) | 384 | Texto → texto | `fragmento_emb_minilm_v1` |
| CLIP (`clip-ViT-B-32`) | 512 | Texto ↔ imagen, imagen → imagen | `fragmento_emb_clip_v1`, `imagen_emb_clip_v1` |

## Integrantes

- Jerónimo Taborda Echeverry
- Juan Felipe Sanabria Posada
- Sebastián Garzón Arias
- Simón Cárdenas Sánchez

## Estructura

```
piaa-rag-neo4j/
├── docker-compose.yml          # Neo4j 5 Community
├── .env.example                # Variables de entorno (copiar a .env)
├── .gitignore
├── import/                     # Archivos CSV para LOAD CSV
├── backups/                    # Dumps de la base (no se suben a Git)
└── scripts/
    ├── 001_esquema.cypher      # Constraints e índices
    └── 002_datos_ejemplo.cypher # Datos de prueba
```

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (en Windows, con WSL2)
- Git
- Python 3.12 y [uv](https://docs.astral.sh/uv/) (para generar embeddings)

## Puesta en marcha

1. Clonar el repositorio:

   ```bash
   git clone <URL-del-repositorio>
   cd piaa-rag-neo4j
   ```

2. Crear el archivo de variables y poner una contraseña propia (mínimo 8 caracteres):

   ```bash
   cp .env.example .env
   ```

3. Levantar Neo4j:

   ```bash
   docker compose up -d
   docker compose logs neo4j   # esperar la línea "Started."
   ```

4. Crear el esquema y cargar los datos de ejemplo:

   ```bash
   docker exec -i neo4j-piaa cypher-shell -u neo4j -p <tu_clave> < scripts/001_esquema.cypher
   docker exec -i neo4j-piaa cypher-shell -u neo4j -p <tu_clave> < scripts/002_datos_ejemplo.cypher
   ```

5. Abrir Neo4j Browser en <http://localhost:7474> y conectarse con `bolt://localhost:7687`, usuario `neo4j` y la contraseña del `.env`.

La contraseña se fija la primera vez que arranca Neo4j. Cambiarla después en `.env` no la cambia en la base.

## Verificación

En Neo4j Browser:

```cypher
// Nodos por etiqueta
MATCH (n) RETURN labels(n) AS etiqueta, count(*) AS total ORDER BY total DESC;

// Constraints e índices (los índices deben estar ONLINE)
SHOW CONSTRAINTS;
SHOW INDEXES;

// Diagrama del modelo
CALL db.schema.visualization();
```

## Uso diario

| Acción | Comando |
| --- | --- |
| Encender | `docker compose start` |
| Apagar | `docker compose stop` |
| Ver estado | `docker compose ps` |
| Ver logs | `docker compose logs neo4j` |

No uses `docker compose down -v`: la opción `-v` borra el volumen y todos los datos.

## Modelo de datos (resumen)

```
(Facultad)-[:TIENE]->(Programa)-[:TIENE]->(ActividadAcademica)<-[:OFERTA]-(Departamento)
(PIAA)-[:PROGRAMA_DE]->(ActividadAcademica)
(PIAA)-[:TIENE_VERSION]->(Version)    (PIAA)-[:VIGENTE]->(Version)
(Version)-[:TIENE_SECCION]->(Seccion)-[:TIENE_FRAGMENTO]->(Fragmento)
(Version)-[:TIENE_HALLAZGO]->(Hallazgo)-[:DE_TIPO]->(Antipatron)-[:INCUMPLE]->(Regla)
(Hallazgo)-[:EN]->(Fragmento)
(Persona)-[:ENVIA]->(Solicitud)-[:PROPONE]->(Version)
(Aprobacion)-[:SOBRE]->(Solicitud)
(Persona)-[:TIENE]->(Chat)-[:GENERA]->(Consulta)-[:RESPONDIDA_CON]->(Fragmento)
```

## Reglas del equipo

- **Todo cambio de esquema va en un script nuevo** (`003_...cypher`, `004_...cypher`) y se sube a Git. Nunca se modifica la base solo a mano.
- Los scripts usan `MERGE` e `IF NOT EXISTS`, así que se pueden ejecutar varias veces sin duplicar datos.
- Las consultas usan parámetros (`$codigo`), nunca texto concatenado.
- Las versiones de un PIAA no se borran: pasan a estado `HISTORICO`.
- `.env` y `backups/` nunca se suben al repositorio.
- Se trabaja en ramas (`feat/...`, `fix/...`) y se integra a `master` por pull request.

## Compartir una copia completa de la base

Para pasar datos pesados (por ejemplo, con embeddings) sin regenerarlos, con Neo4j detenido:

```bash
# Exportar
docker compose stop
docker run --rm -v piaa-rag-neo4j_neo4j_piaa_data:/data -v "$(pwd)/backups":/backups \
  neo4j:5.26-community neo4j-admin database dump neo4j --to-path=/backups
docker compose start

# Importar (reemplaza la base local)
docker compose stop
docker run --rm -v piaa-rag-neo4j_neo4j_piaa_data:/data -v "$(pwd)/backups":/backups \
  neo4j:5.26-community neo4j-admin database load neo4j --from-path=/backups --overwrite-destination=true
docker compose start
```

El archivo `backups/neo4j.dump` se comparte por Drive u OneDrive, no por Git. El nombre del volumen depende del nombre de la carpeta; compruébalo con `docker volume ls`.

## Documentación

- [Manual de Cypher](https://neo4j.com/docs/cypher-manual/current/)
- [Índices vectoriales](https://neo4j.com/docs/cypher-manual/current/indexes/semantic-indexes/vector-indexes/)
- [Driver de Python](https://neo4j.com/docs/python-manual/current/)
- [Neo4j GraphAcademy](https://graphacademy.neo4j.com)
- [Sentence Transformers](https://www.sbert.net)