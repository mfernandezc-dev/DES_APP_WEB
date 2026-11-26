// Lee la clave inicial desde la distribucion. No imprime ni guarda texto secreto.
import {readFileSync,writeFileSync} from 'node:fs';
import path from 'node:path';
import {root,runtime,evidence,readJson,credentials,api,save} from './Grafana-API.mjs';
const installation=readJson(path.join(root,'.runtime','grafana','instalacion.json'));
const credential=credentials();
let result=await api('/api/user',{auth:credential,allowFailure:true});
let changed=false,defaultAccepted=false,defaultRejected=false;
const defaults=readFileSync(path.join(installation.InstallDirectory,'conf','defaults.ini'),'utf8');
const section=defaults.split(/^\[security\]\s*$/m)[1]?.split(/^\[/m)[0]||'';
const initial={user:section.match(/^admin_user\s*=\s*(.+)$/m)?.[1].trim(),password:section.match(/^admin_password\s*=\s*(.+)$/m)?.[1].trim()};
if(!initial.user||!initial.password)throw new Error('No se identifico el acceso inicial de esta distribucion.');
if(result.http!==200) {
  const before=await api('/api/user',{auth:initial});defaultAccepted=before.http===200;
  await api('/api/user/password',{method:'PUT',auth:initial,body:{oldPassword:initial.password,newPassword:credential.password,confirmNew:credential.password}});
  result=await api('/api/user',{auth:credential});changed=true;
}
const old=await api('/api/user',{auth:initial,allowFailure:true});defaultRejected=old.http===401;
if(!defaultRejected||result.http!==200)throw new Error('Cambio de acceso inicial no confirmado.');
const report={Completed:true,Timestamp:new Date().toISOString(),NewInstallation:true,InitialAccessFromDistribution:defaultAccepted,PasswordChangedThisRun:changed,InitialPasswordRejected:defaultRejected,AdministrativeLoginVerified:true,SecretStorage:'Windows DPAPI PSCredential + ACL privada, .runtime/grafana/private/admin.clixml',PlaintextPasswordPublished:false,ManualInterventionRequired:false};
save('AUTENTICACION-GRAFANA.json',report);
writeFileSync(path.join(runtime,'checkpoint-auth.json'),JSON.stringify(report,null,2));
console.log('Acceso administrativo verificado; clave inicial cambiada y rechazada; secreto protegido con DPAPI.');
