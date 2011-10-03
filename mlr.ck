public class Mlr extends Launchpad
{
	
	120 => float bpm;
	Track track[8];
	for (0 => int i; i<8; i++)
	{
		this @=> track[i].parent;
		i => track[i].group;
	}

	fun void start(int port)
	{
		connect(port);
		spork ~ displayShred();
		listen();
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

	fun void groupStop(int t)
	{
		track[t].group => int g;
		for (0 => int i; i<8; i++)
		{
			if (i != t && track[i].group == g)
			{
				track[i].stop();
				rowOff(i);
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
	
	fun void load(int t, string fname, int beats, int group, UGen output)
	{
		track[t].load(this, fname, beats, group, t, output);
	}

	fun void setBpm(int bpm)
	{
		bpm => this.bpm;
		pitch();
	}
	
	// turn off all the lights for one row
	fun void rowOff(int row)
	{
		for (0 => int i; i<9; i++)
		{
			setColor(row,i,0);
		}
	}

	// turn the current step on + the scene button
	fun void rowOn(int row, int col)
	{		
		for (0 => int i; i<8; i++)
		{
			if (i == col) {
				setColor(row,i,127);
			} else {
				setColor(row,i,0);
			}
		}
		setColor(row,8,127);
	}

	fun void displayShred()
	{
		Track @ tr;
		while (1) {
			for (0 => int r; r<8; r++) {
				track[r] @=> tr;
				if (tr.playing) {
					rowOn(r,tr.currentStep);
					if (tr.nextUpdate <= now) {
						tr.nextUpdate + tr.stepLength() => tr.nextUpdate;
						(tr.currentStep + 1) % 8 => tr.currentStep;
					}
				} else {
					rowOff(r);
				}
			}
			10::ms => now;
		}
	}
}

class Track
{
	Mlr @ parent;
	UGen @ output;
	SndBuf buf;
	int beats;
	int group;
	int row;
	int currentStep;
	time nextUpdate;
	int playing;
	
	// load a loop
	fun void load(Mlr parent, string fname, int beats, int group, int row, UGen output)
	{
		parent @=> this.parent;
		output @=> this.output;
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
		now + stepLength() => nextUpdate;
		
		if (!playing) {
			buf => output;
			true => playing;
		}
	}
	
	fun void stop()
	{
		if (playing) {
			buf !=> output;
			false => playing;
		}
	}

	fun void setOutput(UGen u)
	{
		u @=> output;
	}
}
