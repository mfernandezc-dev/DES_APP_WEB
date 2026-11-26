import {readFileSync,writeFileSync} from 'node:fs';
const [input,output,jar]=process.argv.slice(2);
const metadata=JSON.parse(readFileSync(input,'utf8').replace(/^\uFEFF/,''));
const property=metadata.properties.find(p=>p.name==='management.prometheus.metrics.export.enabled');
if(!property) throw new Error('Propiedad Prometheus ausente en los metadatos efectivos');
writeFileSync(output,JSON.stringify({Jar:jar,Name:property.name,Type:property.type,DefaultValue:property.defaultValue,Description:property.description},null,2));
