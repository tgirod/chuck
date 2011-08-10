public class Mlr extends Launchpad
{
	static Mlr singleton;
	
	120 => float bpm;
	Track track[8];
	for (0 => int i; i<8; i++)
	{
		this @=> track[i].parent;
		i => track[i].group;
	}
	
	fun void keyEvent(int row, int col, int press)
	{
		if (row == -1) return; // discard control events
		if (!press) return; // discard release events
		
		track[row] @=> Track t;
		
		if (col < 8) { // matrix event
			if (!t.isLoaded()) return;
			groupStop(row);
			t.play(col);
		} else { // scene event
			if (!t.isLoaded()) return;
			if (t.playing) {
				t.stop();
			} else {
				groupStop(row);
				t.play(0);
			}
		}
	}

	fun void clearRow(int row)
	{
		for (0 => int i; i<9; i++)
		{
			if (getColor(row,i) != 0) setColor(row,i,0);
		}
	}
	
	fun void groupStop(int t)
	{
		track[t].group => int g;
		for (0 => int i; i<8; i++)
		{
			if (i != t && track[i].group == g)
			{
				track[i].stop();
			}
		}
	}
	
	fun void pitch()
	{
		for (0 => int i; i<8; i++)
		{
			track[i].pitch();
		}
	}
	
	fun void load(int t, string fname, int beats, int group)
	{
		track[t].load(fname, beats, group);
	}

	fun void setBpm(int bpm)
	{
		bpm => this.bpm;
		pitch();
	}
}

class PlayEvent extends Event
{
	int step;
}

class StopEvent extends Event
{}

class Track
{
	Mlr @ parent;
	SndBuf buf;
	int beats;
	int group;
	int row;
	int currentStep;
	time nextUpdate;

	PlayEvent play;
	StopEvent stop;
	Shred playing;
	
	// load a loop
	fun void load(Mlr parent, string fname, int beats, int group, int row)
	{
		parent @=> this.parent;
		fname => buf.read;
		true => buf.loop;
		beats => this.beats;
		group => this.group;
		row => this.row;
		pitch();
	}
	
	fun void playHandler()
	{
		while (true)
		{
			play => now;
			
		}
	}

	fun void stopHandler()
	{
		if (isPlaying()) {
			playing.exit();
			parent.clearRow(row);
		}
	}
	
	fun int isLoaded()
	{
		return buf.samples() != 0;
	}
	
	fun int isPlaying()
	{
		return (playing != null);
	}
	
	fun dur trackLength()
	{
		return (beats / parent.bpm * 60)::second;
	}
	
	fun dur stepLength()
	{
		return trackLength() / 8;
	}
	
	// pitch the buffer so it has the right duration
	fun void pitch()
	{
		if (!isLoaded()) return;
		buf.length() / trackLength() => buf.rate;		
	}
	
	fun void play(int step)
	{
		step % 8 => currentStep;
		step * buf.samples() / 8 => buf.pos;
		
		if (!playing)
		{
			buf => dac;
			true => playing;
		}
	}
	
	fun void stop()
	{
		if (playing)
		{
			buf !=> dac;
			false => playing;
		}
	}
}

// Mlr m;
// 180 => m.bpm;
// m.load(0,"/home/tom/Audio/chuck/drum/altan_Seq01_amen.wav",16,0);
// m.connect(1);
// m.listen();
