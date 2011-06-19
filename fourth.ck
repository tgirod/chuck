Std.atoi(me.arg(0)) => int lp_id;
Std.atoi(me.arg(1)) => int synth_id;
Std.atoi(me.arg(2)) => int octave;

public class Fourth extends Launchpad
{
	MidiOut synth_out;
	MidiMsg msg_synth_out;
	
	fun void connect(int lp_id, int synth_id)
	{
		connect(lp_id);
		
		// open the synth port;
		if (!synth_out.open(synth_id)) {
			<<< "can't open synth out" >>>;
			me.exit();
		}

		<<< "connected to the synth" >>>;
	}

	fun void matrixEvent(int row, int col, int press)
	{
		0x90 => msg_synth_out.data1;
		octave*12 + row + col * 4 => msg_synth_out.data2;
		127 * press => msg_synth_out.data3;
		synth_out.send(msg_synth_out);
		matrixLed(row,col,press*127);
	}
}

Fourth f;

f.connect(lp_id, synth_id);

f.listen();
