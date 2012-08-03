import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;

/**

 */
public class WorkerRunnable implements Runnable
{
    protected BufferedReader ownedInputStream;
    protected DataOutputStream ownedOutputStream;
    protected DataOutputStream otherOutputStream;
    protected int connNum;
    private static int screenWidth = 1000;
    private static int dragRoom = 175;
    double ballX = 0;
    double ballY = 0;
    double ballXVel = 0;
    double ballYVel = 0;
    double distance = 0;
    double time = 0;
    double newBallXVel = 0;
    double newBallYVel = 0;
    double ballRot = 0;
    private static double msPerFrame = 22.222; // 45 fps
    private static int constantLagFactor = 3;
    private ConcurrentHashMap<Integer, Long> latencies;
    private ConcurrentHashMap<Integer, String> playerStatus;
    private static long waitForOtherPlayerDelay = 1000; // 1 seconds
    private static int waitForOtherPlayerRetries = 60; // total wait of 1 min
    private int isLagHigh = 1;
    private ConcurrentLinkedQueue<WorkerRunnable> workers;
    
    public boolean stop = false;
    
    public WorkerRunnable(BufferedReader theOwnedInputStream, DataOutputStream theOwnedOutputStream, DataOutputStream theOtherOutputStream, int theConnNum, ConcurrentHashMap<Integer, Long> theLatencies, ConcurrentHashMap<Integer, String> thePlayerStatus, ConcurrentLinkedQueue<WorkerRunnable> theWorkers) 
    {
        ownedInputStream = theOwnedInputStream;
        ownedOutputStream = theOwnedOutputStream;
        otherOutputStream = theOtherOutputStream;
        connNum = theConnNum;
        latencies = theLatencies;
        playerStatus = thePlayerStatus;
        workers = theWorkers;
    }

    public void run() 
    {
        try 
        {
            String xyLine = "";
            while (!stop)
            {
                xyLine = ownedInputStream.readLine();
                if (xyLine != null)
                {
                    xyLine = xyLine.trim();
                }
                else 
                {
                    ownedOutputStream.writeBytes("kill" + "\0");
                    otherOutputStream.writeBytes("kill" + "\0");
                    System.out.println("Stop.");
                    workers.remove(this);
                    stop = true;
                    return;
                }
                if (xyLine.equals("ready"))
                {
                    if (connNum == 1)
                    {
                        performLagTest(30);
                        for (int i = 0; i < waitForOtherPlayerRetries; i++)
                        {
                            if (playerStatus.get(2).equals("ready"))
                            {
                                ownedOutputStream.write(("ready" + "\0").getBytes());
                                try 
                                {
                                    Thread.sleep(waitForOtherPlayerDelay);
                                }
                                catch (InterruptedException e) 
                                {
                                    e.printStackTrace();
                                }
                                break;
                            }
                            else
                            {
                                try 
                                {
                                    Thread.sleep(waitForOtherPlayerDelay);
                                }
                                catch (InterruptedException e) 
                                {
                                    e.printStackTrace();
                                }
                            }
                        }
                    }
                    else if (connNum == 2)
                    {
                        performLagTest(30);
                        for (int i = 0; i < waitForOtherPlayerRetries; i++)
                        {
                            if (playerStatus.get(1).equals("ready"))
                            {
                                ownedOutputStream.write(("ready" + "\0").getBytes());
                                break;
                            }
                            else
                            {
                                try 
                                {
                                    Thread.sleep(waitForOtherPlayerDelay);
                                }
                                catch (InterruptedException e) 
                                {
                                    e.printStackTrace();
                                }
                            }
                        }
                    }
                }
                else if (xyLine.equals("start"))
                {
                    otherOutputStream.write((xyLine + "\0").getBytes());
                }
                else if (xyLine.equals("lt")) 
                {
                    performLagTest(5);
                }
                else if (xyLine != null && xyLine.length() > 0 && xyLine.charAt(0) == 'b')
                {
                    ballX = Double.parseDouble(xyLine.substring(xyLine.indexOf("x") + 1, xyLine.indexOf("y")));
                    ballY = Double.parseDouble(xyLine.substring(xyLine.indexOf("y") + 1, xyLine.lastIndexOf("x")));
                    ballXVel = Double.parseDouble(xyLine.substring(xyLine.lastIndexOf("x") + 2, xyLine.lastIndexOf("y")));
                    ballYVel = Double.parseDouble(xyLine.substring(xyLine.lastIndexOf("y") + 2, xyLine.indexOf("r")));
                    ballRot = Double.parseDouble(xyLine.substring(xyLine.indexOf("r") + 1));
                    double combinedLag = (((latencies.get(1) * 2) + (latencies.get(2) * 2)) * (constantLagFactor) / isLagHigh) / msPerFrame; // convert lag from ms to frames
                    if (connNum == 1)
                    {
                        distance = screenWidth - (dragRoom * 2) + (dragRoom - ballX);
                        time = distance / Math.abs(ballXVel);
                        newBallXVel = distance / (time - combinedLag);
                    }
                    else 
                    {
                        distance = screenWidth - (dragRoom * 2) + (ballX - (screenWidth - dragRoom));
                        time = distance / Math.abs(ballXVel);
                        newBallXVel = distance / (time - combinedLag);
                    }

                    if (ballXVel < 0)
                    {
                        newBallXVel = newBallXVel * -1;
                    }
                    distance = ballYVel * time;
                    newBallYVel = distance / (time - combinedLag);
                    
                    ballX = (double)Math.round(ballX * 100) / 100;
                    ballY = (double)Math.round(ballY * 100) / 100;
                    newBallXVel = (double)Math.round(newBallXVel * 100) / 100;
                    newBallYVel = (double)Math.round(newBallYVel * 100) / 100;
                    xyLine = "bx" + ballX + "y" + ballY + "xv" + newBallXVel + "yv" + newBallYVel + "r" + ballRot + "\0";
                    otherOutputStream.write((xyLine + "\0").getBytes());
                }
                else if (xyLine.equals("g"))
                {
                    playerStatus.put(1, "lagtest");
                    playerStatus.put(2, "lagtest");
                    performLagTest(5);
                    otherOutputStream.write((xyLine + "\0").getBytes());
                    for (int i = 0; i < waitForOtherPlayerRetries; i++)
                    {
                        if (playerStatus.get(1).equals("ready") && playerStatus.get(2).equals("ready"))
                        {
                            ownedOutputStream.write(("ready" + "\0").getBytes());
                            otherOutputStream.write(("ready" + "\0").getBytes());
                            System.out.println("Sent ready after goal");
                            break;
                        }
                        else
                        {
                            try
                            {
                                Thread.sleep(waitForOtherPlayerDelay);
                            }
                            catch (InterruptedException e)
                            {
                                e.printStackTrace();
                            }
                        }
                    }               
                }
                else if (xyLine != null)
                {
                    otherOutputStream.write((xyLine + "\0").getBytes());
                }
            }
            ownedInputStream.close();
            ownedOutputStream.close();
        } 
        catch (IOException e) 
        {
            System.out.println("Stop.");
            workers.remove(this);
            stop = true;
            return;
        }
    }
    
    private void performLagTest(int lagTrials) 
    {
        String lagString = "";
        long time = 0;
        try 
        {
            for (int i = 0; i < lagTrials - 1; i++)
            {
                time = System.currentTimeMillis();
                ownedOutputStream.write(("lagtest" + "\0").getBytes());
                lagString = ownedInputStream.readLine();
                if (lagString != null)
                {
                    lagString = lagString.trim();
                }
                else 
                {
                    ownedOutputStream.writeBytes("kill" + "\0");
                    otherOutputStream.writeBytes("kill" + "\0");
                    System.out.println("Stop.");
                    workers.remove(this);
                    stop = true;
                    return;
                }
                if (lagString.equals("lagtest"))
                {
                    time = System.currentTimeMillis() - time;
                    if (connNum == 1)
                    {
                       latencies.put(1, latencies.get(1) + time);
                    }
                    else
                    {
                        latencies.put(2, latencies.get(2) + time);
                    }
                }             
            }
            time = System.currentTimeMillis();
            ownedOutputStream.write(("flagtest" + "\0").getBytes());
            lagString = ownedInputStream.readLine();
            if( lagString != null)
            {
                lagString = lagString.trim();
            }
            else 
            {
                ownedOutputStream.writeBytes("kill" + "\0");
                otherOutputStream.writeBytes("kill" + "\0");
                System.out.println("Stop.");
                workers.remove(this);
                stop = true;                 
                return;
            }
            if (lagString.equals("flagtest"))
            {
                time = System.currentTimeMillis() - time;
                if (connNum == 1)
                {
                    latencies.put(1, latencies.get(1) + time);
                    latencies.put(1, latencies.get(1) / lagTrials);
                    System.out.println("Conn 1 Lag = " + latencies.get(1));
                }
                else
                {
                    latencies.put(2, latencies.get(2) + time);
                    latencies.put(2, latencies.get(2) / lagTrials);
                    System.out.println("Conn 2 Lag = " + latencies.get(2));
                }
            }        
        }
        catch (IOException e)
        {
            workers.remove(this);
            stop = true;
        }
        if (latencies.get(1) + latencies.get(2) > 40)
        {
            isLagHigh = 2;
        }
        else 
        {
            isLagHigh = 1;
        }
        if (connNum == 1)
        {
            playerStatus.put(1, "ready");
        }
        else if (connNum == 2)
        {
            playerStatus.put(2, "ready");
        }
    }
}