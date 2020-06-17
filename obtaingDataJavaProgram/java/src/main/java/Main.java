import database.DatabaseController;
import download.DownloadController;
import download.Match;

public class Main {
    public static void main(String[] args) {

        for (Match m : DownloadController.getAllMatches())
        {
            System.out.println(m);
        }

    }
}




//        Map<Integer, String> links = new HashMap<>();
//        links.put(1, "https://ligaportugal.vsports.pt/mday/1710/liga/da784ff291c217a7ce9591fac5d45111");
//        links.put(2, "https://ligaportugal.vsports.pt/mday/1711/liga/374a658378ec070b680b34f97d50d4f6");
//        links.put(3, "https://ligaportugal.vsports.pt/mday/1712/liga/e679886ef6862978d2e3fdfeb9d8b835");
//        links.put(4, "https://ligaportugal.vsports.pt/mday/1713/liga/8d395d43f3f760d9d93dd2723067dc18");
//        links.put(5, "https://ligaportugal.vsports.pt/mday/1714/liga/255f9cc10f9a93acc4f7c05e0a288dba");
//        links.put(6, "https://ligaportugal.vsports.pt/mday/1715/liga/eca0b978190d6b6b62fe095865f40909");
//        links.put(7, "https://ligaportugal.vsports.pt/mday/1716/liga/0c9d0e61ae4e4822c33ef67e731c3b37");
//        links.put(8, "https://ligaportugal.vsports.pt/mday/1717/liga/52d858e715c3841d7011f373884d07cb");
//        links.put(9, "https://ligaportugal.vsports.pt/mday/1718/liga/161c9bdba222dc4f13ed9f1f8d766255");
//        links.put(10, "https://ligaportugal.vsports.pt/mday/1719/liga/4d466e73f5c13979bf55edacfa7005d7");
//        links.put(11, "https://ligaportugal.vsports.pt/mday/1720/liga/2ae3393558bedc896a1f2bac9a8f09df");
//        links.put(12, "https://ligaportugal.vsports.pt/mday/1721/liga/579dee0567902a54b275624749f9338c");
//        links.put(13, "https://ligaportugal.vsports.pt/mday/1722/liga/3f9da10b77ad895f1688642e740134cd");
//        links.put(14, "https://ligaportugal.vsports.pt/mday/1723/liga/0ab0ec4a6eb1af08ca061825d99aae31");
//        links.put(15, "https://ligaportugal.vsports.pt/mday/1724/liga/82f23fdf3290903e70cb7d45222dde0c");
//        links.put(16, "https://ligaportugal.vsports.pt/mday/1725/liga/4593003ed576c411c8f47d32c00fb056");
//        links.put(17, "https://ligaportugal.vsports.pt/mday/1726/liga/d96d1f219b90695ffc0cca830d44e3f1");
//        links.put(18, "https://ligaportugal.vsports.pt/mday/1727/liga/c15854ffcea5f8767844bfcb982cd844");
//        links.put(19, "https://ligaportugal.vsports.pt/mday/1728/liga/7d84b14103ff4093cd43e4418f204b4c");
//        links.put(20, "https://ligaportugal.vsports.pt/mday/1729/liga/bc078a778a2ab421aa8478df96e8d959");
//        links.put(21, "https://ligaportugal.vsports.pt/mday/1730/liga/222de664c77d1b084c38834f53062860");
//        links.put(22, "https://ligaportugal.vsports.pt/mday/1731/liga/c891d9de647bab800688dc7755020bcf");
//        links.put(23, "https://ligaportugal.vsports.pt/mday/1732/liga/27074ec5f8bf05ee563247624783e0d1");
//        links.put(24, "https://ligaportugal.vsports.pt/mday/1733/liga/ea934df3e59c5c22413d6721c23195db");
//        links.put(25, "https://ligaportugal.vsports.pt/mday/1734/liga/3de70295befb2e7bc4a4e4a1e8379473");
//        links.put(26, "https://ligaportugal.vsports.pt/mday/1735/liga/c1453840a599e66fd2ae136a4295963c");
//        links.put(27, "https://ligaportugal.vsports.pt/mday/1736/liga/abc926d8e7e2558a1dd7c515d102a5ed");
//        links.put(28, "https://ligaportugal.vsports.pt/mday/1737/liga/7ccd2836ba27f666501326964241becd");
//        links.put(29, "https://ligaportugal.vsports.pt/mday/1738/liga/069d077a51a12e6132c1d28fb18ba348");
//        links.put(30, "https://ligaportugal.vsports.pt/mday/1739/liga/10b774dff0f2f107b77da03520e04f8c");
//
//        int round = 1;
//        for (Map.Entry<Integer, String> entry : links.entrySet()) {
//            if(round <= 24){
//                OracleController.generateInserts(DownloadController.getMatches(entry.getValue(), round), entry.getKey());
//            }
//            round++;
//        }

//        String link = "https://ligaportugal.vsports.pt/mday/1733/liga/ea934df3e59c5c22413d6721c23195db";
//        ArrayList<download.Match> matches = ;
//        for (download.Match match : matches) {
//            System.out.println(match);
//        }
