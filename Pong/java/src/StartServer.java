
public class StartServer
{

    /**
     * @param args
     */
    public static void main(String[] args)
    {
        PongServer server = new PongServer(1011);
        new Thread(server).start();
    }
}
