// this program defines a Launchpad class, in order to communicate with
// Novation's Launchpad controller. This class has three public event objects:
//
// - grid_event for press/release events on the main grid
// - automap_event for press/release events on the top row
// - scene_event for press/release events on the right column
//
// this class provides only the most basic stuff of the protocol - double
// buffer, flashing, batch update and duty cycle are not implemented yet.
//
//
// example:
//
// Launchpad lp;
// spork ~ lp.listen(1); // your midi port
//
// while (true) {
// 	lp.grid_event => now;
// 	<<< lp.grid_event.row, lp.grid_event.col >>>;
// }

fun int clip(int value, int min, int max)
{
	if (value < min) min => value;
	if (value > max) max => value;
	return value;
}

fun int check(int value, int min, int max)
{
	if (value < min) return 0;
	if (value > max) return 0;
	return 1;
}

fun int velocity(int red, int green, int copy, int clear)
{
	// red bits (0,1)
	clip(red,0,3) => red;
	
	// copy bit (2)
	(copy != 0) << 2 => copy;
	
	// clear bit (3)
	(clear != 0) << 3 => clear;
	
	// green bits (4,5)
	clip(green,0,3) => green;
	green << 4 => green;
	
	return red + copy + clear + green;
}

class GridEvent extends Event
{
	int row;
	int col;
	int press;

	fun void print()
	{
		<<< "grid:", row, col, press >>>;
	}
}

class AutomapEvent extends Event
{
	int key;
	int press;

	fun void print()
	{
		<<< "automap:", key, press >>>;
	}
}

class SceneEvent extends Event
{
	int key;
	int press;
	
	fun void print()
	{
		<<< "scene:", key, press >>>;
	}
}

public class Launchpad
{
	// launchpad -> chuck
	MidiIn midi_in;
	MidiMsg msg_in;
	GridEvent grid_event;
	AutomapEvent automap_event;
	SceneEvent scene_event;
	
	// chuck -> launchpad
	MidiOut midi_out;
	MidiMsg msg_out;
	
	fun void listen(int port)
	{
		// open the midi ports
		if (!midi_out.open(port)) {
			<<< "can't open midi out" >>>;
			me.exit();
		}
		if (!midi_in.open(port)) {
			<<< "can't open midi in" >>>;
			me.exit();
		}
		
		<<< "clearing" >>>;
		clear();
		
		<<< "ready" >>>;
		while (true) {
			midi_in => now;
			while (midi_in.recv(msg_in)) midiHandler();
		}
	}

	fun void clear()
	{
		for (0 => int i; i < 8; i++) {
			automap(i,0,0);
			scene(i,0,0);
		}

		for (0 => int i; i < 8; i++) {
			for (0 => int j; j < 8; j++) {
				grid(i,j,0,0);
			}
		}
	}
	
	fun void midiHandler()
	{
		// pressed or released ?
		msg_in.data3 != 0 => int pressed;
		
		if (msg_in.data1 != 0x90) {
			// automap button pressed or released

			// which key ?
			msg_in.data2 - 104 => automap_event.key;

			// pressed ?
			pressed => automap_event.press;
			
			// broadcast new event
			automap_event.broadcast();
		} else {
			// grid button pressed or released
			
			// coordinates ?
			msg_in.data2 / 16 $ int => int row; 
			msg_in.data2 % 16 => int col;

			if (col == 8) {
				//scene button pressed

				// which key ?
				row => scene_event.key;

				// pressed or released ?
				pressed => scene_event.press;
				
				// broadcast new event
				scene_event.broadcast();
			} else {
				// grid button pressed

				// coordinates
				row => grid_event.row;
				col => grid_event.col;

				// pressed or released ?
				pressed => grid_event.press;

				// broadcast new event
				grid_event.broadcast();
			}
		}
	}
	
	fun void grid(int row, int col,int red, int green)
	{
		// if the coordinates are invalid, we stop right there
		if (!check(row,0,7) || !check(col,0,7)) return;
		
		0x90 => msg_out.data1;
		row*16 + col => msg_out.data2;
		velocity(red,green,1,1) => msg_out.data3;
		midi_out.send(msg_out);
	}

	fun void scene(int key, int red, int green)
	{
		if (!check(key,0,7)) return;
		
		0x90 => msg_out.data1;
		key*16 + 8 => msg_out.data2;
		velocity(red,green,1,1) => msg_out.data3;
		midi_out.send(msg_out);
	}
	
	fun void automap(int key, int red, int green)
	{
		if (!check(key,0,7)) return;
		
		0xB0 => msg_out.data1;
		104 + key => msg_out.data2;
		velocity(red,green,1,1) => msg_out.data3;
		midi_out.send(msg_out);
	}
		
	fun void printMsgOut()
	{
		<<< msg_out.data1, msg_out.data2, msg_out.data3 >>>;
	}
	
	fun void printMsgIn()
	{
		<<< msg_in.data1, msg_in.data2, msg_in.data3 >>>;
	}

	// fun void allOn(int brightness)
	// {
	// 	clip(brightness,1,3) => brightness;
	// 	0xB0 => msg_out.data1;
	// 	0 => msg_out.data2;
	// 	124+brightness => msg_out.data3;
	// 	midi_out.send(msg_out);
	// }

	// fun void allOff()
	// {
	// 	0xB0 => msg_out.data1;
	// 	0 => msg_out.data2;
	// 	0 => msg_out.data3;
	// 	midi_out.send(msg_out);
	// }

	// fun void rapidLedUpdate(int data[])
	// {
	// 	if (data.size() != 80) return;
	// 	for (0 => int i; i<80; i+2=>i) {
	// 		0x92 => msg_out.data1;
	// 		data[i] => msg_out.data2;
	// 		data[i+1] => msg_out.data3;
	// 		printMsgOut();
	// 		midi_out.send(msg_out);
	// 	}
	// }

	// fun int[] buildLedUpdate(int red[], int green[])
	// {
	// 	int data[80];
	// 	red.size() => int max;
	// 	if (green.size() < max) green.size() => max;
		
	// 	for (0 => int i; i<max; i++) {
	// 		velocity(red[i],green[i],1,1) => data[i];
	// 	}
	// 	return data;
	// }
	
	// fun void dutyCycle(int numerator, int denominator)
	// {
	// 	if (numerator < 1) 1 => numerator;
	// 	if (numerator > 16) 16 => numerator;
	// 	if (denominator < 3) 3 => denominator;
	// 	if (denominator > 18) 18 => denominator;
	// }
}	
