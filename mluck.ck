// This is a very crude clone of the mlr app, written with Max 5 for the
// monome. mluck is written to be used with Novation's Launchpad, the cheap
// monome ripoff. to use mluck, you will need launchpad.ck in order to
// communicate with the interface.

class Loop
{
	SndBuf buf;					// the sound to play
	0 => int initialized;		// is the loop initialized ?
	0 => int playing;			// is the loop currently playing ?
	0.2 => buf.gain;			// the loop's volume
	1 => buf.loop;				// we want to loop
	0 => int step;				// the current step
	time nextStep;				// when we will switch to the next step
	int length;					// number of beats in the loop
	UGen @ out;					// where to connect the output
	int id;						// the id of the loop
	Mluck @ mluck;			// the parent object
	
	fun void init(string fname_, int length_, UGen out_)
	{
		fname_ => buf.read;
		length_ => length;
		out_ @=> out;
		pitch();
		1 => initialized;
	}
	
	// duration of the loop
	fun dur loopLength()
	{
		return (length / mluck.bpm * 60)::second;
	}
	
	// duration of one step
	fun dur stepLength()
	{
		return loopLength() / 8;
	}
	
	// pitch the buffer so it has the right duration
	fun void pitch()
	{
		if (!initialized) return;
		buf.length() / loopLength() => buf.rate;		
	}
	
	fun void setLength(int length_)
	{
		length_ => length;
		pitch();
	}
	
	// starts playing
	fun void play()
	{
		if (!initialized) return;
		mluck.play(id);
		buf => out;
		1 => playing;
		while (playing) {
			if (now >= nextStep) {
				step => int prev;
				(step +1) % 8 => int next;
				mluck.step(id, prev, next);
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
		mluck.stop(id);
	}
	
	// move the cursor to the step
	fun void seek(int step_)
	{
		if (!initialized) return;
		step => int prev;
		step_ => int next;
		mluck.step(id,prev,next);
		step_ => step;
		step * buf.samples() / 8 => buf.pos;
		now + stepLength() => nextStep;
		if (!playing) spork ~ play();
	}
}

public class Mluck
{
	Loop loop[8];
	float bpm;
	Launchpad @ lp;
	
	for (0 => int i; i<8; i++) {
		i => loop[i].id;
		this @=> loop[i].mluck;
	}
	
	fun void init(float bpm_, Launchpad lp_)
	{
		bpm_ => bpm;
		lp_ @=> lp;
	}

	fun void setBpm(float bpm_)
	{
		bpm_ => bpm;
		for (0=>int i; i<8; i++) loop[i].pitch();
	}
	
	fun void play(int id)
	{
		lp.scene(id,3,3);
	}
	
	fun void stop(int id)
	{
		lp.scene(id,0,0);
		lp.grid(id,loop[id].step,0,0);
	}
	
	fun void step(int id, int prev, int next)
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
			if (lp.grid_event.press) {
				loop[lp.grid_event.row].seek(lp.grid_event.col);
			}
		}
	}
	
	fun void sceneListen()
	{
		while (true) {
			lp.scene_event => now;
			if (lp.scene_event.press) {
				lp.scene_event.key => int l;
				if (loop[l].playing) {
					loop[l].stop();
				} else {
					loop[l].seek(0);
				}
			}
		}
	}
}
