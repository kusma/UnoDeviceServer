using Fuse;
using Uno;
using Uno.IO;
using Uno.Net;
using Uno.Net.Sockets;
using Uno.Threading;

public partial class MainView
{
	Thread _thread;
	HostConnecton _hostConnection;
	ConcurrentQueue<string> _messages = new ConcurrentQueue<string>();

	public MainView()
	{
		InitializeUX();

		try
		{
			debug_log("listening for host...");

			var listener = new HostListener(1337);
			listener.Start();
			_hostConnection = listener.Accept();

			debug_log("connected!");

			var streamWriter = new StreamWriter(_hostConnection.GetStream());
			streamWriter.WriteLine("hello server!\n");
			streamWriter.Flush();

			UpdateManager.AddAction(PollMessages);

			debug_log("said hi!");
		}
		catch (Exception e)
		{
			debug_log("error: " + e);
		}
	}

	void PollMessages()
	{
		try
		{
			while (_hostConnection.Available > 0)
			{
				var steamReader = new StreamReader(_hostConnection.GetStream());
				var message = steamReader.ReadLine();
				debug_log("GOT: " + message);
				_message.Value = message;
			}
		}
		catch (Exception e)
		{
			debug_log("error: " + e);
		}
	}
}
