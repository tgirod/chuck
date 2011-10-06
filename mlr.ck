public class Mlr extends Launchpad
{

	120 => float bpm;
	8 => int length; // sequence's length
	4 => int quantize; // number of ticks per beat in the sequence
	Track track[8];
	
	0 => int learn; // are we in learn mode ?
	0 => int currentStep;
	0 => int currentQuanta;
	time timeOfCurrentQuanta;
	
	fun void init(float bpm, int length, int quantize)
	{
		bpm => this.bpm;
		length => this.length;
		quantize => this.quantize;

		for (0 => int i; i<8; i++){
			track[i].init(this);
		}
		pitch();
	}

	fun void sequencer()
	{
		while (1) {
			for (0 => currentQuanta; currentQuanta < quantize ; currentQuanta++) {
				if (currentQuanta == 0) {
					setColor(-1,7,127);
				} else {
					setColor(-1,7,0);
				}
				
				now => timeOfCurrentQuanta;
				// for each track, play the current quanta's event if there is one
				for (0 => int i; i<8; i++) {
					track[i].sequence[currentStep][currentQuanta] => int ev;
					if (track[i].isLoaded() && track[i].isPlaying() && ev != -1) {
						track[i].play(ev);
					}
				}
				quantaLength() => now;
			}
			(currentStep+1) % length => currentStep;
		}
	}
	
	fun dur quantaLength()
	{
		return 60::second / bpm / quantize;
	}

	fun void pitch()
	{
		for (0 => int i; i<8; i++)
		{
			track[i].pitch();
		}
	}
	
	fun void load(int t, string fname, int beats, int group, float gain, UGen output)
	{
		track[t].load(fname, beats, group, t, gain, output);
	}
	
	fun void start(int port)
	{
		connect(port);
		spork ~ sequencer();
		spork ~ displayShred();
		listen();
	}
	
	fun void keyEvent(int row, int col, int press)
	{
		// discard if release event
		if (!press) return;
		
		// control event
		if (row == -1) {
			// (un)toggle learn mode
			if (col == 0) {
				!learn => learn;
				setColor(-1,0,127*learn);
			} else if (col == 7) {
				length-1 => currentStep;
				quantize-1 => currentQuanta;
			}
			return;
		}
				
		track[row] @=> Track t;
		// discard if the track is not loaded
		if (!t.isLoaded()) return; 
		
		// scene event: start/stop/clear
		if (col == 8) {
			if (learn) {
				// clear sequence
				t.clearSequence();
			} else {
				// start/stop
				if (t.isPlaying()) {
					t.stop();
				} else {
					groupStop(row);
					t.play(0);
				}
			}
			return;
		}
		
		// matrix event
		
		// record if in learn mode
		if (learn) {
			// quantize to the closest quanta
			currentStep => int s;
			currentQuanta => int q;
			if (now - timeOfCurrentQuanta > quantaLength()/2) {
				// quantize in the next quanta
				if (q == quantize-1) {
					(s+1) % length => s;
				}
				(q+1) % quantize => q;
			}
			col => t.sequence[s][q];
		}
		
		groupStop(row);
		t.play(col);
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

	int sequence[][];
	
	fun void init(Mlr parent)
	{
		parent @=> this.parent;
		int seq[parent.length][parent.quantize] @=> sequence;
		clearSequence();
	}

	fun void clearSequence()
	{
		for (0 => int s; s < parent.length; s++) {
			for (0=>int q; q<parent.quantize; q++) {
				-1 => sequence[s][q];
			}
		}
	}
	
	// load a loop
	fun void load(string fname, int beats, int group, int row, float gain, UGen output)
	{
		fname => buf.read;
		true => buf.loop;
		beats => this.beats;
		group => this.group;
		row => this.row;
		gain => buf.gain;
		output @=> this.output;
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
