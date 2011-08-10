class Kali
{
	SndBuf buf;
	[0] @=> int steps[];
	float shuffle;
	
	int cursor;
	int go;
	
	fun void load(string fname, int steps[])
	{
		fname => buf.read;
		steps @=> this.steps;
		0 => cursor;
		0 => go;
		1 => buf.loop;
	}
	
	fun void play()
	{
		1 => go;
		buf => dac;
		while (go)
		{
			//skip to step
			steps[cursor] * buf.samples() / steps.size() => buf.pos;
			//wait the proper amount of time
			if (cursor % 2 == 0) {
				//long shuffle
				buf.length() / steps.size() * (1 + shuffle) => now;
			} else {
				//short shuffle
				buf.length() / steps.size() * (1 - shuffle) => now;
			}
			(cursor + 1) % steps.size() => cursor;
		}
	}
	
	fun void stop()
	{
		0 => go;
		buf !=> dac;
	}
}

Kali k;
//[0,3,1,2,4,7,5,6] @=> int s[];
//[0,1,7,2,3,7,0,6] @=> int s[];
[0,1,3,2,4,5,6,7] @=> int s[];

k.load(me.arg(0),s);
Std.atof(me.arg(1)) => k.shuffle;
k.play();
