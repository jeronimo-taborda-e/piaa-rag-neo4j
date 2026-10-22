import os
import re
import sys
from pathlib import Path

from dotenv import load_dotenv
from neo4j import GraphDatabase

RAIZ = Path(__file__).resolve().parent
SCRIPTS = RAIZ / "scripts"


def sentencias(ruta: Path) -> list[str]:
    """Divide un archivo .cypher en sentencias separadas por ';' al final de línea."""
    texto = ruta.read_text(encoding="utf-8")
    sin_comentarios = "\n".join(
        linea for linea in texto.splitlines() if not linea.strip().startswith("//")
    )
    partes = re.split(r";\s*(?:\n|$)", sin_comentarios)
    return [p.strip() for p in partes if p.strip()]


def main() -> None:
    load_dotenv(RAIZ / ".env")
    uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
    usuario = os.getenv("NEO4J_USER", "neo4j")
    clave = os.getenv("NEO4J_PASSWORD")
    if not clave:
        sys.exit("Falta NEO4J_PASSWORD en el archivo .env")

    archivos = sorted(SCRIPTS.glob("0*.cypher"))
    if "--solo-esquema" in sys.argv:
        archivos = [a for a in archivos if a.name.startswith("001_")]

    with GraphDatabase.driver(uri, auth=(usuario, clave)) as driver:
        driver.verify_connectivity()
        print(f"Conectado a {uri}")

        for archivo in archivos:
            lista = sentencias(archivo)
            for sentencia in lista:
                driver.execute_query(sentencia)
            print(f"  {archivo.name}: {len(lista)} sentencias ejecutadas")

        driver.execute_query("CALL db.awaitIndexes(300)")

        constraints, _, _ = driver.execute_query("SHOW CONSTRAINTS YIELD name")
        indices, _, _ = driver.execute_query(
            "SHOW INDEXES YIELD name, type, state, populationPercent "
            "WHERE type IN ['RANGE', 'FULLTEXT', 'VECTOR'] "
            "RETURN name, type, state, populationPercent ORDER BY type, name"
        )
        nodos, _, _ = driver.execute_query(
            "MATCH (n) RETURN labels(n)[0] AS etiqueta, count(*) AS total ORDER BY etiqueta"
        )

    print(f"\nConstraints: {len(constraints)}")
    print("Índices:")
    for r in indices:
        print(f"  {r['type']:<9} {r['name']:<28} {r['state']} {r['populationPercent']:.0f}%")
    print("Nodos por etiqueta:")
    for r in nodos:
        print(f"  {r['etiqueta']:<28} {r['total']}")


if __name__ == "__main__":
    main()
