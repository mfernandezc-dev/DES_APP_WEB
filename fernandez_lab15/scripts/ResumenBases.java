import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collections;
import java.util.HexFormat;
import java.util.List;

/** Lee credenciales por stdin; emite solamente nombres, conteos y SHA-256. */
public final class ResumenBases {
    private static String phase = "input";
    private static String read(BufferedReader input) throws Exception {
        String line = input.readLine();
        if (line == null) throw new IllegalArgumentException("Entrada incompleta");
        return new String(Base64.getDecoder().decode(line), StandardCharsets.UTF_8);
    }

    private static String json(String value) {
        return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }

    private static void add(MessageDigest hash, byte[] value) {
        hash.update(ByteBuffer.allocate(4).putInt(value == null ? -1 : value.length).array());
        if (value != null) hash.update(value);
    }

    private static String hex(MessageDigest hash) { return HexFormat.of().formatHex(hash.digest()); }

    public static void main(String[] args) {
        try (var input = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8))) {
            Class.forName("com.mysql.cj.jdbc.Driver");
            List<String> summaries = new ArrayList<>();
            for (int i = 0; i < 4; i++) {
                String service = read(input);
                String url = read(input);
                String user = read(input);
                String password = read(input);
                phase = service + ":connect";
                try (Connection connection = DriverManager.getConnection(url, user, password)) {
                    phase = service + ":read-only";
                    connection.setReadOnly(true);
                    // Connector/J no garantiza propagar el hint JDBC a MariaDB.
                    // Solo cambia esta sesion; no altera datos ni configuracion global.
                    try (var guard = connection.createStatement()) {
                        guard.execute("SET SESSION TRANSACTION READ ONLY");
                    }
                    connection.setAutoCommit(false);
                    String database;
                    phase = service + ":verify-read-only";
                    try (var statement = connection.createStatement();
                         var result = statement.executeQuery("SELECT DATABASE(), @@session.tx_read_only")) {
                        result.next(); database = result.getString(1);
                        if (result.getInt(2) != 1) throw new IllegalStateException("Sesion SQL no protegida");
                    }
                    phase = service + ":metadata";
                    List<String> tables = new ArrayList<>();
                    try (var statement = connection.prepareStatement(
                            "SELECT TABLE_NAME FROM information_schema.TABLES "
                            + "WHERE TABLE_SCHEMA = ? AND TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME")) {
                        statement.setString(1, database);
                        try (var result = statement.executeQuery()) {
                            while (result.next()) tables.add(result.getString(1));
                        }
                    }
                    List<String> tableSummaries = new ArrayList<>();
                    for (String table : tables) {
                        phase = service + ":table-read";
                        String quoted = "`" + table.replace("`", "``") + "`";
                        MessageDigest schemaHash = MessageDigest.getInstance("SHA-256");
                        try (var statement = connection.createStatement();
                             var result = statement.executeQuery("SHOW CREATE TABLE " + quoted)) {
                            result.next(); add(schemaHash, result.getBytes(2));
                        }
                        List<String> rowHashes = new ArrayList<>();
                        try (var statement = connection.createStatement();
                             var result = statement.executeQuery("SELECT * FROM " + quoted)) {
                            int columns = result.getMetaData().getColumnCount();
                            while (result.next()) {
                                MessageDigest rowHash = MessageDigest.getInstance("SHA-256");
                                for (int column = 1; column <= columns; column++) add(rowHash, result.getBytes(column));
                                rowHashes.add(hex(rowHash));
                            }
                        }
                        Collections.sort(rowHashes);
                        MessageDigest dataHash = MessageDigest.getInstance("SHA-256");
                        for (String row : rowHashes) add(dataHash, row.getBytes(StandardCharsets.US_ASCII));
                        tableSummaries.add("{\"table\":" + json(table) + ",\"rows\":" + rowHashes.size()
                                + ",\"schemaSHA256\":" + json(hex(schemaHash))
                                + ",\"dataSHA256\":" + json(hex(dataHash)) + "}");
                    }
                    connection.rollback();
                    summaries.add("{\"service\":" + json(service) + ",\"database\":" + json(database)
                            + ",\"readOnly\":true,\"tables\":[" + String.join(",", tableSummaries) + "]}");
                }
            }
            System.out.println("[" + String.join(",", summaries) + "]");
        } catch (Exception exception) {
            // No imprimir mensajes JDBC que pudieran contener credenciales.
            String state = exception instanceof java.sql.SQLException sql ? sql.getSQLState() : "none";
            int code = exception instanceof java.sql.SQLException sql ? sql.getErrorCode() : 0;
            System.err.println("SQL_READ_ONLY_SNAPSHOT_FAILED: " + exception.getClass().getSimpleName()
                    + " phase=" + phase + " state=" + state + " code=" + code);
            System.exit(1);
        }
    }
}
