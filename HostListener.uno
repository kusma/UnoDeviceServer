using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.IO;
using Uno.Net;
using Uno.Net.Sockets;
using Uno.Text;
using Uno.Threading;

public interface IHostConnection
{
	int Available { get; }
	Stream GetStream();
}

class SocketHostConnecton : IHostConnection
{
	readonly Socket _socket;
	NetworkStream _stream;

	public SocketHostConnecton(Socket socket)
	{
		_socket = socket;
	}

	public int Available { get { return _socket.Available; } }

	public Stream GetStream()
	{
		if (_stream == null)
			_stream = new NetworkStream(_socket);

		return _stream;
	}
}

class HostListener
{
	readonly int _port;
	Socket _listener;

	public HostListener(int port)
	{
		_listener = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
		_port = port;
	}

	public void Start()
	{
		_listener.Bind(new IPEndPoint(IPAddress.Any, _port));
		_listener.Listen(1);
	}

	public bool Pending()
	{
		return _listener.Poll(0, SelectMode.Read);
	}

	public SocketHostConnecton Accept()
	{
		var clientSocket = _listener.Accept();
		return new SocketHostConnecton(clientSocket);
	}
}

extern(JAVASCRIPT) class WebSocketHostConnecton : IHostConnection
{
	readonly JsWebSocket _webSocket;
	WebSocketStream _stream;

	public WebSocketHostConnecton(JsWebSocket webSocket)
	{
		_webSocket = webSocket;
	}

	public int Available { get { return _webSocket.Available; } }

	public Stream GetStream()
	{
		if (_stream == null)
			_stream = new WebSocketStream(_webSocket);

		return _stream;
	}
}

public static class HostConnection
{
	public static IHostConnection Connect(int port)
	{
		if defined(JAVASCRIPT)
		{
			var socket = new JsWebSocket("ws://localhost:" + port);
			return new WebSocketHostConnecton(socket);
		}
		else
		{
			var listener = new HostListener(port);
			listener.Start();

			var ret = listener.Accept();
			// TODO: listener.Dispose();
			return new SocketHostConnecton(ret);
		}

		return null;
	}
}
