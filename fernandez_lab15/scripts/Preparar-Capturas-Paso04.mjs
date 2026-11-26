import {readFileSync,writeFileSync,copyFileSync} from 'node:fs';
import {fileURLToPath,pathToFileURL} from 'node:url';
import path from 'node:path';
import {queries,uiUrl} from './Consultas-Prometheus.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const evidence=path.join(root,'evidencias','03-prometheus');
const fileUrl=name=>pathToFileURL(path.join(evidence,name)).href;
const expression=id=>queries.find(q=>q.id===id).expr;
const receipt=JSON.parse(readFileSync(path.join(evidence,'INSTALACION-PROMETHEUS.json'),'utf8').replace(/^\uFEFF/,''));
const measured=JSON.parse(readFileSync(path.join(evidence,'CONSULTAS-PROMETHEUS.json'),'utf8').replace(/^\uFEFF/,''));
const graphUrl=new URL(uiUrl(expression('http-tasa-negocio'),true));
graphUrl.searchParams.set('g0.end_input',measured.TrafficEnd);
copyFileSync(path.join(root,'observabilidad','prometheus','prometheus.yml'),path.join(evidence,'prometheus-configuracion.txt'));
const captures=[
  ['01-descarga-prometheus.png','https://prometheus.io/download/',{delayBefore:2500,scrollText:`prometheus-${receipt.Version}.windows-amd64.zip`}],
  ['02-version-prometheus.png',fileUrl('prometheus-version.txt')],
  ['03-configuracion-prometheus.png',fileUrl('prometheus-configuracion.txt')],
  ['04-validacion-promtool.png',fileUrl('promtool-check-config.txt')],
  ['05-prometheus-interfaz.png','http://localhost:9090/',{allowRedirect:true}],
  ['06-consulta-up.png',uiUrl(expression('up')),{waitForText:'config-server'}],
  ['07-targets-up.png','http://localhost:9090/targets',{waitForText:'producto-service',collapseAllTargets:true}],
  ['08-total-servicios.png',uiUrl(expression('count-up'))],
  ['09-memoria-jvm.png',uiUrl(expression('memoria-jvm')),{waitForText:'config-server'}],
  ['10-uso-cpu.png',uiUrl(expression('cpu')),{waitForText:'config-server'}],
  ['11-peticiones-http.png',uiUrl(expression('http-exitosas')),{waitForText:'config-server'}],
  ['12-grafico-peticiones.png',graphUrl.href,{executeQuery:true,waitForGraph:true}],
  ['13-conexiones-jdbc.png',uiUrl(expression('jdbc')),{waitForText:'categoria-service'}],
  ['14-resilience4j.png',uiUrl(expression('resilience4j')),{waitForText:'categoriaService'}],
  ['15-suma-servicios-up.png',uiUrl(expression('sum-up')),{executeQuery:true,waitForText:'Result series: 1'}],
  ['16-servicios-down.png',uiUrl(expression('down')),{executeQuery:true,waitForText:'Result series: 1'}],
  ['17-targets-up-continuacion.png','http://localhost:9090/targets',{waitForText:'producto-service',scrollBottom:true}]
];
writeFileSync(path.join(root,'.runtime','paso04','capturas.json'),JSON.stringify({step:'04',captures},null,2));
console.log(`Manifiesto de ${captures.length} capturas reales preparado; usar --solo=15,16,17 para completar sin sobrescribir las 14 anteriores.`);
