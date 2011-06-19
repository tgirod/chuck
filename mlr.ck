public class Mlr extends Launchpad
{
	120 => float bpm;
	Track track[8];
	for (0 => int i; i<8; i++)
	{
		this @=> track[i].parent;
		i => track[i].group;
	}
	
	fun void matrixEvent(int row, int col, int press)
	{
		if (!press) return;
		track[row] @=> Track t;
		if (!t.isLoaded()) return;
		t.play(col);
	}
	
	fun void sceneEvent(int row, int press)
	{
		if (!press) return;
		track[row] @=> Track t;
		if (!t.isLoaded()) return;
		
		if (t.playing)
		{
			t.stop();
		}
		else
		{
			t.play(0);
		}
	}

	fun void display()
	{
		while (true)
		{
			
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

class Track
{
	Mlr @ parent;
	SndBuf buf;
	int beats;
	int group;
	int playing;
	int currentStep;
	time nextStep;
	
	fun int isLoaded()
	{
		return buf.samples() != 0;
	}
	
	// load a loop
	fun void load(string fname, int beats, int group)
	{
		fname => buf.read;
		true => buf.loop;
		beats => this.beats;
		group => this.group;
		pitch();
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
		now + stepLength() => nextStep;
		
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
