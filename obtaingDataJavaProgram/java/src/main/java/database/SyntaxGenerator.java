package database;

import download.Match;

import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class SyntaxGenerator {

    private static int currId = 1;

    public static void generateInserts(ArrayList<Match> matches, int day) {
        try {
            File file = new File("files/output.txt");
            FileWriter fr = new FileWriter(file, true);

            StringBuilder strB = new StringBuilder();
            strB.append("--day ").append(day).append("\n");
            for (Match match : matches) {

                strB.append("INSERT INTO history_games").append(" VALUES(")
                        .append(currId++).append(",")
                        .append(match.round).append(",")
                        .append("'").append(getShort(match.teamA)).append("'").append(",")
                        .append("'").append(getShort(match.teamB)).append("'").append(",")
                        .append("'").append(match.matchDate).append(" ").append(match.hour).append("'").append(",")
                        .append("null").append(",")
                        .append(match.scoreA).append(",")
                        .append(match.scoreB)
                        .append(");\n");
            }

            fr.write(strB.toString() + "\n");
            fr.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static String getShort(String fullName) {

        Map<String, String> names = new HashMap<>();
        names.put("BE", "Belenenses SAD");
        names.put("BEN", "SL Benfica");
        names.put("BO", "Boavista FC");
        names.put("DA", "CD Aves");
        names.put("FA", "FC Famalicão");
        names.put("GV", "Gil Vicente FC");
        names.put("MA", "Marítimo M.");
        names.put("MO", "Moreirense");
        names.put("PF", "FC P.Ferreira");
        names.put("PO", "FC Porto");
        names.put("LFC", "Belenenses");
        names.put("RA", "Rio Ave FC");
        names.put("SC", "Santa Clara");
        names.put("SCP", "Sporting CP");
        names.put("TO", "CD Tondela");
        names.put("VG", "Vitória de Guimarães");
        names.put("VSE", "Vitória SC");
        names.put("POR", "Portimonense");
        names.put("MOR", "Moreirense FC");
        names.put("BR", "SC Braga");
        names.put("VFC", "Vitória FC");

        for (Map.Entry<String, String> entry : names.entrySet())
            if (entry.getValue().equals(fullName)) {
                return entry.getKey();
            }
        return null;
    }
}
