using Uno;
using Uno.IO;
using Uno.Net;
using Uno.Net.Sockets;
using Uno.Threading;

public partial class MainView : Uno.Application
{
	IHostConnection _hostConnection;

	public MainView()
	{
//		InitializeUX();

		try
		{
			debug_log("listening for host...");
			_hostConnection = HostConnection.Connect(1337);
			debug_log("connected!");

			var streamWriter = new StreamWriter(_hostConnection.GetStream());
			streamWriter.WriteLine("hello server!\n");
			streamWriter.Flush();

//			UpdateManager.AddAction(PollMessages);

			debug_log("said hi!");
		}
		catch (Exception e)
		{
			debug_log("error: " + e);
		}
	}

	public override void Update()
	{
		PollMessages();
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
				// _message.Value = message;
			}
		}
		catch (Exception e)
		{
			debug_log("error: " + e);
		}
	}
}
