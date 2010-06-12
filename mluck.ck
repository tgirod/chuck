// This is a very crude clone of the mlr app, written with Max 5 for the
// monome. mluck is written to be used with Novation's Launchpad, the cheap
// monome ripoff. to use mluck, you will need launchpad.ck in order to
// communicate with the interface.

public class Mluck
{
	Track track[8];		// the 8 tracks
	float bpm;			// the playback speed
	Launchpad @ lp;		// the launchpad object
	
	for (0 => int i; i<8; i++) {
		i => track[i].id;
		i => track[i].group;
		this @=> track[i].mluck;
	}
	
	fun void init(float bpm_, Launchpad lp_)
	{
		bpm_ => bpm;
		lp_ @=> lp;
	}
	
	fun void setBpm(float bpm_)
	{
		bpm_ => bpm;
		for (0=>int i; i<8; i++) track[i].pitch();
	}
	
	fun void playView(int id)
	{
		lp.scene(id,3,3);
	}
	
	fun void stopView(int id)
	{
		lp.scene(id,0,0);
		lp.grid(id,track[id].step,0,0);
	}

	fun void stepView(int id, int prev, int next)
	{
		lp.grid(id,prev,0,0); // turn off the previous step
		lp.grid(id,next,3,3); // turn on the next step
	}
	
	fun void listen()
	{
		spork ~ gridListen();
		spork ~ sceneListen();
		while (true) 1::second => now;
	}
	
	fun void gridListen()
	{
		while (true) {
			lp.grid_event => now;
			lp.grid_event.row => int t; // track
			lp.grid_event.col => int s; // step
			track[t].group => int g;    // track's group
			if (lp.grid_event.press) {
				// stop any other track of the group that is currently playing
				for (0=>int i; i<8; i++) {
					if (i != t && track[i].group == g && track[i].playing) {
						track[i].stop();
					}
				}
				// jump around ! jump around !
				track[t].seek(s);
			}
		}
	}
	
	fun void sceneListen()
	{
		while (true) {
			lp.scene_event => now;
			if (lp.scene_event.press) {
				lp.scene_event.key => int l;
				if (track[l].playing) {
					track[l].stop();
				} else {
					track[l].seek(0);
				}
			}
		}
	}
}

class Track
{
	SndBuf buf;					// the sound to play
	0 => int initialized;		// is the track initialized ?
	0 => int playing;			// is the track currently playing ?
	0.2 => buf.gain;			// the track's volume
	1 => buf.loop;				// we want to loop
	0 => int step;				// the current step
	time nextStep;				// when we will switch to the next step
	int length;					// number of beats in the track
	UGen @ out;					// where to connect the output
	int id;						// the id of the track
	int group;					// tracks are grouped
	Mluck @ mluck;				// the parent object
	
	fun void init(string fname_, int length_, int group_, UGen out_)
	{
		fname_ => buf.read;
		length_ => length;
		out_ @=> out;
		group_ => group;
		pitch();
		1 => initialized;
	}
	
	// duration of the track
	fun dur trackLength()
	{
		return (length / mluck.bpm * 60)::second;
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
	
	fun void setLength(int length_)
	{
		length_ => length;
		pitch();
	}

	fun void setGroup(int group_)
	{
		group_ => group;
	}
	
	// starts playing
	fun void play()
	{
		if (!initialized) return;
		mluck.playView(id);
		buf => out;
		1 => playing;
		while (playing) {
			if (now >= nextStep) {
				step => int prev;
				(step +1) % 8 => int next;
				mluck.stepView(id, prev, next);
				next => step;
				nextStep + stepLength() => nextStep;
			}
			1::ms => now;
		}
	}
	
	// stops playing
	fun void stop()
	{
		if (!initialized) return;
		buf !=> out;
		0 => playing;
		mluck.stopView(id);
	}
	
	// move the cursor to the step
	fun void seek(int step_)
	{
		if (!initialized) return;
		step => int prev;
		step_ => int next;
		mluck.stepView(id,prev,next);
		step_ => step;
		step * buf.samples() / 8 => buf.pos;
		now + stepLength() => nextStep;
		if (!playing) spork ~ play();
	}
}

