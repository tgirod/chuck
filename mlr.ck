public class Mlr extends Launchpad
{
	
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
		if (!t.isLoaded()) return; // discard if the track is not loaded
		
		if (col < 8) { // matrix event
			groupStop(row);
			t.play(col);
		} else { // scene event
			if (t.isPlaying()) {
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
		track[t].load(this, fname, beats, group, t);
	}

	fun void setBpm(int bpm)
	{
		bpm => this.bpm;
		pitch();
	}
}

class Track
{
	Mlr @ parent;
	SndBuf buf;
	int beats;
	int group;
	int row;
	int currentStep;
	time nextUpdate;

	int playing;
	
	// load a loop
	fun void load(Mlr parent, string fname, int beats, int group, int row)
	{
		parent @=> this.parent;
		fname => buf.read;
		true => buf.loop;
		beats => this.beats;
		group => this.group;
		row => this.row;
		0 => playing;
		pitch();
	}
		
	fun int isLoaded()
	{
		return buf.samples() != 0;
	}
	
	fun int isPlaying()
	{
		return playing;
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
