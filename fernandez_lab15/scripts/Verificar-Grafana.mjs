import path from 'node:path';
import {writeFileSync,readFileSync,existsSync} from 'node:fs';
import {root,runtime,step,readJson,credentials,api,save} from './Grafana-API.mjs';
const auth=credentials();
const call=(url,options={})=>api(url,{auth,...options});
const report={Step:step,Timestamp:new Date().toISOString(),Target:'Grafana real -> Prometheus real -> siete microservicios',Completed:false,Panels:[],Filters:[]};
const jobs=['config-server','eureka-server','gateway-service','categoria-service','producto-service','cliente-service','pedido-service'];
const dashboard=readJson(path.join(root,'observabilidad','grafana','dashboards','lab15-observabilidad.json'));
const proxy='/api/datasources/proxy/uid/prometheus-lab15';
async function prom(expr,file) {
  const result=await call(proxy+'/api/v1/query?query='+encodeURIComponent(expr));
  if(file)save(file,result);
  if(result.body.status!=='success')throw new Error('Consulta PromQL por proxy no satisfactoria');
  return result;
}
function resolve(expr,service='.*'){return expr.replaceAll('${servicio:regex}',service).replaceAll('$__rate_interval','1m');}
try {
  report.Health=await call('/api/health',{auth:null});save('grafana-health.json',report.Health);
  report.Datasource=await call('/api/datasources/uid/prometheus-lab15');save('datasource-prometheus.json',report.Datasource);
  const ds=report.Datasource.body;
  if(ds.name!=='Prometheus'||ds.uid!=='prometheus-lab15'||ds.type!=='prometheus'||ds.url!=='http://127.0.0.1:9090'||ds.access!=='proxy'||!ds.isDefault||!ds.readOnly||ds.jsonData.timeInterval!=='5s')throw new Error('Datasource provisionado no coincide con el contrato.');
  const sources=await call('/api/datasources');
  report.AllDatasources=sources.body.map(d=>({Name:d.name,Type:d.type,UID:d.uid,URL:d.url}));
  if(report.AllDatasources.length!==1||report.AllDatasources[0].Type!=='prometheus')throw new Error('Se esperaba exclusivamente Prometheus, no conexiones a bases del proyecto.');
  report.DatasourceHealth=await call('/api/datasources/uid/prometheus-lab15/health');save('datasource-health.json',report.DatasourceHealth);
  if(report.DatasourceHealth.body.status!=='OK')throw new Error('Save & test equivalente no satisfactorio.');
  report.Up=await prom('up','grafana-query-up.json');
  const up=report.Up.body.data.result;
  if(up.length!==7||up.some(r=>r.value[1]!=='1')||jobs.some(j=>!up.some(r=>r.metric.job===j)))throw new Error('up no devuelve los siete servicios con valor 1.');
  report.Dashboard=await call('/api/dashboards/uid/lab15-observabilidad');save('dashboard-cargado.json',report.Dashboard);
  if(!report.Dashboard.body.meta.provisioned||report.Dashboard.body.dashboard.title!==dashboard.title)throw new Error('Dashboard no provisionado correctamente.');
  const settings=await call('/api/admin/settings');
  const selected={};
  for(const [section,keys] of Object.entries({server:['http_addr','http_port'],database:['type','path'],paths:['data','logs','plugins','provisioning'],users:['allow_sign_up','allow_org_create','default_theme'],'auth.anonymous':['enabled'],analytics:['reporting_enabled','check_for_updates','check_for_plugin_updates'],plugins:['preinstall_disabled','public_key_retrieval_disabled'],dashboards:['min_refresh_interval']})){
    selected[section]=Object.fromEntries(keys.map(k=>[k,settings.body[section]?.[k]]));
  }
  report.EffectiveSettings=selected;save('configuracion-efectiva-segura.json',selected);
  if(selected.server.http_addr!=='127.0.0.1'||selected.server.http_port!=='3000'||selected.database.type!=='sqlite3'||selected['auth.anonymous'].enabled!=='false'||selected.users.allow_sign_up!=='false')throw new Error('Configuracion efectiva insegura.');
  if(selected.users.allow_org_create!=='false'||selected.users.default_theme!=='dark'||Object.values(selected.analytics).some(v=>v!=='false')||selected.plugins.preinstall_disabled!=='true'||selected.plugins.public_key_retrieval_disabled!=='true'||selected.dashboards.min_refresh_interval!=='5s')throw new Error('Telemetria, plugins, tema o refresco no coinciden con la configuracion local.');
  // /api/admin/settings sanea textos como URL: codifica Unicode y normaliza
  // espacios. Contrastar la representacion y, ademas, las rutas reales del INI.
  const normalized=p=>path.resolve(decodeURIComponent(p)).toLowerCase().replace(/\s+/g,' ');
  const ops=path.join(root,'.runtime','grafana');
  if([...Object.values(selected.paths),selected.database.path].some(p=>!normalized(p).startsWith(normalized(ops)+path.sep)))throw new Error('Representacion de rutas operativas no corresponde al laboratorio');
  const config=readFileSync(path.join(ops,'grafana-lab15.ini'),'utf8');
  const pathsSection=config.split('[paths]')[1].split('[')[0];
  const databaseSection=config.split('[database]')[1].split('[')[0];
  const actualPaths=Object.fromEntries(['data','logs','plugins','provisioning'].map(k=>[k,pathsSection.match(new RegExp('^'+k+'\\s*=\\s*(.+)$','m'))[1].trim()]));
  actualPaths.sqlite=databaseSection.match(/^path\s*=\s*(.+)$/m)[1].trim();
  report.ActualOperationalPaths=actualPaths;
  if(Object.values(actualPaths).some(p=>!path.resolve(p).toLowerCase().startsWith(path.resolve(ops).toLowerCase()+path.sep)||!existsSync(p)))throw new Error('Datos operativos reales fuera de .runtime/grafana o ausentes');
  const anonymous=await call('/api/dashboards/uid/lab15-observabilidad',{auth:null,allowFailure:true});
  report.AnonymousAccess={http:anonymous.http,Blocked:anonymous.http===401};
  if(!report.AnonymousAccess.Blocked)throw new Error('Acceso anonimo no bloqueado');
  if(!process.argv.includes('--solo-conexion')) {
    const from=String(Date.now()-180000),to=String(Date.now());
    for(const panel of dashboard.panels.filter(p=>p.targets)) {
      const expr=resolve(panel.targets[0].expr);
      const instant=panel.targets[0].instant===true;
      const model={...panel.targets[0],expr,instant,range:!instant,intervalMs:5000,maxDataPoints:300};
      const result=await call('/api/ds/query',{method:'POST',body:{from,to,queries:[model]}});
      save(`panel-${String(panel.id).padStart(2,'0')}.json`,result);
      const a=result.body.results?.A;
      const frames=a?.frames||[];
      const samples=frames.flatMap(f=>f.data?.values?.slice(1).flat()||[]);
      const valid=result.http===200&&!a?.error&&frames.length>0&&samples.some(v=>v!==null&&Number.isFinite(Number(v)));
      report.Panels.push({Id:panel.id,Title:panel.title,Expression:expr,Http:result.http,Frames:frames.length,NumericSamples:samples.filter(v=>v!==null&&Number.isFinite(Number(v))).length,Error:a?.error||null,Valid:valid});
      if(!valid)throw new Error('Panel sin datos reales o con error: '+panel.id);
    }
    for(const job of jobs) {
      const result=await prom(`up{job="${job}"}`);
      const memory=await prom(`sum by (job) (jvm_memory_used_bytes{job="${job}"}) / 1024 / 1024`);
      const http=await prom(resolve(dashboard.panels.find(p=>p.id===11).targets[0].expr,job));
      const jdbc=await prom(`hikaricp_connections_active{job="${job}"}`);
      const row={Job:job,UpSeries:result.body.data.result.length,MemoryJobs:memory.body.data.result.map(r=>r.metric.job),HttpJobs:http.body.data.result.map(r=>r.metric.job),JdbcSeries:jdbc.body.data.result.length};
      const expectedJdbc=['categoria-service','producto-service','cliente-service','pedido-service'].includes(job)?1:0;
      row.Valid=row.UpSeries===1&&row.MemoryJobs.length===1&&row.MemoryJobs[0]===job&&row.HttpJobs.every(j=>j===job)&&row.JdbcSeries===expectedJdbc;
      report.Filters.push(row);if(!row.Valid)throw new Error('Filtro de servicio incorrecto: '+job);
    }
    save('filtros-verificados.json',report.Filters);
    report.GlobalIndicatorsIgnoreFilter=dashboard.panels.filter(p=>p.id>=2&&p.id<=6).every(p=>!p.targets[0].expr.includes('servicio'));
    report.JdbcJobs=(await prom('hikaricp_connections_active')).body.data.result.map(r=>r.metric.job);
    report.ResilienceJobs=(await prom('count by (job) (resilience4j_circuitbreaker_calls_seconds_count)')).body.data.result.map(r=>r.metric.job);
    const before=await prom('process_uptime_seconds{job="producto-service"}');
    await new Promise(r=>setTimeout(r,6500));
    const after=await prom('process_uptime_seconds{job="producto-service"}');
    report.LiveUpdate={Before:before.body.data.result[0].value,After:after.body.data.result[0].value,Increased:Number(after.body.data.result[0].value[1])>Number(before.body.data.result[0].value[1])};
    if(!report.LiveUpdate.Increased||!report.GlobalIndicatorsIgnoreFilter)throw new Error('Actualizacion/filtro global no confirmado');
  }
  report.Completed=true;
} catch(error) {report.Error=error.message;process.exitCode=1;console.error(error.message);}
const file=process.argv.includes('--solo-conexion')?'CONEXION-GRAFANA.json':'CONSULTAS-GRAFANA.json';
save(file,report);writeFileSync(path.join(runtime,'checkpoint-'+(process.argv.includes('--solo-conexion')?'E':'FG')+'.json'),JSON.stringify({Completed:report.Completed,Timestamp:report.Timestamp,Evidence:file,Error:report.Error||null},null,2));
console.log(JSON.stringify({Completed:report.Completed,UpSeries:report.Up?.body?.data?.result?.length,Panels:report.Panels.length,Filters:report.Filters.length,Error:report.Error||null}));
