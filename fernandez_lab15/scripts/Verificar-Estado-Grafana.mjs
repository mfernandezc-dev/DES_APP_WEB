import path from 'node:path';
import {root,readJson,api,save} from './Grafana-API.mjs';
const dashboard=readJson(path.join(root,'observabilidad','grafana','dashboards','lab15-observabilidad.json'));
const panel=dashboard.panels.find(p=>p.id===6);
const report={Completed:false,Timestamp:new Date().toISOString(),Panel:6,Query:'up',Rows:[]};
try {
  const deadline=Date.now()+45000;let loaded;
  do {loaded=await api('/api/dashboards/uid/lab15-observabilidad');if(loaded.body.dashboard.panels.find(p=>p.id===6)?.transformations?.[0]?.id==='seriesToRows')break;await new Promise(r=>setTimeout(r,1000));}while(Date.now()<deadline);
  report.ProvisioningConfirmed=loaded.body.dashboard.panels.find(p=>p.id===6)?.transformations?.[0]?.id==='seriesToRows';
  if(!report.ProvisioningConfirmed)throw new Error('Provisioning de la tabla final no confirmado');
  const result=await api('/api/ds/query',{method:'POST',body:{from:String(Date.now()-300000),to:String(Date.now()),queries:[{...panel.targets[0],intervalMs:5000,maxDataPoints:300}]}});
  save('panel-06-tabla.json',result);
  const frames=result.body.results?.A?.frames||[];
  for(const frame of frames){const fields=frame.schema.fields;for(let value=0;value<fields.length;value++){const field=fields[value];if(field.type==='number'&&field.labels?.job){for(const sample of frame.data.values[value])report.Rows.push({job:field.labels.job,value:sample});}}}
  report.RenderTransformations=panel.transformations;
  const jobs=['categoria-service','producto-service','cliente-service','pedido-service','gateway-service','eureka-server','config-server'];
  if(report.Rows.length!==7||report.Rows.some(r=>r.value!==1)||jobs.some(j=>!report.Rows.some(r=>r.job===j)))throw new Error('La tabla no tiene siete estados reales UP.');
  report.Completed=true;
}catch(error){report.Error=error.message;console.error(error.message);process.exitCode=1;}
save('TABLA-ESTADOS-GRAFANA.json',report);
console.log(JSON.stringify({Completed:report.Completed,Rows:report.Rows.length,Error:report.Error||null}));
