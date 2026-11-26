// Renderizador local del subconjunto GFM usado aqui; no llama a GitHub ni CDN.
import {readFileSync,writeFileSync} from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {root,runtime,save} from './Grafana-API.mjs';
import {browserSession,delay} from './Navegador-Lab15.mjs';
const escape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const inline=s=>escape(s).replace(/!\[([^\]]*)\]\(([^)]+)\)/g,'<img alt="$1" src="$2">').replace(/\[([^\]]+)\]\(([^)]+)\)/g,'<a href="$2">$1</a>').replace(/`([^`]+)`/g,'<code>$1</code>').replace(/\*\*([^*]+)\*\*/g,'<strong>$1</strong>');
const lines=readFileSync(path.join(root,'README.md'),'utf8').split(/\r?\n/);let html='',code=null,table=false;
for(const line of lines){
  if(line.startsWith('```')){if(code===null){code=line.slice(3);html+='<pre class="'+escape(code)+'"><code>';}else{html+='</code></pre>';code=null;}continue;}
  if(code!==null){html+=escape(line)+'\n';continue;}
  if(line.startsWith('|')){if(!table){html+='<table>';table=true;}if(/^\|[\s:|-]+\|$/.test(line))continue;html+='<tr>'+line.slice(1,-1).split('|').map(c=>'<td>'+inline(c.trim())+'</td>').join('')+'</tr>';continue;}
  if(table){html+='</table>';table=false;}
  const h=line.match(/^(#{1,6}) (.*)$/);if(h){html+=`<h${h[1].length}>${inline(h[2])}</h${h[1].length}>`;continue;}
  if(!line.trim()){html+='<div class="gap"></div>';continue;}
  if(/^[-] /.test(line)||/^\d+\. /.test(line)){html+='<div class="item">'+inline(line)+'</div>';continue;}
  if(line.startsWith('>')){html+='<blockquote>'+inline(line.slice(1).trim())+'</blockquote>';continue;}
  html+='<div>'+inline(line)+'</div>';
}
if(table)html+='</table>';
const file=path.join(runtime,'README-vista-previa.html');
writeFileSync(file,'<!doctype html><html lang="es"><meta charset="utf-8"><title>Vista previa local - README Lab 15</title><base href="'+escape(pathToFileURL(root+path.sep).href)+'"><style>body{margin:0;background:#0d1117;color:#e6edf3;font:16px/1.6 Segoe UI,sans-serif}main{max-width:1180px;margin:0 auto;padding:32px 40px}h1,h2{border-bottom:1px solid #30363d;padding-bottom:8px}h2{margin-top:42px}a{color:#58a6ff}img{width:100%;height:auto;display:block;border:1px solid #30363d;margin:16px 0}pre{overflow:auto;background:#161b22;padding:20px;border-radius:8px}code{font-family:Consolas,monospace;background:#161b22}table{border-collapse:collapse;width:100%;margin:16px 0}td{padding:8px 12px;border:1px solid #30363d}tr:nth-child(even){background:#161b22}blockquote{margin:0;padding:8px 16px;border-left:4px solid #58a6ff;background:#161b22}.gap{height:10px}.item{margin-left:14px}aside{padding:12px;background:#1f2937}</style><aside>VISTA PREVIA LOCAL: no publicada en GitHub. Subconjunto GFM; Mermaid se conserva como código para su renderizado en GitHub.</aside><main>'+html+'</main></html>');
const s=await browserSession();const report={Completed:false,Timestamp:new Date().toISOString(),README_SHA256:createHash('sha256').update(readFileSync(path.join(root,'README.md'))).digest('hex'),Renderer:'Renderizador local sin dependencias: encabezados, listas, tablas, codigo, enlaces e imagenes; Mermaid como codigo',GithubPublished:false};
try{
  await s.navigate(pathToFileURL(file).href);await s.waitFor('[...document.images].every(i=>i.complete&&i.naturalWidth>0)',60000);
  const state=await s.evaluate('({images:[...document.images].map(i=>({alt:i.alt,loaded:i.complete&&i.naturalWidth>0,width:i.naturalWidth,height:i.naturalHeight})),sections:[...document.querySelectorAll("h2")].map(h=>h.innerText),height:document.documentElement.scrollHeight})');
  if(state.images.length!==29||state.sections.length!==24)throw new Error('Vista previa no contiene todas las imagenes/secciones');
  report.Images=state.images;report.Sections=state.sections;report.ContentHeight=state.height;
  const metrics=await s.pageSend('Page.getLayoutMetrics');const clip=metrics.cssContentSize||metrics.contentSize;
  const full=await s.pageSend('Page.captureScreenshot',{format:'png',captureBeyondViewport:true,clip:{x:0,y:0,width:clip.width,height:clip.height,scale:1}});
  writeFileSync(path.join(runtime,'README-vista-previa-completa.png'),Buffer.from(full.data,'base64'));
  await s.screenshot(path.join(runtime,'README-vista-previa-ventana.png'));
  report.FullScreenshot='.runtime/paso06/README-vista-previa-completa.png';report.WindowScreenshot='.runtime/paso06/README-vista-previa-ventana.png';report.Completed=true;
}catch(error){report.Error=error.message;process.exitCode=1;console.error(error.message);}
finally{save('VISTA-PREVIA-README.json',report);await s.close();}
console.log(JSON.stringify({Completed:report.Completed,Images:report.Images?.length,Sections:report.Sections?.length,Height:report.ContentHeight,Error:report.Error||null}));
