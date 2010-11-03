Std.atoi(me.arg(0)) => int lp_id;
Std.atoi(me.arg(1)) => int synth_id;
Std.atoi(me.arg(2)) => int octave;
Std.atoi(me.arg(3)) => int interval;

MidiIn lp_in;
MidiOut lp_out;
MidiOut synth_out;

MidiMsg lp_msg, synth_msg;

lp_in.open(lp_id);
lp_out.open(lp_id);
synth_out.open(synth_id);

while (true) {
	lp_in => now;
	while (lp_in.recv(lp_msg)) {
		if (lp_msg.data1 == 0x90) {
			lp_msg.data2 / 16 $ int => int row;
			lp_msg.data2 % 16 $ int => int col;
			0x90 => synth_msg.data1;
			octave*12 + row + col * interval => synth_msg.data2;
			lp_msg.data3 => synth_msg.data3;
			synth_out.send(synth_msg);
			lp_out.send(lp_msg);
		}
	}
}
