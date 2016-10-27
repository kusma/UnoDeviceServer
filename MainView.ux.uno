using Uno;
using Uno.IO;
using Uno.Net;
using Uno.Net.Sockets;
using Uno.Threading;

public partial class MainView : Uno.Application
{
	public MainView()
	{
//		InitializeUX();

		try
		{
			debug_log("listening for host...");
			var stream = HostConnection.Connect(1337);
			debug_log("connected!");

			var streamWriter = new StreamWriter(stream);
			streamWriter.WriteLine("hello server!\n");
			streamWriter.Flush();
			debug_log("said hi!");

			var steamReader = new StreamReader(stream);
			var message = steamReader.ReadLine();
			debug_log("GOT: " + message);

//			UpdateManager.AddAction(PollMessages);
		}
		catch (Exception e)
		{
			debug_log("error: " + e);
		}
	}
}
