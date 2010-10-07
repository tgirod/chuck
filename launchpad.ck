public class Launchpad {
	
	// launchpad -> chuck
	static MidiIn @ midi_in;
	static MidiMsg @ msg_in;
	
	// chuck -> launchpad
	static MidiOut @ midi_out;
	static MidiMsg @ msg_out;
	
	fun static void listen(int port)
	{
		// initialize midi objects
		new MidiIn @=> midi_in;
		new MidiMsg @=> msg_in;
		
		new MidiOut @=> midi_out;
		new MidiMsg @=> msg_out;
		
		// open the midi ports
		if (!midi_out.open(port)) {
			<<< "can't open midi out" >>>;
			me.exit();
		}
		
		if (!midi_in.open(port)) {
			<<< "can't open midi in" >>>;
			me.exit();
		}

		<<< "launchpad ready" >>>;
		
		// listen to incoming midi messages
		while (true) {
			midi_in => now;
			while (midi_in.recv(msg_in));
		}
	}

	fun static void send()
	{
		midi_out.send(msg_out);
	}

	fun static void send3(int data1, int data2, int data3)
	{
		data1 => msg_out.data1;
		data2 => msg_out.data2;
		data3 => msg_out.data3;
		midi_out.send(msg_out);
	}
}

0 => int port;
if (me.args() == 1) {
	Std.atoi(me.arg(0)) => port;
}

Launchpad.listen(port);
