package network;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import java.io.*;

public class HtmlParser {

    static public void parse(String filename) {

        File file = new File(filename);
        StringBuilder HTMLCode = new StringBuilder();
        String line;
        try {
            BufferedReader br = new BufferedReader(new FileReader(file));
            while ((line = br.readLine()) != null) {
                HTMLCode.append(line).append("\n");
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        Document doc = Jsoup.parseBodyFragment(HTMLCode.toString());

        FileOutputStream outputStream;
        try {
            outputStream = new FileOutputStream(filename);
            outputStream.write(doc.body().html().getBytes());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}