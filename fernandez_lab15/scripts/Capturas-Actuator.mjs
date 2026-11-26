// Navegador Chrome REAL, perfil aislado y CDP por pipe (sin puerto administrativo).
// PrintWindow captura su ventana completa, incluida la barra de direccion, sin fabricar HTML.
import { spawn, spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifestArgument = process.argv.find(arg=>arg.startsWith('--manifest='))?.slice(11);
const manifest = manifestArgument ? JSON.parse(readFileSync(path.resolve(root,manifestArgument),'utf8').replace(/^\uFEFF/,'')) : null;
const step = manifest?.step || '02';
if (!['02','03','04'].includes(step)) throw new Error('Paso de captura no permitido');
const evidence = path.join(root, 'evidencias', ({'02':'01-actuator','03':'02-micrometer','04':'03-prometheus'})[step]);
const runtime = path.join(root, '.runtime', 'paso'+step);
mkdirSync(runtime, {recursive:true});
const captures = manifest?.captures || [
  ['01-producto-actuator.png','http://localhost:8083/actuator'],
  ['02-producto-health.png','http://localhost:8083/actuator/health'],
  ['03-producto-metrics.png','http://localhost:8083/actuator/metrics'],
  ['04-categoria-actuator.png','http://localhost:8082/actuator'],
  ['05-categoria-health.png','http://localhost:8082/actuator/health'],
  ['06-categoria-metrics.png','http://localhost:8082/actuator/metrics'],
  ['07-cliente-actuator.png','http://localhost:8084/actuator'],
  ['08-cliente-health.png','http://localhost:8084/actuator/health'],
  ['09-cliente-metrics.png','http://localhost:8084/actuator/metrics'],
  ['10-pedido-actuator.png','http://localhost:8085/actuator'],
  ['11-pedido-health.png','http://localhost:8085/actuator/health'],
  ['12-pedido-metrics.png','http://localhost:8085/actuator/metrics'],
  ['13-eureka-servicios.png','http://localhost:8761/'],
  ['14-gateway-actuator.png','http://localhost:8080/actuator'],
  ['15-config-server-health.png','http://localhost:8888/actuator/health'],
  ['16-gateway-pruebas.png','http://localhost:8080/api/categorias'],
  ['17-metrica-http-requests.png','http://localhost:8083/actuator/metrics/http.server.requests'],
  ['18-metrica-jvm-memory.png','http://localhost:8083/actuator/metrics/jvm.memory.used'],
];
const only = process.argv.find(arg=>arg.startsWith('--solo='))?.slice(7).split(',').map(Number);
const capturesFile = 'CAPTURAS-PASO'+step+'.json';
const previous = only ? JSON.parse(readFileSync(path.join(evidence,capturesFile),'utf8')) : null;
const report = {method:'Chrome real + CDP por pipe + PrintWindow, ventana con URL', captures:previous?.captures || [], error:null};
const browser = spawn('C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe', [
  '--remote-debugging-pipe', `--user-data-dir=${path.join(runtime,'chrome-evidencias-'+Date.now())}`,
  '--no-first-run','--no-default-browser-check','--disable-sync','--disable-extensions',
  '--disable-background-networking','--window-size=1500,850','--window-position=0,0',
  '--force-device-scale-factor=1','--disable-gpu','--noerrdialogs','about:blank'
], {stdio:['ignore','ignore','ignore','pipe','pipe'], windowsHide:false});
let nextId=0, buffer='';
const pending=new Map();
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
function send(method,params={},sessionId) {
  const id=++nextId;
  return new Promise((resolve,reject)=>{
    const timer=setTimeout(()=>{pending.delete(id);reject(new Error(`CDP timeout: ${method}`));},20000);
    pending.set(id,{resolve,reject,timer});
    browser.stdio[3].write(JSON.stringify({id,method,params,...(sessionId?{sessionId}:{})})+'\0');
  });
}
browser.stdio[4].on('data',chunk=>{
  buffer+=chunk.toString(); let separator;
  while ((separator=buffer.indexOf('\0'))>=0) {
    const message=JSON.parse(buffer.slice(0,separator)); buffer=buffer.slice(separator+1);
    if (message.id && pending.has(message.id)) {
      const {resolve,reject,timer}=pending.get(message.id);pending.delete(message.id);clearTimeout(timer);
      message.error?reject(new Error(message.error.message)):resolve(message.result);
    }
  }
});
try {
  const version=await send('Browser.getVersion'); report.browser=version.product;
  const targets=await send('Target.getTargets');
  const page=targets.targetInfos.find(target=>target.type==='page');
  if (!page) throw new Error('No hay pestana de navegador propia');
  const {sessionId}=await send('Target.attachToTarget',{targetId:page.targetId,flatten:true});
  await send('Page.enable',{},sessionId);
  for (const [file,url,options={}] of captures) {
    if (only && !only.includes(Number(file.slice(0,2)))) continue;
    const response=url.startsWith('file:')?{ok:true,status:null,arrayBuffer:async()=>readFileSync(fileURLToPath(url))}:await fetch(url,{headers:{Accept:step==='03'?'text/plain;version=0.0.4':step==='04'?'text/html,application/json;q=0.9':'application/json'}}); // solo GET
    if (!response.ok) throw new Error(`HTTP ${response.status}: ${url}`);
    await response.arrayBuffer();
    const navigation=await send('Page.navigate',{url},sessionId);
    if (navigation.errorText) throw new Error(navigation.errorText);
    let ready=false;let displayedUrl=url;
    for (let i=0;i<60;i++) {
      await delay(150);
      const state=await send('Runtime.evaluate',{expression:'JSON.stringify({url:location.href,ready:document.readyState})',returnByValue:true},sessionId);
      const value=JSON.parse(state.result.value);
      if ((value.url===url || (options.allowRedirect && new URL(value.url).origin===new URL(url).origin)) && value.ready==='complete') {ready=true;displayedUrl=value.url;break;}
    }
    if (!ready) throw new Error(`La pagina no termino de cargar: ${url}`);
    await send('Target.activateTarget',{targetId:page.targetId});
    await send('Page.bringToFront',{},sessionId);
    if(options.delayBefore) await delay(options.delayBefore);
    if(options.executeQuery) {
      await delay(700);
      const execute=await send('Runtime.evaluate',{expression:'(()=>{const button=[...document.querySelectorAll("button")].find(b=>b.innerText.trim()==="Execute");if(!button)return false;button.click();return true;})()',returnByValue:true},sessionId);
      if(!execute.result.value)throw new Error('No se encontro el boton Execute de la interfaz real');
    }
    if(step==='04') {
      const controls=await send('Runtime.evaluate',{expression:'JSON.stringify([...document.querySelectorAll("button")].map(b=>({text:b.innerText,aria:b.getAttribute("aria-label"),title:b.getAttribute("title"),html:b.outerHTML.slice(0,600)})))',returnByValue:true},sessionId);
      writeFileSync(path.join(runtime,'controls-'+file+'.json'),controls.result.value||'[]');
    }
    if(options.waitForText) {
      let found=false;
      for(let attempt=0;attempt<120;attempt++) {
        const text=await send('Runtime.evaluate',{expression:'document.body.innerText',returnByValue:true},sessionId);
        if(text.result.value?.includes(options.waitForText)){found=true;break;}
        await delay(250);
      }
      if(!found) {
        const diagnostic=await send('Runtime.evaluate',{expression:'document.body.innerText',returnByValue:true},sessionId);
        writeFileSync(path.join(runtime,'error-'+file+'.txt'),diagnostic.result.value||'');
        throw new Error('La interfaz no muestra el resultado esperado: '+options.waitForText);
      }
    }
    if(options.scrollText) {
      const scroll=await send('Runtime.evaluate',{expression:`(()=>{const text=${JSON.stringify(options.scrollText)};const anchor=[...document.querySelectorAll('a')].find(a=>a.textContent.trim()===text && a.getClientRects().length);if(anchor){anchor.scrollIntoView({behavior:'instant',block:'center'});return true;}return false;})()`,returnByValue:true},sessionId);
      if(!scroll.result.value)throw new Error('No se encontro el enlace oficial para enfocar la captura');
    }
    if(options.collapseAllTargets) {
      const collapsed=await send('Runtime.evaluate',{expression:'(async()=>{let button=document.querySelector("button[title=\"Collapse all pools\"]");if(!button){const expand=document.querySelector("button[title=\"Expand all pools\"]");if(expand){expand.click();await new Promise(r=>setTimeout(r,200));button=document.querySelector("button[title=\"Collapse all pools\"]");}}if(button){button.click();return "control global real";}let count=0;for(const control of [...document.querySelectorAll("button[data-accordion-control]")]){if(control.getAttribute("aria-expanded")==="true"){control.click();count++;await new Promise(r=>setTimeout(r,100));}}return count;})()',returnByValue:true,awaitPromise:true},sessionId);
      writeFileSync(path.join(runtime,'targets-collapsed.json'),JSON.stringify(collapsed.result.value));
      await delay(500);
    }
    if(options.clickText) {
      const click=await send('Runtime.evaluate',{expression:`(()=>{const element=[...document.querySelectorAll('button')].find(b=>(b.innerText||b.getAttribute('aria-label')||'').includes(${JSON.stringify(options.clickText)}));if(!element)return false;element.click();return true;})()`,returnByValue:true},sessionId);
      if(!click.result.value)throw new Error('No se encontro el control real: '+options.clickText);
      await delay(400);
    }
    if (options.findText) {
      const focused=await send('Runtime.evaluate',{expression:`(()=>{ const pre=document.querySelector('pre');if(!pre)return false;const node=pre.firstChild;const index=node.textContent.indexOf(${JSON.stringify(options.findText)});if(index<0)return false;const range=document.createRange();range.setStart(node,index);range.setEnd(node,index+${options.findText.length});window.scrollTo(0,range.getBoundingClientRect().top+window.scrollY-140);return true;})()`,returnByValue:true},sessionId);
      if (!focused.result.value) throw new Error('Metrica solicitada no encontrada en la pagina real: '+options.findText);
    }
    await send('Target.activateTarget',{targetId:page.targetId});
    await send('Page.bringToFront',{},sessionId);
    // Forzar una superficie renderizada; se descarta esta captura de pagina.
    // La evidencia guardada sigue siendo exclusivamente la ventana Win32 con URL.
    await send('Page.captureScreenshot',{format:'png',fromSurface:true},sessionId);
    await delay(650);
    if(options.scrollText) {
      await send('Runtime.evaluate',{expression:`[...document.querySelectorAll('a')].find(a=>a.textContent.trim()===${JSON.stringify(options.scrollText)} && a.getClientRects().length)?.scrollIntoView({behavior:'instant',block:'center'})`},sessionId);
      await delay(400);
    }
    if(options.waitForGraph) await delay(2500);
    if(options.scrollBottom) {
      const scrolled=await send('Runtime.evaluate',{expression:'(()=>{const control=[...document.querySelectorAll("button")].find(b=>b.innerText.includes("producto-service"));if(!control)return false;control.scrollIntoView({behavior:"instant",block:"center"});return true;})()',returnByValue:true},sessionId);
      if(!scrolled.result.value)throw new Error('No se encontro el ultimo target para la captura complementaria');
      await delay(500);
      await send('Page.captureScreenshot',{format:'png',fromSurface:true},sessionId);
      await delay(650);
    }
    if(step==='04') {
      const dom=await send('Runtime.evaluate',{expression:'document.body.innerText',returnByValue:true},sessionId);
      writeFileSync(path.join(runtime,'browser-'+file+'.txt'),dom.result.value||'');
      const controls=await send('Runtime.evaluate',{expression:'JSON.stringify([...document.querySelectorAll("button")].map(b=>({text:b.innerText,aria:b.getAttribute("aria-label"),title:b.getAttribute("title"),html:b.outerHTML.slice(0,600)})))',returnByValue:true},sessionId);
      writeFileSync(path.join(runtime,'controls-ready-'+file+'.json'),controls.result.value||'[]');
    }
    const extraArguments=[];let redactions=[];
    if(step==='03') {
      const inspection=await send('Runtime.evaluate',{expression:String.raw`(()=>{const pre=document.querySelector('pre');if(!pre)return [];const node=pre.firstChild;const text=node.textContent;const output=[];const frame=(outerWidth-innerWidth)/2;const top=outerHeight-innerHeight-frame;for(const match of text.matchAll(/\b([A-Za-z_][A-Za-z0-9_]*)="((?:\\.|[^"\\])*)"/g)){if(!/password|secret|token|cookie|authorization|email|dni|direccion/i.test(match[1])&&!/(?:[A-Za-z]:\\|\/Users\/|\/home\/)/.test(match[2]))continue;const range=document.createRange();range.setStart(node,match.index);range.setEnd(node,match.index+match[0].length);for(const rect of range.getClientRects()){if(rect.bottom<0||rect.top>innerHeight)continue;output.push({x:Math.max(frame,rect.x+frame-3),y:Math.max(top,rect.y+top-2),width:rect.width+6,height:rect.height+4,label:match[1]});}}return output;})()`,returnByValue:true},sessionId);
      redactions=inspection.result.value||[];
      const originals=path.join(runtime,'capturas-originales');mkdirSync(originals,{recursive:true});
      const redactionFile=path.join(runtime,file+'.redacciones.json');writeFileSync(redactionFile,JSON.stringify(redactions));
      extraArguments.push('-OriginalFile',path.join(originals,file),'-RedactionsFile',redactionFile);
    }
    const shot=spawnSync('powershell.exe',['-NoProfile','-ExecutionPolicy','Bypass','-File',path.join(root,'scripts','Capturar-Ventana.ps1'),'-BrowserPID',String(browser.pid),'-OutputFile',path.join(evidence,file),...extraArguments],{encoding:'utf8',windowsHide:true});
    if (shot.status!==0) throw new Error(`Captura Win32 fallo: ${shot.stderr || shot.stdout}`);
    report.captures=report.captures.filter(capture=>capture.file!==file);
    report.captures.push({file,url,displayedUrl,status:response.status,source:url.startsWith('file:')?'Archivo real de configuracion/salida de herramienta':'HTTP real',timestamp:new Date().toISOString(),bytes:readFileSync(path.join(evidence,file)).length,redactions,focus:options.findText||null});
    console.log(`${file}: HTTP ${response.status}, ventana real guardada`);
  }
} catch(error) {
  report.error=String(error.message);console.error(report.error);process.exitCode=1;
} finally {
  report.captures.sort((a,b)=>a.file.localeCompare(b.file));
  writeFileSync(path.join(evidence,capturesFile),JSON.stringify(report,null,2));
  try {await send('Browser.close');} catch {}
  for (const {timer} of pending.values()) clearTimeout(timer);
  browser.stdio[3].destroy(); browser.stdio[4].destroy();
}
