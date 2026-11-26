import {readFileSync,writeFileSync,readdirSync,statSync,existsSync} from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {root,evidence,runtime,readJson,credentials} from './Grafana-API.mjs';
const slash=p=>p.replaceAll('\\','/');
export const sha=file=>createHash('sha256').update(readFileSync(file)).digest('hex');
function git(args,input){const r=spawnSync('git',args,{cwd:root,input,encoding:'utf8',maxBuffer:64*1024*1024,windowsHide:true});if(r.status!==0&&r.status!==1)throw new Error('No se pudo leer inventario Git');return r.stdout;}
export function publicFiles(){return [...new Set(git(['ls-files','-z','--cached','--others','--exclude-standard','--','.']).split('\0').filter(Boolean))].sort();}
export function png(file){const b=readFileSync(file);const valid=b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))&&b.subarray(12,16).toString()==='IHDR';return {Valid:valid,Width:valid?b.readUInt32BE(16):0,Height:valid?b.readUInt32BE(20):0};}
function exactCase(relative){let dir=root;for(const p of slash(relative).split('/')){if(!p||p==='.')continue;if(p==='..'){dir=path.dirname(dir);continue;}if(!existsSync(dir)||!readdirSync(dir).includes(p))return false;dir=path.join(dir,p);}return true;}
export function validateDocs(){const docs=[];const issues=[];let totalImages=0;
  for(const name of ['README.md','ENTREGABLE-LAB15.md']){const text=readFileSync(path.join(root,name),'utf8');const withoutCode=text.replace(/^```[^\n]*\n[\s\S]*?^```\s*$/gm,'');const refs=[];
    for(const m of withoutCode.matchAll(/(!?)\[([^\]]*)\]\(([^)]+)\)/g)){const image=m[1]==='!';const target=m[3];if(image)totalImages++;if(/^(https?:|mailto:)/i.test(target)){if(image)issues.push({Document:name,Target:target,Reason:'Imagen externa prohibida'});continue;}
      if(/^(?:file:|[A-Za-z]:|\/|\\)/.test(target)){issues.push({Document:name,Target:target,Reason:'Ruta absoluta'});continue;}
      const relative=decodeURIComponent(target.split('#')[0]);if(!relative)continue;const full=path.resolve(root,relative);const present=existsSync(full);const caseValid=present&&exactCase(relative);const item={Target:target,Image:image,Exists:present,CaseExact:caseValid};
      if(!present||!caseValid)issues.push({Document:name,Target:target,Reason:!present?'Archivo inexistente':'Mayusculas/minusculas diferentes'});
      if(image&&present){item.PNG=png(full);const ignored=git(['check-ignore','-z','--stdin'],relative+'\0').split('\0').filter(Boolean);item.NotIgnored=ignored.length===0;if(!item.PNG.Valid||!item.NotIgnored)issues.push({Document:name,Target:target,Reason:'PNG invalido o ignorado'});}
      refs.push(item);
    }
    const fences=(text.match(/^```/gm)||[]).length;const sections=[...text.matchAll(/^## (.+)$/gm)].map(m=>m[1]);if(fences%2)issues.push({Document:name,Reason:'Bloque de codigo sin cerrar'});
    docs.push({File:name,SHA256:sha(path.join(root,name)),Images:refs.filter(r=>r.Image).length,RelativeReferences:refs.length,Sections:sections,References:refs});
  }
  const readme=docs.find(d=>d.File==='README.md');if(readme.Images!==29||readme.Sections.length!==24)issues.push({Document:'README.md',Reason:'Se esperaban 29 imagenes y 24 secciones'});
  const report={Timestamp:new Date().toISOString(),Completed:issues.length===0,Documents:docs,READMEImages:readme.Images,TotalDocumentImageUses:totalImages,Issues:issues,GFM:'Encabezados, tablas, listas, enlaces, imagenes Markdown y fences Mermaid; sin sintaxis propietaria ni imagenes externas',GithubPublished:false};
  writeFileSync(path.join(evidence,'VALIDACION-DOCUMENTACION.json'),JSON.stringify(report,null,2)+'\n');return report;
}
export function scanPublic(files){const findings=[];const legacy=[];const secret=credentials().password;
  for(const relative of files){const full=path.join(root,relative);if(/(^|\/)(?:\.runtime|target|node_modules|\.idea|\.git)(\/|$)|\.(?:exe|dll|jar|war|zip|gz|msi|class|clixml|sqlite3?|db|wal|log|pid|tmp)$/i.test(relative))findings.push({File:relative,Reason:'Artefacto operativo/binario publicable'});
    if(!/\.(?:md|json|txt|ps1|mjs|java|xml|ya?ml|properties|sql)$/.test(relative)&&!['mvnw','.gitignore'].includes(path.basename(relative)))continue;
    const text=readFileSync(full,'utf8');if(text.includes(secret))findings.push({File:relative,Reason:'Coincidencia con secreto Grafana privado'});
    if(/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|\bgh[pousr]_[A-Za-z0-9]{25,}|\bAKIA[0-9A-Z]{16}\b/.test(text))findings.push({File:relative,Reason:'Patron de secreto de alta confianza'});
    if(!relative.startsWith('evidencias/')){let line=0;for(const value of text.split(/\r?\n/)){line++;const m=value.match(/^\s*["']?([\w.-]*(?:password|passwd|secret|token)[\w.-]*)["']?\s*[:=]\s*(.*)$/i);if(m){const rhs=m[2].trim().replace(/^\x60/,'');const kind=/^(["']{2})?\s*(#.*)?$/.test(rhs)?'empty':/^['"]?\$(?:\{|__file)/.test(rhs)?'reference':/^(true|false|null|never|always)\b/.test(rhs)?'non-secret-setting':'review';legacy.push({File:relative,Line:line,Key:m[1],Classification:kind});if(kind==='review')findings.push({File:relative,Line:line,Reason:'Valor de configuracion sensible requiere revision, valor no publicado'});}}}
    if(relative.startsWith('evidencias/')&&relative.endsWith('.json')&&/"(?:password|passwd|token|secret|authorization|cookie|email|direccion|apellido|nro_dni|nroDni)"\s*:\s*"(?!\[REDACTADO\]|\*+)[^"\s][^"]*"/i.test(text))findings.push({File:relative,Reason:'Campo sensible no protegido'});
  }
  return {Completed:findings.length===0,Findings:findings,InheritedSourcesReviewed:legacy,Scope:'Candidatos del checkout, reglas de alta confianza y coincidencia con clave privada Grafana; no auditoria exhaustiva del remoto config-repo',NoSecretValuesPrinted:true};
}
export function inventory(){const paths=publicFiles();const files=paths.map(p=>({Path:p,Bytes:statSync(path.join(root,p)).size}));const ignored=git(['ls-files','-z','--others','--ignored','--exclude-standard','--','.']).split('\0').filter(Boolean);return {FileCount:files.length,TotalBytes:files.reduce((s,f)=>s+f.Bytes,0),PNGCount:files.filter(f=>f.Path.endsWith('.png')).length,Largest:[...files].sort((a,b)=>b.Bytes-a.Bytes).slice(0,10),ExcludedFileCount:ignored.length,ExcludedRules:['.runtime/**','**/target/**','**/node_modules/**','**/.idea/**','*.exe, *.dll, *.jar, *.zip, *.gz','SQLite, TSDB, WAL, logs, perfiles y credenciales bajo .runtime'],Files:files};}
export function writeInventory(state){const header=['INVENTARIO DE PUBLICACION — FERNANDEZ_LAB15','Solo lectura; no git add/commit/push. Publicacion reservada al PASO 07.','Alcance: git ls-files --cached --others --exclude-standard -- .','Incluye este inventario y la verificacion final; bytes comprobados tras estabilizar artefactos.','Archivos: '+state.FileCount,'Tamano total (bytes): '+state.TotalBytes,'PNG publicables: '+state.PNGCount,'PNG insertados en README: 29','Archivos ignorados/excluidos: '+state.ExcludedFileCount,'','EXCLUSIONES',...state.ExcludedRules,'','ARCHIVOS MAS PESADOS',...state.Largest.map(f=>`${f.Bytes}\t${f.Path}`),'','LISTA EXACTA — BYTES\tRUTA RELATIVA',...state.Files.map(f=>`${f.Bytes}\t${f.Path}`),'','RIESGOS Y ESTRATEGIA','Revisar rutas locales/hostname de informes historicos si se desea anonimizar la maquina.','La auditoria no certifica secretos del repositorio remoto de configuracion.','No publicar sin repetir validacion y revision de diff en una copia limpia del remoto.','En PASO07, copiar solo esta lista dentro de fernandez_lab15; excluir operacion y otros laboratorios.','El staging del repositorio actual no se modifica.',''];writeFileSync(path.join(evidence,'INVENTARIO-PUBLICACION.txt'),header.join('\n'));}
if(process.argv.includes('--validar-documentos')){const r=validateDocs();console.log(JSON.stringify({Completed:r.Completed,READMEImages:r.READMEImages,Issues:r.Issues}));if(!r.Completed)process.exitCode=1;}
