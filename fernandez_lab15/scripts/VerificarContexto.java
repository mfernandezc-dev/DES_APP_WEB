import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.ResultSet;
import java.util.Map;
import javax.sql.DataSource;

/** Sonda de preparacion: usa las dependencias del JAR, no modifica sus fuentes. */
public final class VerificarContexto {
    private static String property(Object environment, String name) throws Exception {
        return (String) Class.forName("org.springframework.core.env.PropertyResolver")
                .getMethod("getProperty", String.class).invoke(environment, name);
    }

    private static String json(String value) {
        if (value == null) return "null";
        return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\r", "\\r").replace("\n", "\\n") + "\"";
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 1) throw new IllegalArgumentException("Falta clase principal");
        String[] bootArgs = java.util.Arrays.copyOfRange(args, 1, args.length);
        Object context = null;
        Class<?> configurable = Class.forName("org.springframework.context.ConfigurableApplicationContext");
        try {
            Class<?> boot = Class.forName("org.springframework.boot.SpringApplication");
            context = boot.getMethod("run", Class.class, String[].class)
                    .invoke(null, Class.forName(args[0]), (Object) bootArgs);
            Object environment = configurable.getMethod("getEnvironment").invoke(context);
            String service = property(environment, "spring.application.name");
            String port = property(environment, "server.port");
            String prometheusEnabled = property(environment, "management.prometheus.metrics.export.enabled");
            Object prometheusRegistry = Class.forName("org.springframework.beans.factory.BeanFactory")
                    .getMethod("getBean", String.class).invoke(context, "prometheusMeterRegistry");
            String registryClass = prometheusRegistry.getClass().getName();
            boolean prometheusValid = "true".equals(prometheusEnabled)
                    && registryClass.equals("io.micrometer.prometheusmetrics.PrometheusMeterRegistry");
            boolean localActuator = "127.0.0.1".equals(property(environment, "server.address"))
                    && "*".equals(property(environment, "management.endpoints.web.exposure.include"))
                    && "always".equals(property(environment, "management.endpoint.health.show-details"));
            if ("config-server".equals(service) || "eureka-server".equals(service)
                    || "gateway-service".equals(service)) {
                System.out.println("LAB15_RESULT {\"service\":" + json(service)
                        + ",\"port\":" + json(port) + ",\"defaultLabel\":"
                        + json(property(environment, "spring.cloud.config.server.git.default-label"))
                        + ",\"prometheusExportEnabled\":" + json(prometheusEnabled)
                        + ",\"prometheusRegistry\":" + json(registryClass)
                        + ",\"localActuator\":" + localActuator + ",\"valid\":" + (localActuator && prometheusValid) + "}");
                if (!localActuator || !prometheusValid) throw new IllegalStateException("Actuator/Prometheus no coincide con la configuracion local esperada");
                if ("true".equals(property(environment, "lab15.probe.keep-alive")))
                    new java.util.concurrent.CountDownLatch(1).await();
                if ("true".equals(property(environment, "lab15.probe.hold"))) System.in.read();
                return;
            }
            String ddl = property(environment, "spring.jpa.hibernate.ddl-auto");
            String version = property(environment, "config.client.version");
            String label = property(environment, "spring.cloud.config.label");
            String sqlInit = property(environment, "spring.sql.init.mode");
            Method getBean = Class.forName("org.springframework.beans.factory.BeanFactory")
                    .getMethod("getBean", String.class);
            Object emf = getBean.invoke(context, "entityManagerFactory");
            Map<?, ?> jpa = (Map<?, ?>) Class.forName("jakarta.persistence.EntityManagerFactory")
                    .getMethod("getProperties").invoke(emf);
            String actualDdl = String.valueOf(jpa.get("hibernate.hbm2ddl.auto"));
            DataSource source = (DataSource) getBean.invoke(context, "dataSource");
            String database;
            boolean readOnly;
            try (Connection connection = source.getConnection();
                 var statement = connection.createStatement();
                 ResultSet rows = statement.executeQuery("SELECT DATABASE(), @@session.tx_read_only")) {
                rows.next();
                database = rows.getString(1);
                readOnly = connection.isReadOnly() && rows.getInt(2) == 1;
            }
            String[] profiles = (String[]) Class.forName("org.springframework.core.env.Environment")
                    .getMethod("getActiveProfiles").invoke(environment);
            String expected = "39a22fc2d854d3549ce77cbb347cd20101b0d13f";
            String expectedDatabase = Map.of("categoria-service", "bd_categoria_dev",
                    "producto-service", "bd_producto_dev", "cliente-service", "bd_cliente_dev",
                    "pedido-service", "bd_pedido_dev").get(service);
            boolean valid = "validate".equals(ddl) && "validate".equals(actualDdl)
                    && expected.equals(version) && expected.equals(label)
                    && "never".equals(sqlInit) && readOnly
                    && database.equals(expectedDatabase)
                    && java.util.Arrays.equals(profiles, new String[]{"dev"}) && localActuator
                    && "false".equals(property(environment, "spring.jpa.generate-ddl"))
                    && "false".equals(property(environment, "spring.flyway.enabled"))
                    && "false".equals(property(environment, "spring.liquibase.enabled")) && prometheusValid;
            System.out.println("LAB15_RESULT {\"service\":" + json(service)
                    + ",\"port\":" + json(port) + ",\"remoteVersion\":" + json(version)
                    + ",\"label\":" + json(label) + ",\"ddlAuto\":" + json(ddl)
                    + ",\"hibernateDdlAuto\":" + json(actualDdl) + ",\"sqlInit\":" + json(sqlInit)
                    + ",\"database\":" + json(database) + ",\"readOnly\":" + readOnly
                    + ",\"generateDdl\":" + json(property(environment, "spring.jpa.generate-ddl"))
                    + ",\"flyway\":" + json(property(environment, "spring.flyway.enabled"))
                    + ",\"liquibase\":" + json(property(environment, "spring.liquibase.enabled"))
                    + ",\"localActuator\":" + localActuator
                    + ",\"prometheusExportEnabled\":" + json(prometheusEnabled)
                    + ",\"prometheusRegistry\":" + json(registryClass)
                    + ",\"profiles\":\"dev\",\"valid\":" + valid + "}");
            if (!valid) throw new IllegalStateException("Configuracion efectiva fuera de lo autorizado");
            if ("true".equals(property(environment, "lab15.probe.keep-alive")))
                new java.util.concurrent.CountDownLatch(1).await();
        } catch (InvocationTargetException exception) {
            throw new IllegalStateException("El contexto Spring no pudo verificarse", exception.getCause());
        } finally {
            if (context != null) configurable.getMethod("close").invoke(context);
        }
    }
}
