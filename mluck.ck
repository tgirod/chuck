class Loop
{
	SndBuf buf;					// the sound to play
	0 => int initialized;		// is the loop initialized ?
	0 => int playing;			// is the loop currently playing ?
	0.2 => buf.gain;			// the loop's volume
	1 => buf.loop;				// we want to loop
	0 => int step;				// the current step
	time nextStep;				// when we will switch to the next step
	float bpm;					// the playback's speed
	int beats;					// number of beats in the loop
	UGen @ out;					// where to connect the output
	int id;						// the id of the loop
	Looper @ looper;			// the parent object
	
	fun void init(string fname_, float bpm_, int beats_, UGen out_)
	{
		fname_ => buf.read;
		bpm_ => bpm;
		beats_ => beats;
		out_ @=> out;
		pitch();
		1 => initialized;
	}
	
	// duration of the loop
	fun dur loopLength()
	{
		return (beats / bpm * 60)::second;
	}
	
	// duration of one step
	fun dur stepLength()
	{
		return loopLength() / 8;
	}
	
	// pitch the buffer so it has the right duration
	fun void pitch()
	{
		buf.length() / loopLength() => buf.rate;		
	}
	
	// starts playing
	fun void play()
	{
		if (!initialized) return;
		looper.play(id);
		buf => out;
		1 => playing;
		while (playing) {
			if (now >= nextStep) {
				step => int prev;
				(step +1) % 8 => int next;
				looper.step(id, prev, next);
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
		looper.stop(id);
	}
	
	// move the cursor to the step
	fun void seek(int step_)
	{
		if (!initialized) return;
		step => int prev;
		step_ => int next;
		looper.step(id,prev,next);
		step_ => step;
		step * buf.samples() / 8 => buf.pos;
		now + stepLength() => nextStep;
		if (!playing) spork ~ play();
	}
}

public class Looper
{
	Loop loop[8];
	
	Launchpad @ lp;
	
	for (0 => int i; i<8; i++) {
		i => loop[i].id;
		this @=> loop[i].looper;
	}

	fun void init(Launchpad _lp)
	{
		_lp @=> lp;
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
