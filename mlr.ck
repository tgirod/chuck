public class Mlr {
	0 => static float bpm;
	static Track @ track[8];
	
	// load a new track
	fun static void load(string fname, int length, int row, int group, float gain)
	{
		track[row].stop();
		track[row].init(fname,length,row,group,gain);
	}

	fun static void setGain(int row, float gain)
	{
		track[row].setGain(gain);
	}

	fun static void setGroup(int row, int group)
	{
		track[row].setGroup(group);
	}
	
	fun static void setBpm(float bpm_)
	{
		bpm_ => bpm;
		pitch();
	}

	// stop all tracks from the same group as the given row
	fun static void groupStop(int row)
	{
		track[row].group => int group;
		for (0 => int i; i<8; i++) {
			if (track[i].group == group && track[i].row != row) {
				track[i].stop();
			}
		}
	}
	
	// pitch all tracks
	fun static void pitch()
	{
		for (0 => int i; i<8; i++) {
			track[i].pitch();
		}
	}
	
	fun static void listen()
	{
		while (true) {
			Launchpad.midi_in => now;
			
			if (Launchpad.msg_in.data1 == 0x90) {
				
				if (Launchpad.msg_in.data3 == 127) {
					// press event
					Launchpad.msg_in.data2 / 16 $ int => int row;
					Launchpad.msg_in.data2 % 16 => int col;
					
					if (col == 8) {
						// scene button
						if (track[row].playing) {
							track[row].stop();
						} else {
							track[row].skip(0);
							track[row].start();
						}
					} else {
						// matrix button
						track[row].skip(col);
						if (!track[row].playing) {
							track[row].start();
						}
					}
				}
			}
		}
	}
	
	fun static void turnOn(int row, int col) {
		Launchpad.send3(0x90, row * 16 + col, 127);
	}
	
	fun static void turnOff(int row, int col) {
		Launchpad.send3(0x90, row * 16 + col, 0);
	}
}

class Track {
	SndBuf buf => Envelope env; // sound buffer
	int length;			// number of beats in the loop
	int row;			// row number assignated on the launchpad
	int group;			// track group
	int step;			// step currently played
	time nextStep;      // when the next step will start
	int playing;		// are we playing right now ?
	false => int initialized;
	5::ms => env.duration; // to avoid clipping
	
	// initializes a track
	fun void init(string fname_, int length_, int row_, int group_, float gain_) {
		true => initialized;
		fname_ => buf.read;
		length_ => length;
		row_ => row;
		group_ => group;
		0 => step;
		false => playing;
		1 => buf.loop;
		gain_ => buf.gain;
		pitch();
		<<< "file:", fname_, "beats", length_, "row", row_, "group", group_, "gain", gain_ >>>;
	}
	
	// duration of the track
	fun dur trackLength()
	{
		return (length / Mlr.bpm * 60)::second;
	}

	// duration of one step
	fun dur stepLength()
	{
		return trackLength() / 8;
	}
	
	// pitch the buffer so it has the right duration
	fun void pitch()
	{
		if (!initialized) return;
		buf.length() / trackLength() => buf.rate;		
	}

	fun void run() {
		if (!initialized) return;
		true => playing;
		//env => dac.chan(row);
		env => dac;
		now + stepLength() => nextStep;
		Mlr.turnOn(row,step);
		env.keyOn();
		while (playing) {
			if (now >= nextStep) {
				Mlr.turnOff(row,step);
				now + stepLength() => nextStep;
				(step+1) % 8 => step;
				Mlr.turnOn(row,step);
			}
			1::ms => now;
		}
		env.keyOff();
		env.duration() => now;
		//env =< dac.chan(row);
		env =< dac;
		Mlr.turnOff(row,step);
	}

	fun void start() {
		if (!initialized) return;
		if (!playing) {
			Mlr.groupStop(row);
			spork ~ run();
		}
	}
	
	fun void stop() {
		if (!initialized) return;
		false => playing;
	}
	
	fun void skip(int step_)
	{
		if (!initialized) return;
		Mlr.turnOff(row,step);
		env.keyOff();
		env.duration() => now;
		step_ % 8 => step;
		step * buf.samples() / 8 => buf.pos;
		Mlr.groupStop(row);
		if (playing) {
			now + stepLength() => nextStep;
			Mlr.turnOn(row,step);
			env.keyOn();
		}
	}

	fun void setGain(float gain)
	{
		gain => buf.gain;
	}

	fun void setGroup(int group_)
	{
		group_ => group;
	}
}

<<< "initialize mlr" >>>;
// first start instance (server)
Std.atof(me.arg(0)) => Mlr.bpm;

Track t[8] @=> Mlr.track;

Mlr.listen();
