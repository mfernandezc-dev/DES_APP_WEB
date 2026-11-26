// API y trafico exclusivamente GET. No escribe en APIs de negocio ni modifica servicios.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {queries,uiUrl} from './Consultas-Prometheus.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const step=process.argv.includes('--paso=06')?'06':process.argv.includes('--paso=05')?'05':'04';
const evidence=path.join(root,'evidencias',step==='06'?'05-pruebas-finales':step==='05'?'04-grafana':'03-prometheus');
const runtime=path.join(root,'.runtime','paso'+step);
mkdirSync(evidence,{recursive:true});mkdirSync(runtime,{recursive:true});
const base='http://localhost:9090';
const jobs=['config-server','eureka-server','gateway-service','categoria-service','producto-service','cliente-service','pedido-service'];
const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));
const args=process.argv.slice(2);
const noTraffic=args.includes('--sin-trafico');
const duration=Number(args.find(a=>a.startsWith('--duracion='))?.slice(11)||120);
const report={Step:step,Timestamp:new Date().toISOString(),HttpMethods:['GET'],Server:[],Targets:null,QueriesBefore:[],QueriesAfter:[],Traffic:[],Ranges:[],CounterComparison:[],Completed:false};
async function get(url,file) {
  const response=await fetch(url,{signal:AbortSignal.timeout(20000)});
  const text=await response.text();let body=null;
  try{body=JSON.parse(text);}catch{}
  if(file) writeFileSync(path.join(evidence,file),body?JSON.stringify(body,null,2):text,'utf8');
  return {url,status:response.status,contentType:response.headers.get('content-type'),body,text};
}
async function query(item,phase,time) {
  const url=new URL('/api/v1/query',base);url.searchParams.set('query',item.expr);if(time)url.searchParams.set('time',String(time));
  const result=await get(url.href,`consulta-${phase}-${item.id}.json`);
  if(result.status!==200||result.body?.status!=='success') throw new Error('PromQL no satisfactoria: '+item.id);
  const rows=result.body.data.result||[];
  return {id:item.id,expr:item.expr,title:item.title,url:url.href,ui:uiUrl(item.expr),http:result.status,resultType:result.body.data.resultType,series:rows.length,values:rows.map(row=>({metric:row.metric,value:row.value})),empty:rows.length===0,nonFinite:rows.filter(row=>!Number.isFinite(Number(row.value?.[1]))).map(row=>({metric:row.metric,value:row.value})),warnings:result.body.warnings||[],evidence:`consulta-${phase}-${item.id}.json`};
}
function validateTargets(body) {
  const active=body?.data?.activeTargets||[];
  return active.length===7&&active.every(target=>jobs.includes(target.labels.job)&&target.health==='up'&&target.lastError===''&&target.scrapeInterval==='5s'&&target.scrapeTimeout==='4s'&&/^http:\/\/127\.0\.0\.1:\d+\/actuator\/prometheus$/.test(target.scrapeUrl))&&new Set(active.map(t=>t.labels.job)).size===7;
}
function aggregate(item){return new Map(item.values.map(row=>[row.metric.job,Number(row.value[1])]));}
try {
  for(const endpoint of ['/','/-/healthy','/-/ready','/targets']) {
    const result=await get(base+endpoint,endpoint.startsWith('/-/')?endpoint.slice(3)+'.txt':null);
    report.Server.push({url:base+endpoint,http:result.status,contentType:result.contentType});
    if(result.status!==200) throw new Error('Endpoint del servidor no disponible: '+endpoint);
  }
  let targets;
  const deadline=Date.now()+120000;
  do {targets=await get(base+'/api/v1/targets');if(validateTargets(targets.body))break;await sleep(2000);}while(Date.now()<deadline);
  writeFileSync(path.join(evidence,'targets-iniciales.json'),JSON.stringify(targets.body,null,2));
  if(!validateTargets(targets.body)) throw new Error('No se confirmaron siete targets UP con intervalos correctos.');
  report.Targets=targets.body;
  const flags=await get(base+'/api/v1/status/flags');
  writeFileSync(path.join(runtime,'flags-originales.json'),JSON.stringify(flags.body,null,2));
  report.Flags={listenAddress:flags.body?.data?.['web.listen-address'],adminApiEnabled:flags.body?.data?.['web.enable-admin-api'],lifecycleEnabled:flags.body?.data?.['web.enable-lifecycle'],retention:flags.body?.data?.['storage.tsdb.retention.time']};
  for(const item of queries) report.QueriesBefore.push(await query(item,'antes'));
  const up=report.QueriesBefore.find(q=>q.id==='up');
  if(up.series!==7||up.values.some(row=>row.value[1]!=='1')) throw new Error('up no devuelve siete unos.');
  for(const [id,expected] of [['count-up','7'],['sum-up','7'],['down','0']]) {
    if(report.QueriesBefore.find(q=>q.id===id)?.values[0]?.value[1]!==expected) throw new Error('Resultado inesperado: '+id);
  }
  const start=Date.now();report.TrafficStart=new Date(start).toISOString();
  const routes=['http://localhost:8080/api/categorias','http://localhost:8080/api/productos','http://localhost:8080/api/clientes','http://localhost:8080/api/pedidos','http://localhost:8085/api/pedidos?detallado=true'];
  if(!noTraffic) {
    const rounds=Math.max(1,Math.floor(duration/5));
    for(let round=0;round<rounds;round++) {
      if(round)await sleep(Math.max(0,start+round*5000-Date.now()));
      for(const url of routes) {
        const response=await fetch(url,{headers:{Accept:'application/json'},signal:AbortSignal.timeout(20000)});
        const text=await response.text();const data=JSON.parse(text);
        const fallback=/temporal(?:mente)? no disponible|NO DISPONIBLE|"disponible"\s*:\s*false/i.test(text);
        report.Traffic.push({round:round+1,url,http:response.status,items:Array.isArray(data)?data.length:null,unexpectedFallback:fallback,timestamp:new Date().toISOString()});
        if(response.status!==200||fallback)throw new Error('Fallo de negocio durante trafico controlado: '+url);
      }
      if((round+1)%6===0)console.log(`Trafico GET moderado: ${round+1}/${rounds} rondas completadas`);
    }
    await sleep(Math.max(0,start+duration*1000-Date.now()));
    await sleep(6500); // permitir un scrape posterior al ultimo incremento, sin apurar el intervalo.
  }
  const end=Date.now();report.TrafficEnd=new Date(end).toISOString();
  for(const item of queries) report.QueriesAfter.push(await query(item,'despues',end/1000));
  const before=aggregate(report.QueriesBefore.find(q=>q.id==='http-exitosas'));
  const after=aggregate(report.QueriesAfter.find(q=>q.id==='http-exitosas'));
  for(const job of jobs)report.CounterComparison.push({job,before:before.get(job),after:after.get(job),delta:after.get(job)-before.get(job),increased:after.get(job)>before.get(job)});
  const businessBefore=aggregate(report.QueriesBefore.find(q=>q.id==='http-negocio-contador'));
  const businessAfter=aggregate(report.QueriesAfter.find(q=>q.id==='http-negocio-contador'));
  report.BusinessCounterComparison=[...businessAfter].map(([job,value])=>({job,before:businessBefore.get(job),after:value,delta:value-businessBefore.get(job)}));
  const gatewayBefore=new Map(report.QueriesBefore.find(q=>q.id==='gateway-contador').values.map(row=>[row.metric.routeId,Number(row.value[1])]));
  report.GatewayCounterComparison=report.QueriesAfter.find(q=>q.id==='gateway-contador').values.map(row=>({routeId:row.metric.routeId,before:gatewayBefore.get(row.metric.routeId),after:Number(row.value[1]),delta:Number(row.value[1])-gatewayBefore.get(row.metric.routeId)}));
  for(const id of ['up','http-tasa-negocio','http-promedio-ms','gateway-tasa']) {
    const item=queries.find(q=>q.id===id);const url=new URL('/api/v1/query_range',base);
    url.searchParams.set('query',item.expr);url.searchParams.set('start',String(start/1000));url.searchParams.set('end',String(end/1000));url.searchParams.set('step','5s');
    const result=await get(url.href,`query-range-${id}.json`);
    if(result.status!==200||result.body?.status!=='success')throw new Error('query_range no satisfactoria: '+id);
    report.Ranges.push({id,expr:item.expr,url:url.href,http:result.status,series:result.body.data.result.length,points:result.body.data.result.map(row=>({metric:row.metric,points:row.values.length,nonFinite:row.values.filter(v=>!Number.isFinite(Number(v[1]))).length})),evidence:`query-range-${id}.json`});
  }
  const final=await get(base+'/api/v1/targets','targets-finales.json');report.FinalTargets=final.body;
  report.Completed=validateTargets(final.body)&&report.QueriesAfter.find(q=>q.id==='up').values.every(row=>row.value[1]==='1')&&(noTraffic||(report.Traffic.length===Math.floor(duration/5)*5&&report.GatewayCounterComparison.length===4&&report.GatewayCounterComparison.every(row=>row.delta>=Math.floor(duration/5))))&&(noTraffic||report.CounterComparison.every(row=>row.increased))&&report.Ranges.every(row=>row.series>0);
} catch(error) {report.Error=error.message;console.error(error.message);process.exitCode=1;}
finally {writeFileSync(path.join(evidence,'CONSULTAS-PROMETHEUS.json'),JSON.stringify(report,null,2));}
console.log(JSON.stringify({Completed:report.Completed,Targets:report.FinalTargets?.data?.activeTargets?.length,Requests:report.Traffic.length,Queries:report.QueriesAfter.length,Ranges:report.Ranges.length},null,2));
