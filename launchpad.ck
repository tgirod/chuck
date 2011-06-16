public class Launchpad
{
	// launchpad -> chuck
	MidiIn lp_in;
	MidiMsg msg_lp_in;
	
	// chuck -> launchpad
	MidiOut lp_out;
	MidiMsg msg_lp_out;

	//state

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
					control_event(col,press);
				} else {
					msg_lp_in.data2 / 16 $ int => row;
					msg_lp_in.data2 % 16 $ int => col;
					msg_lp_in.data3 != 0 => press;
					if (col < 8) {
						matrix_event(row,col,press);
					} else {
						scene_event(row,press);
					}
				}
			}
		}
	}

	fun void control_event(int col, int press)
	{
		<<< "control event", col, press >>>;
	}

	fun void matrix_event(int row, int col, int press)
	{
		<<< "matrix event", row, col, press >>>;
	}

	fun void scene_event(int row, int press)
	{
		<<< "scene event", row, press >>>;
	}
	
	fun void send3(int data1, int data2, int data3)
	{
		data1 => msg_lp_out.data1;
		data2 => msg_lp_out.data2;
		data3 => msg_lp_out.data3;
		lp_out.send(msg_lp_out);
	}

	fun void led_matrix(int row, int col, int color)
	{
		send3(0x90, row*16 + col, color);
	}
}
