"""Informe visual a partir de respuestas reales ya guardadas; no ejecuta APIs."""
import html
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "evidencias"
sections = [
    ("Retry Categoria", "retry/categoria-no-disponible.json"),
    ("Bulkhead Categoria", "bulkhead/categoria-concurrente.json"),
    ("Retry Cliente", "actividad-final/cliente-retry.json"),
    ("Bulkhead Producto", "actividad-final/producto-bulkhead.json"),
]
cards = []
for title, relative in sections:
    data = json.loads((root / relative).read_text(encoding="utf-8-sig"))
    content = ""
    if "Attempts" in data:
        content += f'<p>Intentos observados: <strong>{data["Attempts"]}</strong>. Duracion: {data["Milliseconds"]} ms.</p>'
    if "Responses" in data:
        rows = "".join(
            f'<tr><td>{r["Index"]}</td><td>{r["Status"]}</td><td>{r["Milliseconds"]}</td>'
            f'<td><code>{html.escape(r["Body"])}</code></td></tr>'
            for r in data["Responses"]
        )
        content += '<table><tr><th>Solicitud</th><th>HTTP</th><th>ms</th><th>Respuesta real</th></tr>' + rows + '</table>'
    else:
        content += '<pre>' + html.escape(json.dumps(data.get("Response"), ensure_ascii=False, indent=2)) + '</pre>'
    lines = data.get("Console", [])
    if lines:
        content += '<h3>Extracto real de consola</h3><pre>' + html.escape("\n".join(lines)) + '</pre>'
    cards.append(f'<section><h2>{title}</h2><p>Fuente: <a href="{relative}">{relative}</a></p>{content}</section>')

document = '''<!doctype html><html lang="es"><meta charset="utf-8"><title>Lab 14 - Resultados reales</title>
<style>body{font:16px system-ui;background:#f4f6f8;color:#172536;max-width:1280px;margin:30px auto;padding:0 24px}
section{background:white;border:1px solid #ccd6df;border-radius:8px;margin:22px 0;padding:22px}
pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#edf2f5;padding:12px;font-size:13px}
table{border-collapse:collapse;width:100%;font-size:14px}td,th{border:1px solid #ccd6df;padding:9px;text-align:left}
code{overflow-wrap:anywhere}h1,h2{color:#125272}</style>
<h1>Laboratorio 14 — Resultados de pruebas reales</h1>
<p>Informe generado exclusivamente a partir de los JSON guardados. No es una interfaz de Postman ni una captura en vivo de los servicios.
Las capturas de este informe documentan los resultados registrados, sin simular pantallas ajenas.</p>'''
(root / "informe.html").write_text(document + "".join(cards) + '</html>', encoding="utf-8")
print(root / "informe.html")
