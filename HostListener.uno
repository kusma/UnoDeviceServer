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

extern(JAVASCRIPT) class JsWebSocket
{
	[TargetSpecificType]
	struct WebSocketHandle
	{
		
	}

	WebSocketHandle _handle;

	public JsWebSocket(string url)
	{
		_handle = extern<WebSocketHandle>(url) "new WebSocket($0)";
		BinaryType("arraybuffer");
		var target = this;
		extern(_handle, this) "$0.onopen = function(e) { @{JsWebSocket.OnOpen():Call(target)}; }";
		extern(_handle, this) "$0.onerror = function(e) { @{JsWebSocket.OnError():Call(target)}; }";
		extern(_handle, this) "$0.onmessage = function(e) { @{JsWebSocket.OnMessage(byte[]):Call(target, e.data)}; }";
	}

	Queue<byte[]> _writeQueue;
	public void OnOpen()
	{
		if (_writeQueue != null)
		{
			while (_writeQueue.Count > 0)
			{
				var buf = _writeQueue.Dequeue();
				debug_log("sending " + buf.Length + " arrays of queued up data");
				extern(_handle, buf) "$0.send($1)";
			}

			_writeQueue = null;
		}

		debug_log("WEBZOXXOR IS OPEN FOR BUSINESS!!1");
	}

	public void OnError()
	{
		debug_log("WEBSOCKET ERROR");
	}

	Queue<byte> _readBuffer = new Queue<byte>();
	public void OnMessage(byte[] data)
	{
		debug_log("GOT DATA: \"" + Utf8.GetString(data) + "\"");
		for (int i = 0; i < data.Length; ++i)
			_readBuffer.Enqueue(data[i]);
	}

	void BinaryType(string str)
	{
		extern(_handle, str) "$0.binaryType = $1";
	}

	public void Send(byte[] data, int offset, int size)
	{
		var clone = new byte[size];
		Array.Copy(data, offset, clone, 0, size);

		var readyState = extern<int>(_handle) "$0.readyState";
		if (readyState == 0)
		{
			debug_log("queuing up " + size + " bytes");

			// the socket is still connecting, let's just queue up the bytes

			if (_writeQueue == null)
				_writeQueue = new Queue<byte[]>();

			_writeQueue.Enqueue(clone);
			return;
		}

		debug_log("sending " + data.Length + " bytes");
		extern(_handle, clone) "$0.send($1)";
	}

	public void Close(int code = 1000, string reason = null)
	{
		extern(_handle, code, reason) "$0.close($1, $2)";
	}

	public int Available { get { return _readBuffer.Count; } }

	public int Read(byte[] dst, int byteOffset, int byteCount)
	{
		byteCount = Math.Min(byteCount, _readBuffer.Count);

		for (int i = 0; i < byteCount; ++i)
			dst[byteOffset + i] = _readBuffer.Dequeue();

		return byteCount;
	}
}

extern(JAVASCRIPT) public class WebSocketStream : Stream
{
	readonly JsWebSocket _socket;

	public WebSocketStream(JsWebSocket socket)
	{
		_socket = socket;
	}

	public override long Length
	{
		get { return 0; }
	}

	public override long Position
	{
		get { return 0; }
		set { }
	}

	public override void SetLength(long value) { }

	public override bool CanRead
	{
		get { return true; }
	}

	public override bool CanWrite
	{
		get { return true; }
	}

	public override bool CanSeek
	{
		get { return false; }
	}

	public override int Read(byte[] dst, int byteOffset, int byteCount)
	{
		return _socket.Read(dst, byteOffset, byteCount);
	}

	public override void Write(byte[] src, int byteOffset, int byteCount)
	{
		_socket.Send(src, byteOffset, byteCount);
	}

	public override long Seek(long byteOffset, SeekOrigin origin)
	{
		return 0;
	}

	public override void Flush() { }
}

extern(JAVASCRIPT) class WebSocketHostConnecton : IHostConnection
{
	readonly JsWebSocket _webSocket;
	WebSocketStream _stream;

	public WebSocketHostConnecton(JsWebSocket webSocket)
	{
		_webSocket = webSocket;
	}

	public int Available { get { return 0; } }

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
