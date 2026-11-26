// Reutiliza Chrome/CDP por pipe y Capturar-Ventana.ps1; sin puerto de depuracion.
import {spawn,spawnSync} from 'node:child_process';
import {mkdirSync,readFileSync,writeFileSync} from 'node:fs';
import path from 'node:path';
import {root,runtime,credentials} from './Grafana-API.mjs';
export const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
export async function browserSession() {
  mkdirSync(runtime,{recursive:true});
  const browser=spawn('C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',['--remote-debugging-pipe',`--user-data-dir=${path.join(runtime,'chrome-'+Date.now())}`,'--no-first-run','--no-default-browser-check','--disable-sync','--disable-extensions','--disable-background-networking','--disable-backgrounding-occluded-windows','--disable-renderer-backgrounding','--window-size=1500,850','--window-position=0,0','--force-device-scale-factor=1','--disable-gpu','--noerrdialogs','about:blank'],{stdio:['ignore','ignore','ignore','pipe','pipe'],windowsHide:false});
  let nextId=0,buffer='';const pending=new Map();const network=[];const errors=[];
  function send(method,params={},sessionId) {
    const id=++nextId;
    return new Promise((resolve,reject)=>{const timer=setTimeout(()=>{pending.delete(id);reject(new Error('CDP timeout: '+method))},30000);pending.set(id,{resolve,reject,timer});browser.stdio[3].write(JSON.stringify({id,method,params,...(sessionId?{sessionId}:{})})+'\0');});
  }
  browser.stdio[4].on('data',chunk=>{
    buffer+=chunk.toString();let separator;
    while((separator=buffer.indexOf('\0'))>=0){const message=JSON.parse(buffer.slice(0,separator));buffer=buffer.slice(separator+1);
      if(message.id&&pending.has(message.id)){const {resolve,reject,timer}=pending.get(message.id);pending.delete(message.id);clearTimeout(timer);message.error?reject(new Error(message.error.message)):resolve(message.result);}
      if(message.method==='Network.responseReceived') {const r=message.params.response;if(r.url.startsWith('http://localhost:3000/api/'))network.push({url:r.url,status:r.status,timestamp:new Date().toISOString()});}
      if(message.method==='Runtime.exceptionThrown')errors.push({message:message.params.exceptionDetails.text,url:message.params.exceptionDetails.url||null});
    }
  });
  const version=await send('Browser.getVersion');
  const targets=await send('Target.getTargets');const page=targets.targetInfos.find(t=>t.type==='page');
  const {sessionId}=await send('Target.attachToTarget',{targetId:page.targetId,flatten:true});
  await send('Page.enable',{},sessionId);await send('Runtime.enable',{},sessionId);await send('Network.enable',{},sessionId);
  async function evaluate(expression){const value=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true},sessionId);if(value?.exceptionDetails)throw new Error('Operacion del navegador: '+(value.exceptionDetails.exception?.description||value.exceptionDetails.text).split('\n')[0]);return value?.result?.value;}
  async function waitFor(expression,timeout=45000){const end=Date.now()+timeout;while(Date.now()<end){try{if(await evaluate(expression))return;}catch{}await delay(250);}throw new Error('La interfaz no alcanzo el estado esperado.');}
  async function navigate(url){const navigation=await send('Page.navigate',{url},sessionId);if(navigation.errorText)throw new Error('Navegacion: '+navigation.errorText);const matching=url.startsWith('file:')?`location.href===${JSON.stringify(url)}`:`location.origin===${JSON.stringify(new URL(url).origin)}`;await waitFor(`${matching} && document.readyState==="complete" && !!document.body`);await send('Target.activateTarget',{targetId:page.targetId});await send('Page.bringToFront',{},sessionId);await send('Page.captureScreenshot',{format:'png',fromSurface:true},sessionId);await delay(1600);}
  async function login(){await navigate('http://localhost:3000/login');const c=credentials();const result=await evaluate(`(async()=>{const r=await fetch('/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(${JSON.stringify(c)})});return r.status;})()`);if(result!==200)throw new Error('Login privado del navegador no confirmado');await navigate('http://localhost:3000/');}
  async function screenshot(file,{redactions=[],originalFile}={}){
    // Nunca capturar un formulario con contrasena rellenada ni un token visible.
    if(await evaluate('[...document.querySelectorAll("input[type=password]")].some(e=>e.value.length>0)'))throw new Error('Campo secreto no vacio; captura bloqueada.');
    await send('Target.activateTarget',{targetId:page.targetId});await send('Page.bringToFront',{},sessionId);
    await send('Page.captureScreenshot',{format:'png',fromSurface:true},sessionId);await delay(650);
    const extra=[];
    if(redactions.length){const regions=path.join(runtime,path.basename(file)+'.redacciones.json');writeFileSync(regions,JSON.stringify(redactions));extra.push('-RedactionsFile',regions);if(originalFile)extra.push('-OriginalFile',originalFile);}
    const shot=spawnSync('powershell.exe',['-NoProfile','-ExecutionPolicy','Bypass','-File',path.join(root,'scripts','Capturar-Ventana.ps1'),'-BrowserPID',String(browser.pid),'-OutputFile',file,...extra],{encoding:'utf8',windowsHide:true});
    if(shot.status!==0)throw new Error('PrintWindow: '+(shot.stderr||shot.stdout).trim());
    return {bytes:readFileSync(file).length,url:await evaluate('location.href'),timestamp:new Date().toISOString()};
  }
  async function close(){try{await send('Browser.close')}catch{}for(const {timer}of pending.values())clearTimeout(timer);browser.stdio[3].destroy();browser.stdio[4].destroy();}
  return {send,pageSend:(method,params={})=>send(method,params,sessionId),evaluate,waitFor,navigate,login,screenshot,close,network,errors,browser:version.product};
}
