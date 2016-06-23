using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;

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
		extern(_handle) "$0.binaryType = 'arraybuffer'";
		var target = this;
		extern(_handle, this) "$0.onopen = function(e) { @{JsWebSocket.OnOpen():Call(target)}; }";
		extern(_handle, this) "$0.onerror = function(e) { @{JsWebSocket.OnError():Call(target)}; }";
		extern(_handle, this) "$0.onmessage = function(e) { @{JsWebSocket.OnMessage(byte[]):Call(target, new Uint8Array(e.data))}; }";
	}

	List<byte[]> _writeQueue;
	public void OnOpen()
	{
		if (_writeQueue != null)
		{
			for (int i = 0; i < _writeQueue.Count; ++i)
			{
				var buf = _writeQueue[i];
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
		for (int i = 0; i < data.Length; ++i)
			_readBuffer.Enqueue(data[i]);
	}

	public enum ReadyStateEnum
	{
		Connecting = 0,
		Open = 1,
		Closing = 2,
		Closed = 3
	}

	ReadyStateEnum ReadyState { get { return (ReadyStateEnum)extern<int>(_handle) "$0.readyState"; } }

	public void Send(byte[] data, int offset, int size)
	{
		var clone = new byte[size];
		Array.Copy(data, offset, clone, 0, size);

		if (ReadyState == ReadyStateEnum.Connecting)
		{
			// the socket is still connecting, let's just queue up the bytes

			if (_writeQueue == null)
				_writeQueue = new List<byte[]>();

			_writeQueue.Add(clone);
			return;
		}

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
