package download;

public class Match {

    public int round;

    public String teamA;
    public String teamB;

    public Integer scoreA;
    public Integer scoreB;

    public String hour;
    public String matchDate;

    public Match(int round, String teamA, String teamB, Integer scoreA, Integer scoreB, String hour, String matchDate) {
        this.round = round;
        this.teamA = teamA;
        this.teamB = teamB;
        this.scoreA = scoreA;
        this.scoreB = scoreB;
        this.hour = hour;
        this.matchDate = matchDate;
    }

    @Override
    public String toString() {
        return "date: " + matchDate + " " + hour + "\n" +
                scoreA + "\t : " + teamA + "\n" +
                scoreB + "\t : " + teamB + "\n";
    }
}
