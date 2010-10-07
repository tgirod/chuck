public class Mlr {
	static float bpm;
	static Track @ track[8];

	fun static void init()
	{
		120 => bpm;
		Track t[8] @=> track;
	}
	
	// change BPM and repitch everything
	fun static void setBpm(float bpm_)
	{
		bpm_ => bpm;
		pitch();
	}
	
	// load a new track
	fun static void load(int row, string fname, int length, int group, float gain)
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

	fun static void setLength(int row, int length)
	{
		track[row].setLength(length);
	}

	fun static void start(int row)
	{
		track[row].start();
	}

	fun static void stop(int row)
	{
		track[row].stop();
	}

	fun static void skip(int row, int step)
	{
		track[row].skip(step);
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
}

// initialize static attributes
Mlr.init();

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
		MidiInterface.turnOn(row,step);
		env.keyOn();
		while (playing) {
			if (now >= nextStep) {
				MidiInterface.turnOff(row,step);
				now + stepLength() => nextStep;
				(step+1) % 8 => step;
				MidiInterface.turnOn(row,step);
			}
			1::ms => now;
		}
		env.keyOff();
		env.duration() => now;
		//env =< dac.chan(row);
		env =< dac;
		MidiInterface.turnOff(row,step);
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
		MidiInterface.turnOff(row,step);
		env.keyOff();
		env.duration() => now;
		step_ % 8 => step;
		step * buf.samples() / 8 => buf.pos;
		Mlr.groupStop(row);
		if (playing) {
			now + stepLength() => nextStep;
			MidiInterface.turnOn(row,step);
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
	
	fun void setLength(int length_)
	{
		length_ => length;
		pitch();
	}
}

////////////////////
// MIDI INTERFACE //
////////////////////

class MidiInterface
{
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
						if (Mlr.track[row].playing) {
							Mlr.track[row].stop();
						} else {
							Mlr.track[row].skip(0);
							Mlr.track[row].start();
						}
					} else {
						// matrix button
						Mlr.track[row].skip(col);
						if (!Mlr.track[row].playing) {
							Mlr.track[row].start();
						}
					}
				}
			}
		}
	}
	
	fun static void turnOn(int row, int col)
	{
		Launchpad.send3(0x90, row * 16 + col, 127);
	}
	
	fun static void turnOff(int row, int col)
	{
		Launchpad.send3(0x90, row * 16 + col, 0);
	}
}

///////////////////
// OSC INTERFACE //
///////////////////

class Handler
{
	OscEvent e;
	string format;
	
	fun void listen(OscRecv orec)
	{
		orec.event(format) @=> e;
		while (true) {
			e => now;
			while (e.nextMsg() != 0) {
				<<< "OSC message" >>>;
				parse();
			}
		}
	}

	fun void parse()
	{
		return;
	}
}

class BpmHandler extends Handler
{
	"/mlr/bpm,f" => format;
	
	fun void parse()
	{
		Mlr.setBpm(e.getFloat());
	}
}

class LoadHandler extends Handler
{
	"/mlr/load,isiif" => format;
	fun void parse()
	{
		Mlr.load(e.getInt(), e.getString(), e.getInt(), e.getInt(), e.getFloat());
	}
}

class LengthHandler extends Handler
{
	"/mlr/length,ii" => format;
	fun void parse()
	{
		Mlr.setLength(e.getInt(), e.getInt());
	}
}

class GroupHandler extends Handler
{
	"/mlr/group,ii" => format;
	fun void parse()
	{
		Mlr.setGroup(e.getInt(), e.getInt());
	}
}

class GainHandler extends Handler
{
	"/mlr/gain,if" => format;
	fun void parse()
	{
		Mlr.setGain(e.getInt(), e.getFloat());
	}
}

class StartHandler extends Handler
{
	"/mlr/start,i" => format;
	fun void parse()
	{
		Mlr.start(e.getInt());
	}
}

class StopHandler extends Handler
{
	"/mlr/stop,i" => format;
	fun void parse()
	{
		Mlr.stop(e.getInt());
	}
}

class SkipHandler extends Handler
{
	"/mlr/skip,ii" => format;
	fun void parse()
	{
		Mlr.skip(e.getInt(),e.getInt());
	}
}

class OscInterface
{
	static OscRecv @ orec;
	static Handler @ bpm, load, length, group, gain, start, stop, skip;

	fun static void init()
	{
		new OscRecv @=> orec;
		1213 => orec.port;
		
		new BpmHandler @=> bpm;
		new LoadHandler @=> load;
		new LengthHandler @=> length;
		new GroupHandler @=> group;
		new GainHandler @=> gain;
		new StartHandler @=> start;
		new StopHandler @=> stop;
		new SkipHandler @=> skip;
	}
	
	fun static void listen()
	{
		orec.listen();
		spork ~ bpm.listen(orec);
		spork ~ load.listen(orec);
		spork ~ length.listen(orec);
		spork ~ group.listen(orec);
		spork ~ gain.listen(orec);
		spork ~ start.listen(orec);
		spork ~ stop.listen(orec);
		spork ~ skip.listen(orec);
	}		
}

OscInterface.init();
OscInterface.listen();
MidiInterface.listen();
