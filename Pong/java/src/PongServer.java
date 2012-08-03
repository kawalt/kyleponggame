
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * The Pong Server works by accepting connections two at a time. Once two connections are accepted, two WorkerRunnable 
 * threads are kicked off to handle the playing of a game. The server then goes back to listening for connections.
 * This is repeated until maxWorkers is reached, at which time any connection received will be ignored. When games end
 * and workers are freed up, the server again begins accepting connections.
 * 
 * @author Kyle
 *
 */
public class PongServer implements Runnable
{
    protected int serverPort = 1011;
    protected ServerSocket serverSocket = null;
    protected boolean isStopped = false;
    protected int connections = 0;
    protected ConcurrentLinkedQueue<WorkerRunnable> workers;
    protected Socket client1Socket = null;
    protected Socket client2Socket = null;
    protected WorkerRunnable worker1; 
    protected WorkerRunnable worker2;
    protected BufferedReader client1InputStream;
    protected BufferedReader client2InputStream;
    protected DataOutputStream client1OutputStream;
    protected DataOutputStream client2OutputStream;
    protected ConcurrentHashMap<Integer, Long> latencies;
    protected ConcurrentHashMap<Integer, String> playerStatus;
    private static final int maxWorkers = 8;
    
    public boolean stop = false;
    
    public PongServer(int port)
    {
        serverPort = port;
        workers = new ConcurrentLinkedQueue<WorkerRunnable>();
        latencies = new ConcurrentHashMap<Integer, Long>();
        latencies.put(1, 0L);
        latencies.put(2, 0L);
        playerStatus = new ConcurrentHashMap<Integer, String>();
        playerStatus.put(1, "disconnected");
        playerStatus.put(2, "disconnected");
    }

    public void run()
    {
        openServerSocket();
        while (!stop)
        {
            waitForConnections();
            if (connections == 2)
            {
                startWorkers();
                connections = 0;
            }
            else 
            {
                connections = 0;
            }
        }
        stop();
    }

    private void waitForConnections()
    {
        try 
        {
            if (connections % 2 == 0) 
            {
                System.out.println("Waiting for connection 1.");
                client1Socket = serverSocket.accept();
                client1OutputStream = new DataOutputStream(client1Socket.getOutputStream());
                if (workers.size() >= maxWorkers)
                {
                    client1OutputStream.write(("full" + "\0").getBytes());
                }
                else
                {
                    connections++;
                    client1OutputStream.write(("conn1" + "\0").getBytes());
                }
                
            }
            if (connections % 2 != 0)
            {
                System.out.println("Waiting for connection 2.");
                client2Socket = serverSocket.accept();
                connections++;
                client2OutputStream = new DataOutputStream(client2Socket.getOutputStream());
                client2OutputStream.write(("conn2" + "\0").getBytes());
            }
        }
        catch (IOException e) 
        {
            if(isStopped()) {
                System.out.println("Server Stopped.") ;
                return;
            }
            else 
            {
                stop();
            }
            throw new RuntimeException("Error accepting client connection", e);
        }
    }
    
    private void startWorkers()
    {
        try 
        {
            client1InputStream = new BufferedReader(new InputStreamReader(client1Socket.getInputStream()));
            client2InputStream = new BufferedReader(new InputStreamReader(client2Socket.getInputStream()));
        }
        catch (IOException e)
        {
            e.printStackTrace();
        }
        worker1 = new WorkerRunnable(client1InputStream, client1OutputStream, client2OutputStream, 1, latencies, playerStatus, workers);
        worker2 = new WorkerRunnable(client2InputStream, client2OutputStream, client1OutputStream, 2, latencies, playerStatus, workers);
        workers.add(worker1);
        workers.add(worker2);
        new Thread(worker1).start();
        new Thread(worker2).start();
    }

    private synchronized boolean isStopped() 
    {
        return isStopped;
    }

    public synchronized void stop()
    {
        isStopped = true;
        connections = 0;
        try 
        {
            serverSocket.close();
        } 
        catch (IOException e)
        {
            e.printStackTrace();
        }
    }

    private void openServerSocket() 
    {
        try 
        {
            serverSocket = new ServerSocket(serverPort);
        } 
        catch (IOException e) 
        {
            throw new RuntimeException("Cannot open port " + serverPort + ".", e);
        }
    }
}