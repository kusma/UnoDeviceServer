using Uno.IO;

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
