export const queries = [
  {id:'up',expr:'up',title:'Disponibilidad de los siete targets'},
  {id:'count-up',expr:'count(up)',title:'Total de targets'},
  {id:'sum-up',expr:'sum(up)',title:'Targets UP'},
  {id:'down',expr:'count(up == 0) or vector(0)',title:'Targets DOWN'},
  {id:'memoria-jvm',expr:'sum by (job) (jvm_memory_used_bytes) / 1024 / 1024',title:'Memoria JVM, MiB'},
  {id:'cpu',expr:'100 * process_cpu_usage',title:'CPU del proceso, porcentaje'},
  {id:'hilos',expr:'jvm_threads_live_threads',title:'Threads Java activos'},
  {id:'uptime',expr:'process_uptime_seconds',title:'Tiempo de actividad, segundos'},
  {id:'jdbc',expr:'hikaricp_connections_active',title:'Conexiones HikariCP activas, solo cuatro servicios JDBC'},
  {id:'http-exitosas',expr:'sum by (job) (http_server_requests_seconds_count{status="200"})',title:'Peticiones HTTP exitosas acumuladas'},
  {id:'http-negocio-contador',expr:'sum by (job) (http_server_requests_seconds_count{status="200",uri=~"/api/.*"})',title:'Contador HTTP exclusivamente de negocio'},
  {id:'http-tasa-negocio',expr:'sum by (job) (rate(http_server_requests_seconds_count{uri=~"/api/.*"}[1m]))',title:'Tasa HTTP de negocio, solicitudes/segundo'},
  {id:'http-promedio-ms',expr:'1000 * sum by (job) (rate(http_server_requests_seconds_sum{uri=~"/api/.*"}[1m])) / sum by (job) (rate(http_server_requests_seconds_count{uri=~"/api/.*"}[1m]))',title:'Latencia HTTP promedio de negocio, milisegundos'},
  {id:'resilience4j',expr:'resilience4j_circuitbreaker_calls_seconds_count{job=~"producto-service|cliente-service|pedido-service"}',title:'CircuitBreaker por job, name y kind'},
  {id:'resilience4j-cerrados',expr:'resilience4j_circuitbreaker_state{job=~"producto-service|cliente-service|pedido-service",state="closed"}',title:'Estado CLOSED de los circuitos'},
  {id:'resilience4j-retry',expr:'resilience4j_retry_calls_total{job=~"producto-service|pedido-service"}',title:'Retry real por name y kind'},
  {id:'gateway-tasa',expr:'sum by (job, routeId) (rate(spring_cloud_gateway_requests_seconds_count{job="gateway-service"}[1m]))',title:'Gateway: tasa por routeId'},
  {id:'gateway-contador',expr:'sum by (routeId) (spring_cloud_gateway_requests_seconds_count{job="gateway-service",httpStatusCode="200"})',title:'Contadores reales de las cuatro rutas Gateway'},
  {id:'gateway-promedio-ms',expr:'1000 * sum by (job, routeId) (rate(spring_cloud_gateway_requests_seconds_sum{job="gateway-service"}[1m])) / sum by (job, routeId) (rate(spring_cloud_gateway_requests_seconds_count{job="gateway-service"}[1m]))',title:'Gateway: latencia promedio por routeId, milisegundos'}
];
export const uiUrl=(expr,graph=false)=>'http://localhost:9090/query?g0.expr='+encodeURIComponent(expr)+'&g0.tab='+(graph?'graph':'table')+'&g0.range_input=5m';
