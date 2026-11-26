// Solo HTTP GET contra servicios reales. Nunca publica originales con rutas locales.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {createHash} from 'node:crypto';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const runtime=path.join(root,'.runtime','paso03');
const evidence=path.join(root,'evidencias','02-micrometer');
const services=[['producto-service',8083],['categoria-service',8082],['cliente-service',8084],['pedido-service',8085],['config-server',8888],['eureka-server',8761],['gateway-service',8080]];
const routes=[['categoria-service','categorias'],['producto-service','productos'],['cliente-service','clientes'],['pedido-service','pedidos']];
const reference=['application_ready_time_seconds','application_started_time_seconds','jvm_memory_used_bytes','jvm_memory_max_bytes','jvm_threads_live_threads','process_cpu_usage','system_cpu_usage','process_uptime_seconds','http_server_requests_seconds_count','http_server_requests_seconds_sum','hikaricp_connections_active','hikaricp_connections_max','jdbc_connections_active','jdbc_connections_max','resilience4j_circuitbreaker_calls_seconds_count'];
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
mkdirSync(runtime,{recursive:true});mkdirSync(evidence,{recursive:true});
function redact(text) {
  const changes=[];
  const safe=text.replace(/\b([A-Za-z_][A-Za-z0-9_]*)="((?:\\.|[^"\\])*)"/g,(whole,key,value)=>{
    const sensitiveKey=/password|passwd|token|secret|cookie|authorization|email|correo|dni|direccion/i.test(key);
    const localPath=/(?:[A-Za-z]:\\|\/Users\/|\/home\/)/.test(value);
    const credentialUrl=/\/\/[^\s/:]+:[^\s/@]+@/.test(value);
    if (sensitiveKey||localPath||credentialUrl) {
      changes.push({label:key,reason:localPath?'ruta local absoluta':'valor sensible'});
      return `${key}="[REDACTADO]"`;
    }
    return whole;
  });
  return {text:safe,changes};
}
function parse(text) {
  const samples=[],invalid=[];let help=0,type=0;
  for (const line of text.split(/\r?\n/)) {
    if (!line.trim()) continue;
    if (line.startsWith('# HELP ')) {help++;continue;}
    if (line.startsWith('# TYPE ')) {type++;continue;}
    if (line.startsWith('#')) continue;
    const match=line.match(/^([A-Za-z_:][A-Za-z0-9_:]*)(?:\{(.*)\})?\s+([+-]?(?:\d+(?:\.\d*)?(?:[eE][+-]?\d+)?|Inf)|NaN)(?:\s+\d+)?(?:\s+#.*)?$/);
    if (!match) {invalid.push(line.slice(0,80));continue;}
    const labels={};
    for (const label of (match[2]||'').matchAll(/([A-Za-z_][A-Za-z0-9_]*)="((?:\\.|[^"\\])*)"/g)) {
      labels[label[1]]=JSON.parse(`"${label[2]}"`);
    }
    const value=Number(match[3]);
    samples.push({name:match[1],labels,value:Number.isFinite(value)?value:match[3],finite:Number.isFinite(value)});
  }
  return {samples,help,type,invalid};
}
async function scrape(service,port,phase,publish=false) {
  const url=`http://localhost:${port}/actuator/prometheus`;
  const response=await fetch(url,{headers:{Accept:'text/plain;version=0.0.4'},signal:AbortSignal.timeout(30000)});
  const bytes=Buffer.from(await response.arrayBuffer());
  const original=path.join(runtime,`${service}-prometheus-${phase}.original.txt`);
  writeFileSync(original,bytes);
  const safe=redact(bytes.toString('utf8'));
  const parsed=parse(safe.text);
  const contentType=response.headers.get('content-type')||'';
  const valid=response.status===200&&/^(text\/plain|application\/openmetrics-text)/i.test(contentType)&&parsed.help>0&&parsed.type>0&&parsed.samples.some(s=>s.finite)&&parsed.invalid.length===0;
  const file=`${service}-prometheus.txt`;
  if (publish) writeFileSync(path.join(evidence,file),safe.text,'utf8');
  return {service,port,url,status:response.status,contentType,timestamp:new Date().toISOString(),bytes:bytes.length,helpLines:parsed.help,typeLines:parsed.type,numericSamples:parsed.samples.filter(s=>s.finite).length,invalidLines:parsed.invalid,valid,redactions:safe.changes,originalSHA256:sha(bytes),publicSHA256:publish?sha(Buffer.from(safe.text)):null,evidence:publish?file:null,samples:parsed.samples};
}
function select(samples,name,filter={}) {return samples.filter(s=>s.name===name&&Object.entries(filter).every(([k,v])=>s.labels[k]===v));}
function count(samples,name,filter) {return select(samples,name,filter).reduce((total,s)=>total+(typeof s.value==='number'?s.value:0),0);}
const report={Step:'03',Timestamp:new Date().toISOString(),Target:'Servicios reales localhost; sin servidor Prometheus, Docker ni mocks',HttpMethods:['GET'],Prometheus:[],Traffic:[],HttpCounterComparison:[],MetricsByService:[],ResilienceCalls:[],Completed:false};
try {
  const regression=JSON.parse(readFileSync(path.join(evidence,'REGRESION-ACTUATOR.json'),'utf8').replace(/^\uFEFF/,''));
  if (!regression.Completed) throw new Error('La regresion Actuator/negocio debe ser satisfactoria antes de medir trafico.');
  const before={};
  for (const [service,port] of services) {
    before[service]=await scrape(service,port,'antes');
    if (!before[service].valid) throw new Error(`Exposicion inicial invalida: ${service}`);
  }
  for(let round=1;round<=3;round++) {
    for(const [service,route] of routes) {
      const url=`http://localhost:8080/api/${route}`;
      const response=await fetch(url,{headers:{Accept:'application/json'},signal:AbortSignal.timeout(30000)});
      const text=await response.text();
      const fallback=/temporal(?:mente)? no disponible|NO DISPONIBLE|"disponible"\s*:\s*false/i.test(text);
      const data=JSON.parse(text);
      report.Traffic.push({round,service,url,status:response.status,items:Array.isArray(data)?data.length:null,unexpectedFallback:fallback});
      if(response.status!==200||fallback) throw new Error(`Fallo funcional durante ronda ${round}: ${service}`);
    }
  }
  const after={};
  for(const [service,port] of services) {
    const result=await scrape(service,port,'despues',true);after[service]=result;
    const {samples,...summary}=result;report.Prometheus.push(summary);
    const names=[...new Set(samples.map(s=>s.name))].sort();
    const selected=reference.filter(name=>names.includes(name));
    for(const name of names.filter(name=>name.startsWith('resilience4j_'))) if(!selected.includes(name)) selected.push(name);
    report.MetricsByService.push({service,sampleNames:names,reference:reference.map(name=>({name,available:names.includes(name),applicable:(!/^(hikaricp_|jdbc_)/.test(name)||routes.some(([s])=>s===service))&&(!name.startsWith('resilience4j_')||['producto-service','cliente-service','pedido-service'].includes(service))})),foundMetrics:selected.map(name=>({name,samples:select(samples,name)}))});
    if(!result.valid) throw new Error(`Exposicion final invalida: ${service}`);
  }
  for(const [service,route] of routes) {
    const filter={uri:`/api/${route}`,method:'GET',status:'200'};
    const metric='http_server_requests_seconds_count';
    const first=count(before[service].samples,metric,filter),last=count(after[service].samples,metric,filter);
    report.HttpCounterComparison.push({service,metric,filter,before:first,after:last,delta:last-first,increased:last-first>=3,beforeSeries:select(before[service].samples,metric,filter),afterSeries:select(after[service].samples,metric,filter)});
    const gatewayName='spring_cloud_gateway_requests_seconds_count';
    const gatewayFilter={routeId:service,httpMethod:'GET',httpStatusCode:'200'};
    const gatewayBefore=count(before['gateway-service'].samples,gatewayName,gatewayFilter),gatewayAfter=count(after['gateway-service'].samples,gatewayName,gatewayFilter);
    report.HttpCounterComparison.push({service:'gateway-service',routeId:service,metric:gatewayName,filter:gatewayFilter,before:gatewayBefore,after:gatewayAfter,delta:gatewayAfter-gatewayBefore,increased:gatewayAfter-gatewayBefore>=3,beforeSeries:select(before['gateway-service'].samples,gatewayName,gatewayFilter),afterSeries:select(after['gateway-service'].samples,gatewayName,gatewayFilter)});
  }
  for(const service of ['producto-service','cliente-service','pedido-service']) {
    const name='resilience4j_circuitbreaker_calls_seconds_count';
    report.ResilienceCalls.push({service,metric:name,successful:count(after[service].samples,name,{kind:'successful'}),failed:count(after[service].samples,name,{kind:'failed'}),series:select(after[service].samples,name)});
  }
  report.Completed=report.Prometheus.length===7&&report.Prometheus.every(s=>s.valid)&&report.HttpCounterComparison.every(c=>c.increased)&&report.ResilienceCalls.every(c=>c.failed===0)&&report.Traffic.length===12;
} catch(error) {report.Error=error.message;console.error(error.message);process.exitCode=1;}
finally {writeFileSync(path.join(evidence,'PROMETHEUS-HTTP.json'),JSON.stringify(report,null,2));}
console.log(JSON.stringify({Completed:report.Completed,Endpoints:report.Prometheus.length,ControlledGets:report.Traffic.length,Counters:report.HttpCounterComparison.map(({service,routeId,before,after,delta})=>({service,routeId,before,after,delta}))},null,2));
