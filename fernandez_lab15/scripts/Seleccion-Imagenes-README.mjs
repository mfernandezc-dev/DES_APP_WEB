import path from 'node:path';
import {readFileSync,existsSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {root,evidence,readJson} from './Grafana-API.mjs';
const map=[
['02-eureka-registro.png','01-actuator/13-eureka-servicios.png','Cinco aplicaciones registradas UP'],
['03-producto-actuator.png','01-actuator/01-producto-actuator.png','Indice de endpoints administrativos'],
['04-producto-health.png','01-actuator/02-producto-health.png','Salud UP de Producto'],
['05-producto-metrics.png','01-actuator/03-producto-metrics.png','Catalogo Micrometer de Producto'],
['06-categoria-health.png','01-actuator/05-categoria-health.png','Actividad 1: Categoria UP'],
['07-cliente-health.png','01-actuator/08-cliente-health.png','Actividad 1: Cliente UP'],
['08-pedido-health.png','01-actuator/11-pedido-health.png','Actividad 1: Pedido UP'],
['09-producto-prometheus.png','02-micrometer/01-producto-prometheus.png','Exposicion Prometheus de Producto'],
['10-categoria-prometheus.png','02-micrometer/02-categoria-prometheus.png','Actividad 2: Categoria'],
['11-cliente-prometheus.png','02-micrometer/03-cliente-prometheus.png','Actividad 2: Cliente'],
['12-pedido-prometheus.png','02-micrometer/04-pedido-prometheus.png','Actividad 2: Pedido'],
['13-prometheus-configuracion.png','03-prometheus/03-configuracion-prometheus.png','YAML de siete jobs reales'],
['14-prometheus-validacion.png','03-prometheus/04-validacion-promtool.png','promtool SUCCESS'],
['15-prometheus-consulta-up.png','03-prometheus/06-consulta-up.png','Siete series up=1'],
['16-prometheus-targets-up.png','readme/16-prometheus-targets-up.png','Vista final de siete targets UP'],
['17-prometheus-memoria-jvm.png','03-prometheus/09-memoria-jvm.png','Memoria JVM en MiB'],
['18-prometheus-peticiones-http.png','03-prometheus/12-grafico-peticiones.png','Grafico real de peticiones del PASO04'],
['19-grafana-inicio.png','04-grafana/04-grafana-inicio.png','Inicio autenticado de Grafana'],
['20-grafana-datasource.png','04-grafana/05-datasource-prometheus.png','Datasource provisionado'],
['21-grafana-conexion-correcta.png','04-grafana/06-conexion-prometheus-correcta.png','Health real equivalente a Save & test'],
['22-grafana-explore-up.png','04-grafana/07-explore-consulta-up.png','Siete series UP en Explore, reconsultadas en PASO06'],
['23-grafana-dashboard-general.png','readme/23-grafana-dashboard-general.png','Dashboard final completamente cargado en su vista inicial'],
['24-grafana-memoria-cpu.png','04-grafana/10-memoria-cpu.png','Graficos reales de JVM/CPU'],
['25-grafana-metricas-http.png','readme/25-grafana-metricas-http.png','HTTP del trafico real PASO06, ventana fija'],
['26-grafana-conexiones-jdbc.png','04-grafana/12-conexiones-jdbc.png','Pools JDBC donde estan instrumentados'],
['27-grafana-resilience4j.png','04-grafana/13-resilience4j.png','CircuitBreaker y Retry durante trafico real PASO05'],
['28-grafana-filtro-producto.png','readme/28-grafana-filtro-producto.png','Filtro Producto seleccionado y datos reales'],
['29-gateway-productos.png','readme/29-gateway-productos.png','GET real de productos via Gateway'],
['30-pedido-detallado.png','readme/30-pedido-detallado.png','GET real de pedido detallado con datos personales ocultos']
];
const rows=[{Selection:'01-arquitectura-servicios.png',Kind:'Mermaid',File:null,Reused:false,New:false,Explanation:'Diagrama tecnico en README, no captura de ejecucion ni PNG simulado.'}];
for(const [selection,relative,meaning]of map){const file='evidencias/'+relative;const full=path.join(root,file);if(!existsSync(full))throw new Error('Falta imagen seleccionada: '+file);const bytes=readFileSync(full);rows.push({Selection:selection,Kind:'PNG',File:file,Reused:!relative.startsWith('readme/'),New:relative.startsWith('readme/'),Copied:false,Bytes:bytes.length,SHA256:createHash('sha256').update(bytes).digest('hex'),Meaning:meaning,Source:relative.startsWith('readme/')?'CAPTURAS-PASO06.json':'Manifiesto original del paso correspondiente',Publication:'Ruta relativa al original; sin duplicacion fisica'});}
const report={Timestamp:new Date().toISOString(),SelectionCount:30,PNGSelections:29,MermaidDiagrams:1,Reused:rows.filter(r=>r.Reused).length,New:rows.filter(r=>r.New).length,Images:rows};
writeFileSync(path.join(evidence,'INVENTARIO-IMAGENES-README.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({PNG:29,Mermaid:1,Reused:report.Reused,New:report.New}));
