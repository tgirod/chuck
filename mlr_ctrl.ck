me.arg(0) => string cmd;

if (cmd == "load") {
	Std.atoi(me.arg(3)) => int row;
	me.arg(1) => string fname;
	Std.atoi(me.arg(2)) => int length;
	Std.atoi(me.arg(4)) => int group;
	Std.atof(me.arg(5)) => float gain;
	Mlr.load(row,fname,length,group,gain);
}

if (cmd == "bpm") {
	Std.atof(me.arg(1)) => float bpm;
	Mlr.setBpm(bpm);
}

if (cmd == "gain") {
	Std.atoi(me.arg(1)) => int row;
	Std.atof(me.arg(2)) => float gain;
	Mlr.setGain(row,gain);
}

if (cmd == "group") {
	Std.atoi(me.arg(1)) => int row;
	Std.atoi(me.arg(2)) => int group;
	Mlr.setGroup(row,group);
}
