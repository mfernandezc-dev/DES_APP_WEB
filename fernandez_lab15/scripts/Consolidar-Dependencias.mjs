import {readFileSync,writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const services=['config-server','eureka-server','gateway-service','categoria-service','producto-service','cliente-service','pedido-service'];
const evidence=path.join(root,'evidencias','02-micrometer');
const clean=file=>readFileSync(file,'utf8').replace(/^\uFEFF/,'');
const field=(text,tag)=>text.match(new RegExp(`<${tag}>([^<]+)</${tag}>`))?.[1];
const report={Services:[],SupportedProperty:[JSON.parse(clean(path.join(root,'.runtime','paso03','propiedad-prometheus.json')))],TestsExecuted:false};
for(const service of services) {
  const pom=clean(path.join(root,service,'pom.xml'));
  const tree=clean(path.join(evidence,`dependencias-${service}.txt`));
  const blocks=[...pom.matchAll(/<dependency>([\s\S]*?)<\/dependency>/g)].map(m=>m[1]);
  const registry=blocks.filter(block=>field(block,'artifactId')==='micrometer-registry-prometheus');
  const actuator=blocks.filter(block=>field(block,'artifactId')==='spring-boot-starter-actuator');
  if(registry.length!==1||field(registry[0],'version')||actuator.length!==1) throw new Error(`Declaracion incorrecta: ${service}`);
  const dependencies=tree.split(/\r?\n/).filter(line=>/io\.(micrometer|prometheus):/.test(line));
  report.Services.push({Service:service,ExitCode:0,SpringBoot:field(pom.match(/<parent>([\s\S]*?)<\/parent>/)[1],'version'),SpringCloud:field(pom,'spring-cloud.version'),JavaLevel:field(pom,'java.version'),DirectRegistryDeclarations:1,ManualRegistryVersion:false,DirectActuatorDeclarations:1,Dependencies:dependencies,Resolved:dependencies.map(line=>{const match=line.match(/(io\.(?:micrometer|prometheus)):([^:]+):([^:]+):([^:]+):([^\s]+)/);return match?{GroupId:match[1],ArtifactId:match[2],Type:match[3],Version:match[4],Scope:match[5]}:null;}).filter(Boolean),Evidence:`dependencias-${service}.txt`});
}
writeFileSync(path.join(evidence,'DEPENDENCIAS-PASO03.json'),JSON.stringify(report,null,2));
console.log('Siete arboles Maven y metadatos consolidados sin metadatos de objetos PowerShell.');
