public class Launchpad
{
	// launchpad -> chuck
	MidiIn lp_in;
	MidiMsg msg_lp_in;
	
	// chuck -> launchpad
	MidiOut lp_out;
	MidiMsg msg_lp_out;

	//keys state
	int key_state[9][9];
	
	//leds state
	int led_state[9][9];
	
	fun void connect(int lp_id)
	{
		// open the midi ports
		if (!lp_out.open(lp_id)) {
			<<< "can't open midi out" >>>;
			me.exit();
		}
		
		if (!lp_in.open(lp_id)) {
			<<< "can't open midi in" >>>;
			me.exit();
		}
		
		<<< "connected to the launchpad" >>>;
	}
	
	fun void listen()
	{
		int row; // row
		int col; // col
		int press; // press
		
		while (true)
		{
			lp_in => now;
			while (lp_in.recv(msg_lp_in))
			{
				if (msg_lp_in.data1 == 176)
				{
					msg_lp_in.data2 - 104 => col;
					msg_lp_in.data3 != 0 => press;
					press => key_state[8][col];
					keyEvent(-1,col,press);
				} else {
					msg_lp_in.data2 / 16 $ int => row;
					msg_lp_in.data2 % 16 $ int => col;
					msg_lp_in.data3 != 0 => press;
					press => key_state[row][col];
					keyEvent(row,col,press);
				}
			}
		}
	}

	fun void keyEvent(int row, int col, int press)
	{
		<<< "key event", row, col, press >>>;
	}
	
	fun void send3(int data1, int data2, int data3)
	{
		data1 => msg_lp_out.data1;
		data2 => msg_lp_out.data2;
		data3 => msg_lp_out.data3;
		lp_out.send(msg_lp_out);
	}

	fun void setColor(int row, int col, int color)
	{
		if (row == -1) {
			color => led_state[8][col];
			send3(0xB0, 104+col, color);
		} else {
			color => led_state[row][col];
			send3(0x90, row*16 + col, color);
		}
	}
	
	fun void setColor(int row, int col, int red, int green)
	{
		red + (green * 0x10) + 0x0c => int color;
		setColor(row, col, color);
	}
	
	fun int getColor(int row, int col)
	{
		if (row == -1) {
			return led_state[8][col];
		} else {
			return led_state[row][col];
		}
	}
	
	fun int isPressed(int row, int col)
	{
		if (row == -1) {
			return key_state[8][col];
		} else {
			return key_state[row][col];
		}
	}
}
