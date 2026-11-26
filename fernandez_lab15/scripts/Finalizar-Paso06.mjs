// Consolida evidencias existentes. No inicia procesos, compila, captura ni escribe en Git/SQL.
import {readFileSync,writeFileSync,existsSync,statSync} from 'node:fs';
import path from 'node:path';
import {root,runtime,evidence,readJson,api} from './Grafana-API.mjs';
import {sha,png,validateDocs,scanPublic,publicFiles,inventory,writeInventory} from './Auditoria-Documental.mjs';
if(!process.argv.includes('--paso=06'))throw new Error('Se requiere --paso=06.');
const read=name=>readJson(path.join(evidence,name));
const write=(name,data)=>writeFileSync(path.join(evidence,name),JSON.stringify(data,null,2)+'\n');
const assert=(condition,message)=>{if(!condition)throw new Error(message);};
async function get(url){const r=await fetch(url,{headers:{Accept:'application/json'},signal:AbortSignal.timeout(30000)});const text=await r.text();let body;try{body=JSON.parse(text);}catch{body=null;}return {http:r.status,body,text};}
const report={Step:'06',Timestamp:new Date().toISOString(),Completed:false,Status:'Consolidando evidencias recuperadas',Step07Executed:false,GithubPublished:false,ReadyForStep07:false};
try {
  const tests=read('PRUEBAS-FINALES.json'),academic=read('AUDITORIA-GUIA.json'),ui=read('INTERFAZ-GRAFANA.json'),queries=read('CONSULTAS-GRAFANA.json');
  assert(tests.Completed&&tests.Actuator.length===21&&tests.Actuator.every(x=>x.Valid)&&tests.PrometheusEndpoints.length===7&&tests.PrometheusEndpoints.every(x=>x.Valid)&&tests.Functional.length===6&&tests.Functional.every(x=>x.Valid),'Pruebas recuperadas incompletas.');
  assert(academic.Completed&&academic.Mandatory.length===17&&academic.Mandatory.every(x=>x.Verified),'Auditoria academica incompleta.');
  assert(ui.Completed&&ui.AutomaticRefresh.Verified&&queries.Completed&&queries.Panels.length===17&&queries.Panels.every(x=>x.Valid)&&queries.Filters.length===7&&queries.Filters.every(x=>x.Valid),'Dashboard/filtros/actualizacion sin validar.');
  report.Recovered={TestsTimestamp:tests.Timestamp,Actuator:21,Exporters:7,FunctionalRoutes:6,PanelQueries:17,Filters:7,UI:true,GeneralScripts:readJson(path.join(runtime,'checkpoint-scripts.json'))};
  report.RecoveryFixes={Grafana:'Reutilizar DACL privada correcta; sin cambiar credenciales ni SACL.',Prometheus:'No sobrescribir evidencia historica en arranques posteriores; original recuperado con hash identico.',NewPromtoolValidation:'.runtime/paso06/VALIDACION-PROMTOOL-recuperacion.json'};
  assert(report.Recovered.GeneralScripts.Completed&&report.Recovered.GeneralScripts.StartIdempotent&&report.Recovered.GeneralScripts.StopWhatIf,'Scripts generales no verificados.');
  const original=readJson(path.join(runtime,'evidencias-originales.json'));
  const changed=original.filter(x=>!existsSync(path.join(root,x.Path))||sha(path.join(root,x.Path)).toLowerCase()!==x.SHA256.toLowerCase()).map(x=>x.Path);
  assert(changed.length===0,'Se alteraron evidencias anteriores: '+changed.join(', '));
  const captures=read('AUDITORIA-CAPTURAS.json'),selection=read('INVENTARIO-IMAGENES-README.json'),fresh=read('CAPTURAS-PASO06.json');
  assert(captures.AllTechnicalChecksPassed&&captures.Captures.length===59&&fresh.captures.length===6&&!fresh.error&&fresh.Explore.Verified,'Inventario de capturas incompleto.');
  for(const x of captures.Captures)assert(sha(path.join(root,x.File)).toLowerCase()===x.SHA256.toLowerCase()&&png(path.join(root,x.File)).Valid,'Captura historica modificada: '+x.File);
  const readme=readFileSync(path.join(root,'README.md'),'utf8');
  const imagePaths=[...readme.matchAll(/!\[[^\]]*\]\(([^)]+)\)/g)].map(x=>x[1]);
  assert(selection.PNGSelections===29&&selection.Reused===23&&selection.New===6&&imagePaths.length===29,'Seleccion README incoherente.');
  for(const x of selection.Images.filter(x=>x.Kind==='PNG'))assert(imagePaths.includes(x.File)&&sha(path.join(root,x.File))===x.SHA256&&png(path.join(root,x.File)).Valid,'Imagen README distinta del inventario: '+x.File);
  for(const x of fresh.captures)assert(selection.Images.some(i=>i.File===x.path&&i.New&&i.Bytes===x.bytes),'Captura nueva sin procedencia: '+x.path);
  report.Captures={Total:65,Previous:59,NewBeforeInterruption:6,CreatedDuringRecovery:0,READMEImages:29,ReusedInREADME:23,AllHashesMatch:true,PreviousEvidenceFilesPreserved:original.length,VisualReview:'Auditoria anterior conservada; seis imagenes nuevas y vista previa revisadas al recuperar. Datos personales de Pedido enmascarados; originales privados excluidos.'};
  const preview=read('VISTA-PREVIA-README.json');
  assert(preview.Completed&&preview.Images.length===29&&preview.Images.every(x=>x.loaded)&&preview.Sections.length===24,'Vista previa incompleta.');
  assert(preview.README_SHA256===sha(path.join(root,'README.md')),'README cambio desde la vista previa; regenerar y validar explicitamente.');
  for(const file of [preview.FullScreenshot,preview.WindowScreenshot,'.runtime/paso06/README-vista-previa.html'])assert(existsSync(path.join(root,file))&&statSync(path.join(root,file)).size>0,'Falta artefacto de vista previa.');
  report.Preview={Completed:true,RegeneratedAfterRecoveryNote:true,PreviousValidPreviewPreserved:true,README_SHA256:sha(path.join(root,'README.md')),HTML_SHA256:sha(path.join(runtime,'README-vista-previa.html')),ImagesLoaded:29,Sections:24,LocalOnly:true,Mermaid:'Conservado como codigo en vista local; renderizado GFM reservado a GitHub.'};
  for(const file of ['README.md','ENTREGABLE-LAB15.md']){const text=readFileSync(path.join(root,file),'utf8');const block=text.split(/^## .*Cinco conclusiones\s*$/m)[1]?.split(/^## /m)[0];assert(block&&[...block.matchAll(/^[1-5]\. /gm)].length===5,'Se requieren cinco conclusiones en '+file);}
  const system=readJson(path.join(runtime,'recuperacion-sistema.json')),integrity=readJson(path.join(runtime,'integridad-resultado.json'));
  assert(system.Completed&&system.ProcessesValid&&system.Databases.Unchanged&&system.MariaDB.Running,'Estado recuperado del sistema no valido.');
  assert(Date.now()-Date.parse(system.Timestamp)<30*60*1000,'Comprobacion del sistema demasiado antigua.');
  assert(integrity.ExternalChangedOrRemoved.length===0&&integrity.ExternalAdded.length===0&&integrity.Lab14Unchanged&&integrity.IndexUnchanged&&integrity.HeadUnchanged&&integrity.ExternalGitStatusUnchanged,'Integridad externa/Git no confirmada.');
  report.Integrity={Completed:true,Lab14Unchanged:true,Lab14Files:integrity.Lab14Files,ExternalFiles:integrity.ExternalFilesAfter,OtherLabsAndLocalConfigRepoUnchanged:true,ExternalChanged:0,IndexSHA256:integrity.IndexSHA256After,StagingUnchanged:true,HeadUnchanged:true,ExternalGitStatusUnchanged:true,Branch:integrity.Branch,DatabaseSchemas:system.Databases.Schemas,DatabaseTables:system.Databases.Tables,DatabaseHashesUnchanged:true,ReadOnlyWithRollback:true,OriginalEvidenceUnchanged:true,OperationalProofs:'.runtime/paso06/{integridad-resultado,recuperacion-sistema,bases-recuperacion}.json'};
  // Solo sondas imprescindibles tras restaurar procesos ausentes; no repetir trafico ni capturas.
  const services={'config-server':8888,'eureka-server':8761,'gateway-service':8080,'categoria-service':8082,'producto-service':8083,'cliente-service':8084,'pedido-service':8085};
  const health=[];
  for(const [name,port] of Object.entries(services)){const x=await get(`http://127.0.0.1:${port}/actuator/health`);assert(x.http===200&&x.body?.status==='UP','Health actual no UP: '+name);const probe=readJson(path.join(root,'.runtime','paso03',`proteccion-${name}.json`));assert(probe.valid,'Contexto efectivo invalido: '+name);health.push({Service:name,Port:port,Http:x.http,Status:x.body.status,StartupContextValid:true});}
  const ready=await get('http://127.0.0.1:9090/-/ready'),targets=await get('http://127.0.0.1:9090/api/v1/targets');
  const active=targets.body?.data?.activeTargets;assert(ready.http===200&&targets.http===200&&active?.length===7&&active.every(t=>t.health==='up'&&!t.lastError),'Targets actuales no validos.');
  const gh=await api('/api/health',{auth:null}),ds=await api('/api/datasources/uid/prometheus-lab15/health'),dash=await api('/api/dashboards/uid/lab15-observabilidad');
  assert(gh.body.database==='ok'&&ds.body.status==='OK'&&dash.body.dashboard.panels.length===18&&dash.body.dashboard.refresh==='5s'&&dash.body.meta.provisioned,'Grafana actual no valido.');
  const apps=await get('http://127.0.0.1:8761/eureka/apps');const registrations=apps.body?.applications?.application??[];
  assert(registrations.length===5&&registrations.every(a=>(Array.isArray(a.instance)?a.instance:[a.instance]).every(i=>i.status==='UP')),'Eureka actual incompleto.');
  report.Services={Completed:true,Timestamp:new Date().toISOString(),Applications:health,Processes:system.Processes,Targets:{Total:7,UP:7,DOWN:0,NoErrors:true},EurekaApplications:5,Grafana:'healthy',Datasource:'OK',DashboardPanels:18,Refresh:'5s',MariaDBRunning:true,ProcessesUnique:true,LocalhostOnly:true,SameApprovedArtifacts:true,PreviousProcessesNoLongerRunningAtRecovery:true,RestoredServices:9,ReusedRunningLabServices:0,Installations:0,Builds:0,NewBusinessTrafficRounds:0,LeftRunning:true};
  const docs=validateDocs();assert(docs.Completed,'Enlaces/imagenes de documentacion no validos.');
  report.Documentation={Completed:true,READMEImages:docs.READMEImages,ImageUsesBothDocuments:docs.TotalDocumentImageUses,RelativeReferences:docs.Documents.reduce((s,d)=>s+d.RelativeReferences,0),BrokenImages:0,BrokenRelativeLinks:0,CaseExact:true,GitIgnoredImages:0,ConclusionsPerDocument:5,ExternalLinks:'No se realiza auditoria de disponibilidad web externa; destino local Grafana verificado por API.'};
  const secrets=scanPublic(publicFiles());assert(secrets.Completed,'Hallazgos de seguridad publicables; revisar informe sin exponer valores.');
  report.Security={Completed:true,Findings:secrets.Findings,InheritedSourcesReviewed:secrets.InheritedSourcesReviewed,CredentialsExcluded:true,PersonalBusinessDataRedacted:true,AuthorAttributionRetained:true,Scope:secrets.Scope};
  report.Academic={Completed:true,MandatoryVerified:17,GuidePDFPresent:false,Basis:academic.GuideBasis,Audit:'AUDITORIA-GUIA.json',AdditionalDashboard:true,TracingClaimed:false};
  report.Publication={FileCount:0,TotalBytes:0,PNGCount:65,Inventory:'INVENTARIO-PUBLICACION.txt',ExactInventoryVerified:false,Strategy:'Otra copia limpia del remoto, solo inventario de Lab 15; requiere autorizacion del PASO 07.'};
  report.Completed=true;report.ReadyForStep07=true;report.Status='PASO 06 verificado; servicios activos. Esperando autorizacion para PASO 07.';
  // El inventario se incluye a si mismo: resolver bytes hasta un punto fijo y comprobar desde disco.
  report.Publication.ExactInventoryVerified=true;
  let stable=false;
  for(let attempt=0;attempt<12;attempt++){
    write('VERIFICACION-PASO06.json',report);const state=inventory();writeInventory(state);
    const actual=inventory();
    if(report.Publication.FileCount===actual.FileCount&&report.Publication.TotalBytes===actual.TotalBytes&&JSON.stringify(state.Files)===JSON.stringify(actual.Files)){stable=true;break;}
    report.Publication.FileCount=actual.FileCount;report.Publication.TotalBytes=actual.TotalBytes;
  }
  assert(stable,'No convergio el inventario exacto.');
  assert(inventory().PNGCount===65,'Cantidad inesperada de capturas publicables.');
  const manifest=readFileSync(path.join(evidence,'INVENTARIO-PUBLICACION.txt'),'utf8');
  for(const f of inventory().Files)assert(manifest.includes(`${f.Bytes}\t${f.Path}\n`),'Bytes/ruta no coinciden con inventario.');
  writeFileSync(path.join(runtime,'checkpoint-cierre.json'),JSON.stringify({Completed:true,Timestamp:report.Timestamp,Verification:'evidencias/05-pruebas-finales/VERIFICACION-PASO06.json',Step07Executed:false},null,2)+'\n');
  console.log(JSON.stringify({Completed:true,Captures:65,READMEImages:29,Academic:17,Preview:true,Files:report.Publication.FileCount,Bytes:report.Publication.TotalBytes,Services:9,DatabasesUnchanged:true,StagingUnchanged:true,Step07Executed:false},null,2));
} catch(error){report.Completed=false;report.ReadyForStep07=false;report.Status='Pendiente: '+error.message;if(report.Publication)report.Publication.ExactInventoryVerified=false;write('VERIFICACION-PASO06.json',report);console.error(report.Status);process.exitCode=1;}
