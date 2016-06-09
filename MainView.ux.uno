using Uno;
using Uno.IO;
using Uno.Net;
using Uno.Net.Sockets;
using Uno.Threading;

public partial class MainView
{
	Thread _thread;

	public MainView()
	{
		InitializeUX();

		_thread = Thread.Create(RunServer);
		_thread.Start();
	}

	void RunServer()
	{
		try
		{
			var listener = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
			listener.Bind(new IPEndPoint(IPAddress.Any, 1337));

			var endPoint = listener.LocalEndPoint as IPEndPoint;
			debug_log("listening on: " + endPoint);

			listener.Listen(1);
			while (true)
			{
				var clientSocket = listener.Accept();
				var clientStream = new NetworkStream(clientSocket);

				var clientWriter = new StreamWriter(clientStream);
				clientWriter.WriteLine("hello server!\n");
				clientWriter.Flush();

				debug_log("reading...");
				var clientReader = new StreamReader(clientStream);
				var hello = clientReader.ReadLine();
				debug_log("GOT: " + hello);

				clientSocket.Shutdown(SocketShutdown.Both);
				clientSocket.Close();
			}

		}
		catch (Exception e)
		{
			debug_log("error: " + e);
		}
	}
}
