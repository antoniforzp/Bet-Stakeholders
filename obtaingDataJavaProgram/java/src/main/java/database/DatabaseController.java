package database;

import java.sql.*;

public class DatabaseController {

    Connection connection;

    public DatabaseController() {
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            connection = DriverManager.getConnection("jdbc:oracle:thin:@localhost:15210:orcl", "aabd", "aabd");

            connection.close();
        } catch (SQLException e) {
            System.out.println(e.getErrorCode());
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }
}