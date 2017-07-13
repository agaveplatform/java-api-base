import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.Connection;
import java.sql.SQLException;

public class TestHikariCP{
    private static HikariDataSource ds;
    static{

        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:mysql://129.114.6.229:3306/agave-api");
        config.setUsername("agaveapi");
        config.setPassword("d3f@ult$");
        config.setDriverClassName("com.mysql.jdbc.Driver");
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");

        ds = new HikariDataSource(config);
    }

    public static Connection getConn() throws SQLException {
        return ds.getConnection();
    }

    public static void main(String[] args) throws SQLException {
       TestHikariCP testHikariCP = new TestHikariCP();
        Connection conn = TestHikariCP.getConn();
          // query
        conn.close();
    }

}