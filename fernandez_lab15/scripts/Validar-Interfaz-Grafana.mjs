import {writeFileSync} from 'node:fs';
import path from 'node:path';
import {root,runtime,readJson,save} from './Grafana-API.mjs';
import {browserSession,delay} from './Navegador-Lab15.mjs';
const dashboard=readJson(path.join(root,'observabilidad','grafana','dashboards','lab15-observabilidad.json'));
const s=await browserSession();
const report={Completed:false,Timestamp:new Date().toISOString(),Browser:s.browser,GlobalIndicators:null,IndividualServices:null,Filter:null,PanelChecks:[],AutomaticRefresh:null,Errors:[]};
const url='http://localhost:3000/d/lab15-observabilidad/lab-15-observabilidad-de-microservicios?orgId=1&from=now-15m&to=now&refresh=5s';
try {
  await s.login();await s.navigate(url+'&var-servicio='+encodeURIComponent('$__all'));
  await s.waitFor('document.querySelector("[data-testid=table-panel-6]")?.innerText.includes("UP")');
  const text=await s.evaluate('JSON.stringify(Object.fromEntries([2,3,4,5,6].map(id=>[id,document.querySelector(`[data-testid="${id===6?"table":"stat"}-panel-${id}"]`)?.innerText])))');
  const global=JSON.parse(text);report.GlobalIndicators=global;
  if(!/\b7\b/.test(global[2])||!/\b0\b/.test(global[3])||!/\b7\b/.test(global[4])||!global[5].includes('100%'))throw new Error('Indicadores globales de la UI no confirmados');
  report.IndividualServices={VisibleUP:(global[6].match(/\bUP\b/g)||[]).length,Text:global[6]};
  if(report.IndividualServices.VisibleUP!==7)throw new Error('La UI no muestra siete UP');
  const before=s.network.filter(n=>n.url.includes('/api/ds/query')).length;await delay(6500);
  const after=s.network.filter(n=>n.url.includes('/api/ds/query')).length;
  report.AutomaticRefresh={Interval:'5s',QueryResponsesBefore:before,QueryResponsesAfter:after,Verified:after>before};
  if(!report.AutomaticRefresh.Verified)throw new Error('Refresco automatico de consultas no observado');
  for(const p of dashboard.panels.filter(p=>p.type==='timeseries')) {
    await s.evaluate(`document.querySelector('[data-testid="timeseries-panel-${p.id}"]')?.scrollIntoView({block:'center',behavior:'instant'})`);
    await delay(900);
    const panel=await s.evaluate(`(()=>{const e=document.querySelector('[data-testid="timeseries-panel-${p.id}"]');return e?{text:e.innerText,hasCanvas:!!e.querySelector('canvas'),error:!!e.querySelector('[data-testid*="Panel status error"]')}:null})()`);
    report.PanelChecks.push({Id:p.id,Title:p.title,Rendered:!!panel,Canvas:!!panel?.hasCanvas,ConfigurationError:!!panel?.error,NoData:!!panel?.text?.includes('No data')});
    if(!panel||panel.error)throw new Error('Panel de interfaz no renderizado o con error: '+p.id);
  }
  await s.navigate(url+'&var-servicio=producto-service');
  await s.waitFor('document.querySelector("[data-testid=stat-panel-2]")?.innerText.includes("7") && !!document.querySelector("[data-testid=timeseries-panel-7]")');
  await s.evaluate('document.querySelector("[data-testid=timeseries-panel-7]").scrollIntoView({block:"center",behavior:"instant"})');
  await s.waitFor('document.querySelector("[data-testid=timeseries-panel-7]")?.innerText.includes("producto-service")');
  const filtered=await s.evaluate('JSON.stringify({memory:document.querySelector("[data-testid=timeseries-panel-7]").innerText,cpu:document.querySelector("[data-testid=timeseries-panel-8]").innerText,global:document.querySelector("[data-testid=stat-panel-2]").innerText,allStates:document.querySelector("[data-testid=table-panel-6]").innerText})');
  const f=JSON.parse(filtered);
  report.Filter={Selected:'producto-service',MemoryText:f.memory,CpuText:f.cpu,GlobalStillSeven:/\b7\b/.test(f.global),AllStatesStillSeven:(f.allStates.match(/\bUP\b/g)||[]).length===7,OtherMemoryJobsAbsent:!/(categoria-service|cliente-service|config-server|eureka-server|gateway-service|pedido-service)/.test(f.memory)};
  if(!report.Filter.GlobalStillSeven||!report.Filter.AllStatesStillSeven||!report.Filter.OtherMemoryJobsAbsent)throw new Error('Filtro UI no respeta alcance global y por servicio');
  report.QueryHTTPFailures=s.network.filter(n=>n.url.includes('/api/ds/query')&&n.status!==200);
  report.Errors=s.errors;
  if(report.QueryHTTPFailures.length||report.Errors.length)throw new Error('Errores de consulta o JavaScript observados');
  report.Completed=true;
} catch(error){report.Error=error.message;console.error(error.message);process.exitCode=1;}
finally {save('INTERFAZ-GRAFANA.json',report);writeFileSync(path.join(runtime,'checkpoint-ui.json'),JSON.stringify({Completed:report.Completed,Timestamp:report.Timestamp,Error:report.Error||null},null,2));await s.close();}
console.log(JSON.stringify({Completed:report.Completed,UP:report.IndividualServices?.VisibleUP,AutomaticRefresh:report.AutomaticRefresh?.Verified,Filter:report.Filter?.OtherMemoryJobsAbsent,Panels:report.PanelChecks.length,Error:report.Error||null}));
