using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.IO;
using Uno.Net;
using Uno.Net.Sockets;
using Uno.Text;
using Uno.Threading;

public static class HostConnection
{
	public static Stream Connect(int port)
	{
		if defined(JAVASCRIPT)
		{
			var webSocket = new JsWebSocket("ws://localhost:" + port);
			return new WebSocketStream(webSocket);
		}
		else
		{
			var serverSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
			serverSocket.Bind(new IPEndPoint(IPAddress.Any, port));
			serverSocket.Listen(1);

			var clientSocket = serverSocket.Accept();
			return new NetworkStream(clientSocket);
		}

		return null;
	}
}
