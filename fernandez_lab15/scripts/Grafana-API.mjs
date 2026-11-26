import {spawnSync} from 'node:child_process';
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
export const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
export const step=process.argv.includes('--paso=06')?'06':'05';
export const runtime=path.join(root,'.runtime','paso'+step);
export const evidence=path.join(root,'evidencias',step==='06'?'05-pruebas-finales':'04-grafana');
export const readJson=file=>JSON.parse(readFileSync(file,'utf8').replace(/^\uFEFF/,''));
export function save(file,body){mkdirSync(evidence,{recursive:true});writeFileSync(path.join(evidence,file),JSON.stringify(body,null,2)+'\n');}
export function credentials() {
  const child=spawnSync('powershell.exe',['-NoProfile','-ExecutionPolicy','Bypass','-File',path.join(root,'scripts','Acceso-Grafana.ps1'),'-JsonPrivado'],{encoding:'utf8',windowsHide:true});
  if(child.status!==0)throw new Error('No se pudo descifrar la credencial local DPAPI; no se muestran salidas privadas.');
  return JSON.parse(child.stdout.replace(/^\uFEFF/,''));
}
export async function api(route,{method='GET',body,auth=credentials(),allowFailure=false}={}) {
  if(!route.startsWith('/')||route.startsWith('//'))throw new Error('Solo API local de Grafana');
  const headers={Accept:'application/json'};
  if(auth)headers.Authorization='Basic '+Buffer.from(auth.user+':'+auth.password).toString('base64');
  if(body!==undefined)headers['Content-Type']='application/json';
  const response=await fetch('http://127.0.0.1:3000'+route,{method,headers,body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(45000)});
  const text=await response.text();let data;try{data=JSON.parse(text)}catch{data={nonJson:true}};
  if(!response.ok&&!allowFailure)throw new Error(`Grafana HTTP ${response.status}: ${route.split('?')[0]}`);
  return {http:response.status,body:data};
}
