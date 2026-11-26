// Capturas nuevas necesarias. Los originales anteriores no se tocan.
import {mkdirSync,writeFileSync,existsSync} from 'node:fs';
import path from 'node:path';
import {root,runtime,evidence,readJson,save} from './Grafana-API.mjs';
import {browserSession,delay} from './Navegador-Lab15.mjs';
const selected=path.join(root,'evidencias','readme');mkdirSync(selected,{recursive:true});
const file=path.join(evidence,'CAPTURAS-PASO06.json');
const only=process.argv.find(a=>a.startsWith('--solo='))?.slice(7).split(',').map(Number);
const report={method:'Chrome real + CDP por pipe + PrintWindow; ocultamiento de pixeles personales documentado',captures:existsSync(file)?readJson(file).captures:[],error:null};
const s=await browserSession();
const base='http://localhost:3000/d/lab15-observabilidad/lab-15-observabilidad-de-microservicios';
const dashboard=(job='$__all')=>base+'?orgId=1&from=now-15m&to=now&refresh=5s&var-servicio='+encodeURIComponent(job);
async function capture(n,name,url,action){
  if(only&&!only.includes(n))return;
  if(!only&&report.captures.some(c=>c.file===name)&&existsSync(path.join(selected,name)))return;
  await s.navigate(url);let redactions=[];
  if(action)redactions=await action()||[];
  if(n===30&&!redactions.length)throw new Error('Pedido detallado requiere ocultamiento verificable; no se guarda imagen sin proteccion.');
  const originalFile=redactions.length?path.join(runtime,name+'.original.png'):undefined;
  const shot=await s.screenshot(path.join(selected,name),{redactions,originalFile});
  report.captures=report.captures.filter(c=>c.file!==name);report.captures.push({file:name,path:'evidencias/readme/'+name,requestedUrl:url,displayedUrl:shot.url,timestamp:shot.timestamp,bytes:shot.bytes,redactions,source:'Captura nueva de ejecucion real PASO06'});
  writeFileSync(file,JSON.stringify(report,null,2));console.log(name+': captura real guardada');
}
async function graphReady(title){await s.waitFor('!!document.querySelector("[data-testid=stat-panel-2]")');await s.evaluate(`(()=>{const e=[...document.querySelectorAll('h2')].find(e=>e.textContent===${JSON.stringify(title)});e?.scrollIntoView({block:'start',behavior:'instant'});})()`);await delay(2200);}
try{
  await capture(16,'16-prometheus-targets-up.png','http://localhost:9090/targets',async()=>{
    await s.waitFor('document.body.innerText.includes("producto-service")');
    await s.evaluate('(async()=>{for(const b of [...document.querySelectorAll("button[data-accordion-control]")]){if(b.getAttribute("aria-expanded")==="true"){b.click();await new Promise(r=>setTimeout(r,100));}}})()');await delay(600);
  });
  await capture(29,'29-gateway-productos.png','http://localhost:8080/api/productos',async()=>{await s.evaluate('document.querySelector("input[type=checkbox]")?.click()');await delay(500);});
  await capture(30,'30-pedido-detallado.png','http://localhost:8085/api/pedidos?detallado=true',async()=>{
    await s.evaluate('document.querySelector("input[type=checkbox]")?.click()');await delay(700);
    return await s.evaluate(String.raw`(()=>{const out=[];const walk=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT);let node;const frame=(outerWidth-innerWidth)/2,top=outerHeight-innerHeight-frame;while(node=walk.nextNode()){if(['SCRIPT','STYLE'].includes(node.parentElement?.tagName))continue;for(const m of node.textContent.matchAll(/"(?:nombre|nombres|apellido|apellidos|nro_?dni|nroDni|email|correo|direccion|telefono)"\s*:\s*(?:"(?:\\.|[^"\\])*"|\d+)/gi)){const range=document.createRange();range.setStart(node,m.index);range.setEnd(node,m.index+m[0].length);for(const r of range.getClientRects()){if(r.bottom<0||r.top>innerHeight)continue;out.push({x:Math.max(frame,r.x+frame-2),y:Math.max(top,r.y+top-2),width:r.width+4,height:r.height+4,label:m[0].split(':')[0].replaceAll('"','')});}}}return out;})()`);
  });
  await s.login();
  const panes={lab15:{datasource:'prometheus-lab15',queries:[{refId:'A',expr:'up',instant:true,range:false,editorMode:'code',datasource:{type:'prometheus',uid:'prometheus-lab15'}}],range:{from:'now-15m',to:'now'}}};
  await s.navigate('http://localhost:3000/explore?schemaVersion=1&panes='+encodeURIComponent(JSON.stringify(panes))+'&orgId=1');await s.waitFor('document.body.innerText.includes("config-server")');
  const explore=await s.evaluate('document.body.innerText');
  report.Explore={Verified:['config-server','eureka-server','gateway-service','categoria-service','producto-service','cliente-service','pedido-service'].every(j=>explore.includes(j))&&/Result series:\s*7/.test(explore),Query:'up',Series:7,OriginalScreenshotReused:'evidencias/04-grafana/07-explore-consulta-up.png'};
  if(!report.Explore.Verified)throw new Error('Explore actual no muestra las siete series');
  await capture(23,'23-grafana-dashboard-general.png',dashboard(),async()=>{await s.waitFor('document.querySelector("[data-testid=stat-panel-2]")?.innerText.includes("7") && document.querySelector("[data-testid=table-panel-6]")?.innerText.includes("producto-service")');await delay(2200);});
  const measured=readJson(path.join(evidence,'CONSULTAS-PROMETHEUS.json'));const demo=new URL(dashboard());demo.searchParams.set('from',String(Date.parse(measured.TrafficStart)-60000));demo.searchParams.set('to',String(Date.parse(measured.TrafficEnd)+60000));
  await capture(25,'25-grafana-metricas-http.png',demo.href,async()=>{await graphReady('HTTP de negocio · solicitudes por segundo');});
  await capture(28,'28-grafana-filtro-producto.png',dashboard('producto-service'),async()=>{await graphReady('Memoria JVM utilizada');await s.waitFor('document.querySelector("[data-testid=timeseries-panel-7]")?.innerText.includes("producto-service")');});
}catch(error){report.error=error.message;process.exitCode=1;console.error(error.message);}
finally{report.captures.sort((a,b)=>a.file.localeCompare(b.file));writeFileSync(file,JSON.stringify(report,null,2));writeFileSync(path.join(runtime,'checkpoint-capturas-nuevas.json'),JSON.stringify({Completed:!report.error,Count:report.captures.length,Error:report.error},null,2));await s.close();}
