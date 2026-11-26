// Modelo clasico provisionable. No descarga plugins ni escribe en Grafana.
import {writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
const ds={type:'prometheus',uid:'prometheus-lab15'};
const selected='job=~"${servicio:regex}"';
const window='[$__rate_interval]';
const mvc=(suffix,extra='')=>`http_server_requests_seconds_${suffix}{${selected},uri=~"/api/.*"${extra}}`;
const gw=(suffix,extra='')=>`spring_cloud_gateway_requests_seconds_${suffix}{job="gateway-service",${selected}${extra}}`;
const rate=metric=>`sum by (job) (rate(${metric}${window}))`;
const httpRate=`${rate(mvc('count'))} or ${rate(gw('count'))}`;
const success=`sum by (job) (increase(${mvc('count',',status="200"')}[2m])) or sum by (job) (increase(${gw('count',',httpStatusCode="200"')}[2m]))`;
const mean=(sum,count)=>`1000 * ${rate(sum)} / (${rate(count)} > 0)`;
const latency=`(${mean(mvc('sum'),mvc('count'))}) or (${mean(gw('sum'),gw('count'))})`;
const panels=[];
const thresholds=(color='green')=>({mode:'absolute',steps:[{color,value:null}]});
function field(unit='short',extra={}) {return {defaults:{unit,noValue:'Sin datos',color:{mode:'palette-classic'},thresholds:thresholds(),...extra},overrides:[]};}
function target(expr,legendFormat='{{job}}',instant=false) {return {refId:'A',datasource:ds,expr,legendFormat,editorMode:'code',range:!instant,instant};}
function add(id,title,type,pos,expr,unit,description,extra={}) {
  const panel={id,title,type,gridPos:{x:pos[0],y:pos[1],w:pos[2],h:pos[3]},description,datasource:ds,fieldConfig:field(unit),targets:[target(expr)],options:{tooltip:{mode:'multi',sort:'desc'},legend:{showLegend:true,displayMode:'table',placement:'bottom',calcs:['lastNotNull','max']}},...extra};
  if(type==='timeseries') panel.fieldConfig.defaults.custom={drawStyle:'line',lineInterpolation:'smooth',lineWidth:2,fillOpacity:12,showPoints:'never',spanNulls:false,axisCenteredZero:false,axisColorMode:'text',axisLabel:'',scaleDistribution:{type:'linear'},hideFrom:{tooltip:false,viz:false,legend:false}};
  panels.push(panel);return panel;
}
panels.push({id:1,type:'text',title:'LAB 15 / CENTRO DE OBSERVABILIDAD',gridPos:{x:0,y:0,w:24,h:3},options:{mode:'markdown',content:'### Siete servicios · una visión operativa\n**Prometheus → Grafana OSS** · métricas reales cada **5 s** · los indicadores globales siempre incluyen los siete servicios. Selecciona un **Microservicio** para explorar JVM, HTTP, JDBC y resiliencia.\n\n`UP` = scrape correcto, no certificación de negocio. **Sin datos** ≠ DOWN. Latencia sin solicitudes: sin observaciones, nunca cero artificial.'}});
for(const [id,title,expr,unit,x] of [[2,'Servicios disponibles','sum(up)','short',0],[3,'Servicios no disponibles','count(up == 0) or vector(0)','short',6],[4,'Total de servicios','count(up)','short',12],[5,'Disponibilidad del scrape','100 * avg(up)','percent',18]]) {
  const p=add(id,title,'stat',[x,3,6,4],expr,unit,'Indicador global, independiente del filtro. Estado actual del scrape, no SLO histórico.',{targets:[target(expr,'',true)],options:{reduceOptions:{values:false,calcs:['lastNotNull'],fields:''},orientation:'auto',textMode:'value',colorMode:'background',graphMode:'none',justifyMode:'auto',wideLayout:true}});
  p.fieldConfig.defaults.decimals=0;
  p.fieldConfig.defaults.color={mode:'thresholds'};
  p.fieldConfig.defaults.thresholds=id===3?{mode:'absolute',steps:[{color:'green',value:null},{color:'red',value:1}]}:id===2?{mode:'absolute',steps:[{color:'red',value:null},{color:'orange',value:1},{color:'green',value:7}]}:id===5?{mode:'absolute',steps:[{color:'red',value:null},{color:'orange',value:80},{color:'green',value:100}]}:thresholds('blue');
}
const state=add(6,'Estado individual · siete microservicios','stat',[0,7,24,4],'up','short','Global: muestra los siete jobs incluso al filtrar. Ausencia de serie = Sin datos (gris), no DOWN.',{targets:[target('up','{{job}}',true)],options:{reduceOptions:{values:true,calcs:['lastNotNull'],fields:''},orientation:'horizontal',textMode:'value_and_name',colorMode:'background',graphMode:'none',justifyMode:'center',wideLayout:true}});
state.fieldConfig.defaults={...state.fieldConfig.defaults,color:{mode:'thresholds'},noValue:'Sin datos',mappings:[{type:'value',options:{'0':{text:'DOWN',color:'red',index:0},'1':{text:'UP',color:'green',index:1}}},{type:'special',options:{match:'null',result:{text:'Sin datos',color:'gray',index:2}}}],thresholds:{mode:'absolute',steps:[{color:'red',value:null},{color:'green',value:1}]}};
// Tabla de siete filas: legible en todas las relaciones de aspecto. Evita
// comprimir siete resultados instantaneos en un unico Stat de poca altura.
state.type='table';
state.options={showHeader:true,cellHeight:'sm',sortBy:[{displayName:'Microservicio',desc:false}],footer:{show:false}};
state.transformations=[{id:'seriesToRows',options:{}},{id:'organize',options:{excludeByName:{Time:true},indexByName:{Metric:0,Value:1},renameByName:{Metric:'Microservicio',Value:'Estado'}}}];
state.fieldConfig.defaults.custom={align:'left',cellOptions:{type:'auto'}};
state.fieldConfig.overrides=[{matcher:{id:'byName',options:'Estado'},properties:[{id:'custom.cellOptions',value:{type:'color-background',mode:'basic'}},{id:'custom.align',value:'center'},{id:'custom.width',value:180}]}];
add(7,'Memoria JVM utilizada','timeseries',[0,11,12,8],`sum by (job) (jvm_memory_used_bytes{${selected}}) / 1024 / 1024`,'suffix: MiB','Heap + non-heap. MiB = bytes / 1024².');
const cpu=add(8,'CPU del proceso','timeseries',[12,11,12,8],`100 * process_cpu_usage{${selected}}`,'percent','Porcentaje de CPU del proceso Java, no del host. Eje automatico en porcentaje para visualizar cargas pequeñas.');cpu.fieldConfig.defaults.min=0;
add(9,'Hilos activos de Java','timeseries',[0,19,12,7],`jvm_threads_live_threads{${selected}}`,'short','Gauge: puede aumentar o disminuir.');
add(10,'Tiempo de actividad','timeseries',[12,19,12,7],`process_uptime_seconds{${selected}}`,'s','Segundos desde el inicio de cada JVM; no reiniciar para generar evidencia.');
add(11,'HTTP de negocio · solicitudes por segundo','timeseries',[0,26,12,8],httpRate,'reqps','rate con $__rate_interval (mínimo 4 scrapes). MVC filtra /api/; Gateway usa sus timers de rutas.');
add(12,'HTTP exitosas · últimas 2 min','timeseries',[12,26,12,8],success,'short','increase de respuestas HTTP 200 de negocio. Puede ser fraccional por extrapolación. Cero es válido si existe contador pero no hubo nuevas solicitudes.');
add(13,'HTTP de negocio · respuesta media','timeseries',[0,34,24,8],latency,'ms','Media ponderada, no percentil. Denominador > 0: sin solicitudes no hay observación; no se rellena con cero ni NaN. Gateway usa su timer real.');
const active=add(14,'HikariCP · conexiones activas','timeseries',[0,42,12,8],`hikaricp_connections_active{${selected}}`,'short','Solo Categoria, Producto, Cliente y Pedido. Cero entre consultas es normal; infraestructura sin JDBC = Sin datos.');active.fieldConfig.defaults.min=0;active.fieldConfig.defaults.custom.axisSoftMax=10;
add(15,'HikariCP · límite de conexiones','timeseries',[12,42,12,8],`hikaricp_connections_max{${selected}}`,'short','Capacidad configurada del pool; no son conexiones activas ni se atribuye JDBC a infraestructura.');
const cb=add(16,'Resilience4j · llamadas CircuitBreaker','timeseries',[0,50,24,8],`sum by (job, name, kind) (rate(resilience4j_circuitbreaker_calls_seconds_count{${selected}}${window}))`,'reqps','Series reales de Producto/Cliente/Pedido por name y kind; no se inventan para otros servicios.');cb.targets[0].legendFormat='{{job}} · {{name}} · {{kind}}';
const closed=add(17,'Resilience4j · circuitos cerrados','timeseries',[0,58,12,8],`resilience4j_circuitbreaker_state{${selected},state="closed"}`,'short','1=CLOSED; 0=no CLOSED. Solo instancias instrumentadas.');closed.targets[0].legendFormat='{{job}} · {{name}}';
const retry=add(18,'Resilience4j · llamadas Retry','timeseries',[12,58,12,8],`sum by (job, name, kind) (rate(resilience4j_retry_calls_total{${selected}}${window}))`,'reqps','Solo Producto/Pedido, donde se comprobó este contador. kind distingue successful_without_retry y demás resultados reales.');retry.targets[0].legendFormat='{{job}} · {{name}} · {{kind}}';
panels[0].gridPos.h=4;
for(const panel of panels.filter(p=>p.id>=2&&p.id<=6))panel.gridPos.y+=1;
state.gridPos.h=10;
for(const panel of panels.filter(p=>p.id>=7))panel.gridPos.y+=7;
const dashboard={id:null,uid:'lab15-observabilidad',title:'Lab 15 - Observabilidad de Microservicios',description:'Observabilidad local reproducible de siete microservicios. Fuentes reales Prometheus; sin datos artificiales.',tags:['lab15','microservicios','prometheus','observabilidad'],timezone:'browser',schemaVersion:41,version:1,editable:false,style:'dark',graphTooltip:1,refresh:'5s',time:{from:'now-15m',to:'now'},timepicker:{refresh_intervals:['5s','10s','30s','1m'],time_options:['5m','15m','30m','1h']},annotations:{list:[]},links:[],templating:{list:[{name:'servicio',label:'Microservicio',type:'query',datasource:ds,definition:'label_values(up, job)',query:{query:'label_values(up, job)',refId:'StandardVariableQuery'},refresh:2,sort:1,multi:true,includeAll:true,allValue:'.*',current:{selected:true,text:'Todos',value:'$__all'},options:[],hide:0,skipUrlSync:false}]},panels};
writeFileSync(fileURLToPath(new URL('../observabilidad/grafana/dashboards/lab15-observabilidad.json',import.meta.url)),JSON.stringify(dashboard,null,2)+'\n');
console.log(`Dashboard: ${panels.length} paneles, ${panels.filter(p=>p.targets).length} paneles de datos; provisioning portable.`);
