Std.atoi(me.arg(0)) => int launchpad;
Std.atoi(me.arg(1)) => int synth;
Std.atoi(me.arg(2)) => int octave;
Std.atoi(me.arg(3)) => int ecart;

MidiIn lp_in;
MidiOut lp_out;
MidiOut synth_out;

MidiMsg lp_msg, synth_msg;

lp_in.open(launchpad);
lp_out.open(launchpad);
synth_out.open(synth);

while (true) {
	lp_in => now;
	while (lp_in.recv(lp_msg)) {
		if (lp_msg.data1 == 0x90) {
			lp_msg.data2 / 16 $ int => int row;
			lp_msg.data2 % 16 $ int => int col;
			0x90 => synth_msg.data1;
			octave*12 + row + col * ecart => synth_msg.data2;
			lp_msg.data3 => synth_msg.data3;
			synth_out.send(synth_msg);
			lp_out.send(lp_msg);
		}
	}
}
