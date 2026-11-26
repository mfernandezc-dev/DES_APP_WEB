import {readFileSync,writeFileSync,existsSync} from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {root,runtime,evidence,readJson} from './Grafana-API.mjs';
import {browserSession,delay} from './Navegador-Lab15.mjs';
const only=process.argv.find(a=>a.startsWith('--solo='))?.slice(7).split(',').map(Number);
const manifest=path.join(evidence,'CAPTURAS-PASO05.json');
const previous=existsSync(manifest)?readJson(manifest):{captures:[]};
const report={method:'Chrome real + CDP por pipe + PrintWindow; URL visible; sin HTML fabricado',captures:previous.captures,error:null};
const session=await browserSession();report.browser=session.browser;
const dash='http://localhost:3000/d/lab15-observabilidad/lab-15-observabilidad-de-microservicios';
const dashboardUrl=(job='$__all')=>dash+'?orgId=1&from=now-15m&to=now&refresh=5s&var-servicio='+encodeURIComponent(job);
const demonstrationUrl=()=>{
  const measured=readJson(path.join(evidence,'CONSULTAS-PROMETHEUS.json'));
  const url=new URL(dashboardUrl());
  url.searchParams.set('from',String(Date.parse(measured.TrafficStart)-60000));
  url.searchParams.set('to',String(Date.parse(measured.TrafficEnd)+60000));
  return url.href;
};
let logged=false;
async function capture(n,file,url,{wait,scroll,action}={}) {
  if(only&&!only.includes(n))return;
  if(!only&&report.captures.some(c=>c.file===file)&&existsSync(path.join(evidence,file)))return;
  await session.navigate(url);
  if(wait)await session.waitFor(wait,60000);
  if(action)await action();
  if(scroll){await session.evaluate(`(()=>{const titles=[...document.querySelectorAll('h1,h2,h3,h4,h5,h6,[data-testid]')];const e=titles.find(e=>e.textContent.trim()===${JSON.stringify(scroll)});if(!e)return false;e.scrollIntoView({block:'start',behavior:'instant'});return true;})()`);await delay(1500);}
  const shot=await session.screenshot(path.join(evidence,file));
  report.captures=report.captures.filter(c=>c.file!==file);report.captures.push({file,requestedUrl:url,displayedUrl:shot.url,timestamp:shot.timestamp,bytes:shot.bytes,source:'Ventana real de Chrome',redactions:[]});
  writeFileSync(manifest,JSON.stringify(report,null,2));console.log(file+': ventana real guardada');
}
try {
  if(process.argv.includes('--probe')) {
    await session.login();await session.navigate(dashboardUrl());await delay(4500);
    const probe=await session.evaluate('JSON.stringify({url:location.href,text:document.body.innerText,buttons:[...document.querySelectorAll("button")].map(e=>({text:e.innerText,aria:e.getAttribute("aria-label")})),panels:[...document.querySelectorAll("[data-panelid],[data-testid],h1,h2,h3,h4,h5,h6")].map(e=>({tag:e.tagName,id:e.id,test:e.getAttribute("data-testid"),panel:e.getAttribute("data-panelid"),text:(e.innerText||e.textContent||"").slice(0,100)})).slice(0,150)})');
    writeFileSync(path.join(runtime,'dashboard-dom.json'),probe);console.log(probe);
  } else {
    await capture(1,'01-descarga-grafana.png','https://grafana.com/grafana/download/13.3.2?edition=oss&platform=windows',{wait:'document.body.innerText.includes("13.3.2")',action:async()=>{await session.evaluate('(()=>{const e=[...document.querySelectorAll("h1,h2,h3,a")].find(e=>/Standalone Windows|Windows/.test(e.textContent));e?.scrollIntoView({block:"center"});})()');}});
    await capture(2,'02-version-grafana.png',pathToFileURL(path.join(evidence,'grafana-version.txt')).href);
    await capture(3,'03-grafana-login.png','http://localhost:3000/login',{wait:'!!document.querySelector("input[type=password]")'});
    await session.login();logged=true;
    await capture(4,'04-grafana-inicio.png','http://localhost:3000/',{wait:'document.body.innerText.includes("Home")||document.body.innerText.includes("Welcome")'});
    await capture(5,'05-datasource-prometheus.png','http://localhost:3000/connections/datasources/edit/prometheus-lab15',{wait:'document.body.innerText.includes("Prometheus")',action:async()=>{await delay(1500);}});
    await capture(6,'06-conexion-prometheus-correcta.png','http://localhost:3000/api/datasources/uid/prometheus-lab15/health',{wait:'document.body.innerText.includes("OK")'});
    const panes={lab15:{datasource:'prometheus-lab15',queries:[{refId:'A',expr:'up',instant:true,range:false,editorMode:'code',datasource:{type:'prometheus',uid:'prometheus-lab15'}}],range:{from:'now-15m',to:'now'}}};
    await capture(7,'07-explore-consulta-up.png','http://localhost:3000/explore?schemaVersion=1&panes='+encodeURIComponent(JSON.stringify(panes))+'&orgId=1',{wait:'document.body.innerText.includes("config-server")',action:async()=>{await delay(2000);}});
    const wait='document.body.innerText.includes("Servicios disponibles")';
    await capture(8,'08-dashboard-general.png',dashboardUrl(),{wait,action:async()=>{await delay(4000);}});
    await capture(9,'09-estado-microservicios.png',dashboardUrl(),{wait,scroll:'Estado individual · siete microservicios'});
    await capture(10,'10-memoria-cpu.png',dashboardUrl(),{wait,scroll:'Memoria JVM utilizada'});
    await capture(11,'11-metricas-http.png',demonstrationUrl(),{wait,scroll:'HTTP de negocio · solicitudes por segundo'});
    await capture(12,'12-conexiones-jdbc.png',dashboardUrl(),{wait,scroll:'HikariCP · conexiones activas'});
    await capture(13,'13-resilience4j.png',demonstrationUrl(),{wait,scroll:'Resilience4j · llamadas CircuitBreaker'});
    await capture(14,'14-filtro-microservicio.png',dashboardUrl('producto-service'),{wait,scroll:'Memoria JVM utilizada'});
  }
} catch(error){report.error=error.message;process.exitCode=1;console.error(error.message);}
finally {
  report.captures.sort((a,b)=>a.file.localeCompare(b.file));
  if(!process.argv.includes('--probe'))writeFileSync(manifest,JSON.stringify(report,null,2));
  writeFileSync(path.join(runtime,'navegador-red-'+Date.now()+'.json'),JSON.stringify({network:session.network,errors:session.errors},null,2));
  await session.close();
}
