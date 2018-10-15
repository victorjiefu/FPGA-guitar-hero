`timescale 1ns / 1ps
/* This module is based on vga_demo.v, but was modified for my asteroid game*/
/* source 2: vga_demo.v on blackboard */
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
// Author:  Da Cheng
//////////////////////////////////////////////////////////////////////////////////
module guitar_hero(ClkPort, vga_h_sync, vga_v_sync, vga_r0, vga_r1, vga_r2, vga_g0, vga_g1, vga_g2, vga_b0, vga_b1,
	Sw7,Sw6,Sw5,Sw4,Sw3,Sw2,Sw1,Sw0,
	btnU, btnD, btnC, btnL, btnR,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7,
	MISO,SS,MOSI,SCLK,AN,SEG,
	Speaker
	
	);
	
	
	input ClkPort, btnU, btnD, btnC, btnL, btnR;
	input Sw7,Sw6,Sw5,Sw4,Sw3,Sw2,Sw1,Sw0;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r0, vga_r1, vga_r2, vga_g0, vga_g1, vga_g2, vga_b0, vga_b1;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	output Speaker;
	reg  vga_r0, vga_r1, vga_r2, vga_g0, vga_g1, vga_g2, vga_b0, vga_b1;
	reg Speaker;
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, ClkPort, board_clk, clk, button_clk;
	BUF BUF1 (board_clk, ClkPort); 
	BUF BUF2 (reset, btnU);
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;
	wire [9:0] joy_x,joy_y;  
	
	///////////////Guitar Hero//////////////////////

	//////////////////////////////////////////
	
	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	reg [7:0] RGB;
	
	wire [7:0] SW_C;
	assign SW_C = {Sw7,Sw6,Sw5,Sw4,Sw3,Sw2,Sw1,Sw0};

	///////////////////////////////////////////////////////////////////
	///////////////			Produce Random Number /////////////////////
	///////////////////////////////////////////////////////////////////
	wire rand_bit;
	reg [3:0] rand;
	////LFSR, source:http://outputlogic.com//////
	lfsr_counter random_generator1(.clk(clk), .reset(), .d0(rand_bit));
	reg [2:0] i_rand;
	always @ (posedge clk)
		begin
			rand [i_rand] = rand_bit;
			i_rand <= i_rand + 1;
			if (i_rand == 3) i_rand <= 0;
		end
	//////////////////End Random Number////////////////////////////
	
	///// Declare Notes//////
	reg [2:0] notes [11:0]; // stores each of the 12 active rows notes
	reg [3:0] currentrow; // stores what the current note row is (0-11)
	reg [3:0] hitrow; // stores what the hit row is (0-11)
	reg [3:0] lastrow; // stores the last row (0-11)
	reg [2:0] notedata; // stores the randomized algorithized note value
	reg [9:0] position [11:0]; // stores each of the 12 active rows positions
	reg [1:0] level;
	reg [5:0] nextnote; // counter to store when to create the next note
	reg [2:0] buttonLCR;
	reg strum; // if joystick is hit
	reg start;
	reg gameover;
	reg [2:0] lives;
	reg [9:0] score;
	reg [9:0] posData;
	reg [11:0] hitConfirm; // is high if the note was hit 
	reg [11:0] hitMiss; // is high if the note was wrong
	reg LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg soundOn;
	reg herotime;
	reg [9:0] hitposition;
	reg loopflag;
	reg [29:0] endcounter;
	integer temp1, temp2, temp3, temp4;
	
	// Colors
	reg [7:0] red;
	reg [7:0] green;
	reg [7:0] blue;
	reg [7:0] white;
	reg [7:0] black;
	reg [7:0] gold;
	reg [7:0] brown;
	
	// Sets values initially
	initial
		begin: setValues
			
			for (temp1 = 0; temp1 < 12; temp1 = temp1 + 1) begin
				notes[temp1] = 0;
				position[temp1] = 0;
				hitConfirm[temp1] = 0;
				hitMiss[temp1] = 0;
			end
			LD0 = 1; LD1 = 1; LD2 = 1; LD3 = 1; LD4 = 1; LD5 = 1; LD6 = 1; LD7 = 1;
			
			level[0] = Sw0;
			level[1] = Sw1;
			currentrow = 0;
			hitrow = 1;
			lastrow = 2;
			nextnote = 0;
			score = 0;
			posData = 0;
			start = 0;
			gameover = 0;
			lives = 3'b111;
			soundOn = 0;
			herotime = 0;
			Speaker = 0;
			loopflag = 0;
			hitposition = 0;
			endcounter = 0;
			
			red = 8'b11100000;
			green = 8'b00011100;
			blue = 8'b00000011;
			white = 8'b11111111;
			black = 8'b00000000;
			gold = 8'b11111100;
			brown = 8'b10111000;
			
			
	
		end
		
	// Moves the notes down the frets and loads the weighted randomized note data
	always @ (posedge DIV_CLK[19])
		begin: moveNotes
			
		
		if (gameover && !start) begin
		// Reset values
		
		for (temp4 = 0; temp4 < 12; temp4 = temp4 + 1) begin
				notes[temp4] = 0;
				position[temp4] = 0;
				hitConfirm[temp4] = 0;
				hitMiss[temp4] = 0;
			end
			
			currentrow = 0;
			hitrow = 1;
			lastrow = 2;
			nextnote = 0;
			score = 0;
			lives = 3'b111;
			LD0 = 0;
		
		end
		
		else if ((~gameover && herotime )|| (gameover && start)) begin: gameON
			
			// Turn off gameover
			gameover = 0;
			
			// Turn on LD0
			LD0 = 1;
		
			// increments the position of all notes
			for (temp2 = 0; temp2 < 12; temp2 = temp2 + 1) begin
				position[temp2] = position[temp2] + 1;
			end
			
			
			// increments the next note counter
			if (nextnote < 50)
				nextnote = nextnote + 1;
			else
				nextnote = 0;
				
			if (nextnote == 0) begin
				
				// resets note position to top
				position[currentrow] = 0;
				// sets randomized notedata based on the level
				notes[currentrow] = notedata;
				// resets hitConfirm & hitMiss of new row
				hitConfirm[currentrow] = 0;
				hitMiss[currentrow] = 0;
				// increments the current row
				if (currentrow < 11)
				currentrow = currentrow + 1;
				else
				currentrow = 0;
				if (hitrow < 11)
				hitrow = hitrow + 1;
				else
				hitrow = 0;
				if (lastrow < 11) begin
					if (hitrow == 0)
					lastrow = 11;
					else
					lastrow = hitrow - 1;
				end
				else
				lastrow = 0;
				
			end
			
			// Monitor the buttons and the joystick strums (buttonLCR, strum)
			if ((notes[hitrow] == buttonLCR) && (notes[hitrow] != 3'b000) && (strum) && !(hitConfirm[hitrow])) begin
			// correct note was hit
			hitConfirm[hitrow] = 1;
			score = score + 1;
			
			end
			
			if ((notes[hitrow] != buttonLCR) && (strum) && (notes[hitrow] != 3'b000) && !(hitMiss[hitrow]) && !(hitConfirm[hitrow])) begin
				// pushed wrong buttons for the note
				hitMiss[hitrow] = 1;
				if (lives != 0)
				lives = lives - 1;
				else
				gameover = 1;
			
			end
			
			// takes away a point if you missed a note
			if ((hitMiss[lastrow] == 0) && (hitConfirm[lastrow] == 0) && (notes[lastrow] != 3'b000)) begin
				hitMiss[lastrow] = 1;
				if (lives != 0)
				lives = lives - 1;
				else
				gameover = 1;
			
			
			end
			
			

		
		end
		
		end
		
	
	
	// Sets the notedata based on what level it is
	always @ (posedge clk)
		begin
		
		start = btnD;
		if (~herotime) herotime = btnD;
		
		if ((~gameover && herotime) || (gameover && start)) begin: gameON2
		
			// Set button values to array of reg
			buttonLCR[2] = btnL;
			buttonLCR[1] = btnC;
			buttonLCR[0] = btnR;
			
			// Set switch levels
			level[0] = Sw0;
			level[1] = Sw1;
			
			// Set score to posData
			posData = score;

			
			
				
				
			if ((position[hitrow] > 508) && (position[hitrow] < 513))	Speaker = DIV_CLK[18];
			
			// Creates sound based on notes			
			else if ((notes[hitrow] == buttonLCR) && (notes[hitrow] != 3'b000) && (strum)) begin

				// use variable to store position value for that exact hit
				if (~loopflag) hitposition = position[hitrow];
				
				// play hit sound for 20 positions
				if (hitposition + 20 > position[hitrow])	Speaker = DIV_CLK[16];
				else	Speaker = 0;
				//Speaker = DIV_CLK[16];
				// use flag in this clock domain to stop from looping
				if (~loopflag) loopflag = 1;
			end
			
			// Creates bad sound based on notes			
			else if ((notes[hitrow] != buttonLCR) && (notes[hitrow] != 3'b000) && (strum)) begin

				// use variable to store position value for that exact hit
				if (~loopflag) hitposition = position[hitrow];
				
				// play hit sound for 20 positions
				if (hitposition + 30 > position[hitrow])	Speaker = DIV_CLK[19];
				else	Speaker = 0;
				//Speaker = DIV_CLK[19];
				// use flag in this clock domain to stop from looping
				if (~loopflag) loopflag = 1;
			end
			
			// Creates bad sound if you strum when there are no notes			
			else if ((notes[hitrow] == 3'b000) && (strum)) begin
				
				Speaker = DIV_CLK[19];

			end
			
			else if (gameover && !start) begin

				// Lose sound
				if (endcounter < 50000000)	begin
					endcounter = endcounter + 1;
					Speaker = DIV_CLK[19];
					end
				else	begin
					Speaker = 0;
					endcounter = 0;
					end
			end
			
						
			else	Speaker = 0;
			
			
			if ((joy_x > 750) || (joy_y > 750) || (joy_x < 250) || (joy_y < 250))
			strum = 1;
			else
			strum = 0;
			
		
			case (level)
				
				0: 
				begin
					if (rand==0||rand==1||rand==2||rand==3)
						notedata<=3'b000;
					if (rand==4||rand==5||rand==6)
						notedata<=3'b001;
					if (rand==7||rand==8||rand==9)
						notedata<=3'b010;
					if (rand==10||rand==11|rand==12)
						notedata<=3'b100;
					if(rand==13)
						notedata<=3'b011;
					if (rand==14)
						notedata<=3'b101;
					if (rand==15)
						notedata<=3'b110;
				end
				
				1:
				begin
					if (rand==0||rand==1||rand==2)
						notedata<=3'b000;
					if (rand==3||rand==4)
						notedata<=3'b001;
					if (rand==5||rand==6)
						notedata<=3'b010;
					if (rand==7||rand==8)
						notedata<=3'b100;
					if(rand==9||rand==10)
						notedata<=3'b011;
					if (rand==11||rand==12)
						notedata<=3'b101;
					if (rand==13||rand==14)
						notedata<=3'b110;
					if (rand==15)
						notedata<=3'b111;
				end
				
				2:
				begin
					if (rand==0)
						notedata<=3'b000;
					if (rand==1)
						notedata<=3'b001;
					if (rand==2)
						notedata<=3'b010;
					if (rand==3)
						notedata<=3'b100;
					if(rand==4||rand==5||rand==6)
						notedata<=3'b011;
					if (rand==7||rand==8||rand==9)
						notedata<=3'b101;
					if (rand==10||rand==11||rand==12)
						notedata<=3'b110;
					if (rand==13||rand==14||rand==15)
						notedata<=3'b111;
				end
				
			endcase
			
			// Manage the LEDs and life counts
			if (lives > 0) LD1 = 1;
			else LD1 = 0;
			if (lives > 1) LD2 = 1;
			else LD2 = 0;
			if (lives > 2) LD3 = 1;
			else LD3 = 0;
			if (lives > 3) LD4 = 1;
			else LD4 = 0;
			if (lives > 4) LD5 = 1;
			else LD5 = 0;
			if (lives > 5) LD6 = 1;
			else LD6 = 0;
			if (lives > 6) LD7 = 1;
			else LD7 = 0;
			
			
		end
		
		end
	
	//////////////////// Draw all the things /////////////////////////
	always @ (posedge clk)
	begin: DrawBlock
	
	
	if (~herotime) begin
		// Guitar Hero screen
		RGB = 8'b00100111; // light blue
		
		if ((CounterY > 65) && (CounterY <= 415))
		begin: drawBlock4
			// Fretboard background
			RGB = brown; // light brown
		
			// Vertical Fret Bars
			if ((CounterY > 65) && (CounterY <= 70)) RGB = white;
			if ((CounterY > 180) && (CounterY <= 185)) RGB = white;
			if ((CounterY > 295) && (CounterY <= 300)) RGB = white;
			if ((CounterY > 410) && (CounterY <= 415)) RGB = white;
			
			
			// Horizantol Frets
			if ((CounterX > 512) && (CounterX <= 515))	RGB = gold;
			if ((CounterX > 565) && (CounterX <= 568))	RGB = gold;
			
			
			
			// Draw user instructions for button
			if ((CounterY > 205) && (CounterY <= 275) && (CounterX > 150) && (CounterX <= 230)) RGB = black; // up
			if ((CounterY > 205) && (CounterY <=275) && (CounterX > 250) && (CounterX <= 330)) RGB = black; // middle
			if ((CounterY > 205) && (CounterY <= 275) && (CounterX > 350) && (CounterX <= 430)) RGB = black; // down
			if ((CounterY > 320) && (CounterY <= 390) && (CounterX > 250) && (CounterX <= 330)) RGB = black; // right
			if ((CounterY > 90) && (CounterY <= 160) && (CounterX > 250) && (CounterX <= 330)) RGB = black; // left

			// Flashing green box under down button
			if (DIV_CLK[26]) begin
			
				if ((CounterY > 205) && (CounterY <= 275) && (CounterX > 350) && (CounterX <= 430)) RGB = green; // down
			
			end
		
		end
		
		// Assigning output color values based on RGB final of a given pixel
		vga_r0 = RGB[7] & inDisplayArea;
		vga_r1 = RGB[6] & inDisplayArea;
		vga_r2 = RGB[5] & inDisplayArea;
		vga_g0 = RGB[4] & inDisplayArea;
		vga_g1 = RGB[3] & inDisplayArea;
		vga_g2 = RGB[2] & inDisplayArea;
		vga_b0 = RGB[1] & inDisplayArea;
		vga_b1 = RGB[0] & inDisplayArea;

	
	end
	
	
	else if (gameover && !start && herotime) begin
		// Gameover screen
		// Guitar Hero screen
		RGB = red; // red
				
		if ((CounterY > 65) && (CounterY <= 415))
		begin: drawBlock3
			// Fretboard background
			RGB = brown; // light brown
		
			// Vertical Fret Bars
			if ((CounterY > 65) && (CounterY <= 70)) RGB = white;
			if ((CounterY > 180) && (CounterY <= 185)) RGB = white;
			if ((CounterY > 295) && (CounterY <= 300)) RGB = white;
			if ((CounterY > 410) && (CounterY <= 415)) RGB = white;
			
			
			// Horizantol Frets
			if ((CounterX > 512) && (CounterX <= 515))	RGB = gold;
			if ((CounterX > 565) && (CounterX <= 568))	RGB = gold;
		
		end
		
		// Assigning output color values based on RGB final of a given pixel
		vga_r0 = RGB[7] & inDisplayArea;
		vga_r1 = RGB[6] & inDisplayArea;
		vga_r2 = RGB[5] & inDisplayArea;
		vga_g0 = RGB[4] & inDisplayArea;
		vga_g1 = RGB[3] & inDisplayArea;
		vga_g2 = RGB[2] & inDisplayArea;
		vga_b0 = RGB[1] & inDisplayArea;
		vga_b1 = RGB[0] & inDisplayArea;
	
	end
	
	else if ((~gameover && herotime) || (gameover && start))
	begin: DrawBlock2
	
		//default background
		RGB = 8'b00100101; // light gray
		
		if ((CounterY > 65) && (CounterY <= 415))
		begin: drawBlock3
			// Fretboard background
			RGB = brown; // light brown
		
			// Vertical Fret Bars
			if ((CounterY > 65) && (CounterY <= 70)) RGB = white;
			if ((CounterY > 180) && (CounterY <= 185)) RGB = white;
			if ((CounterY > 295) && (CounterY <= 300)) RGB = white;
			if ((CounterY > 410) && (CounterY <= 415)) RGB = white;
			
			
			// Horizantol Frets
			if ((CounterX > 512) && (CounterX <= 515))	RGB = gold;
			if ((CounterX > 565) && (CounterX <= 568))	RGB = gold;
			
			// Draw an indention around each fret if button is pressed
			if ((CounterY > 70) && (CounterY <= 180) && (CounterX > 515) && (CounterX <= 565) && buttonLCR[0]) RGB = 8'b00000010; // dark blue
			//if () RGB = brown;
			
			if ((CounterY > 185) && (CounterY <= 295) && (CounterX > 515) && (CounterX <= 565) && buttonLCR[1]) RGB = 8'b11000000; // dark red
			//if () RGB = brown;
			
			if ((CounterY > 300) && (CounterY <= 410) && (CounterX > 515) && (CounterX <= 565) && buttonLCR[2]) RGB = 8'b00011000; // dark green
			//if () RGB = brown;

			
			// Draw each note row
			for (temp3 = 0; temp3 < 12; temp3 = temp3 + 1) begin
			
			if ((CounterY > 75) && (CounterY <= 175) && (CounterX > position[temp3]) && (CounterX <= position[temp3] + 40) && notes[temp3][0]) RGB = blue;
			if ((CounterY > 190) && (CounterY <= 290) && (CounterX > position[temp3]) && (CounterX <= position[temp3] + 40) && notes[temp3][1]) RGB = red;
			if ((CounterY > 305) && (CounterY <= 405) && (CounterX > position[temp3]) && (CounterX <= position[temp3] + 40) && notes[temp3][2]) RGB = green;
			
			end
			
			// Draws notes gold when hit correctly (plus 1 point)
			if ((CounterY > 75) && (CounterY <= 175) && (CounterX > position[hitrow]) && (CounterX <= position[hitrow] + 40) && notes[hitrow][0] && hitConfirm[hitrow]) RGB = gold;
			if ((CounterY > 190) && (CounterY <= 290) && (CounterX > position[hitrow]) && (CounterX <= position[hitrow] + 40) && notes[hitrow][1] && hitConfirm[hitrow]) RGB = gold;
			if ((CounterY > 305) && (CounterY <= 405) && (CounterX > position[hitrow]) && (CounterX <= position[hitrow] + 40) && notes[hitrow][2] && hitConfirm[hitrow]) RGB = gold;
			// Draws notes black when hit incorrectly (minus 1 point)
			if ((CounterY > 75) && (CounterY <= 175) && (CounterX > position[hitrow]) && (CounterX <= position[hitrow] + 40) && notes[hitrow][0] && hitMiss[hitrow]) RGB = black;
			if ((CounterY > 190) && (CounterY <= 290) && (CounterX > position[hitrow]) && (CounterX <= position[hitrow] + 40) && notes[hitrow][1] && hitMiss[hitrow]) RGB = black;
			if ((CounterY > 305) && (CounterY <= 405) && (CounterX > position[hitrow]) && (CounterX <= position[hitrow] + 40) && notes[hitrow][2] && hitMiss[hitrow]) RGB = black;
			// Maintains note colors when hit
				// if gold
			if ((CounterY > 75) && (CounterY <= 175) && (CounterX > position[lastrow]) && (CounterX <= position[lastrow] + 40) && notes[lastrow][0] && hitConfirm[lastrow]) RGB = gold;
			if ((CounterY > 190) && (CounterY <= 290) && (CounterX > position[lastrow]) && (CounterX <= position[lastrow] + 40) && notes[lastrow][1] && hitConfirm[lastrow]) RGB = gold;
			if ((CounterY > 305) && (CounterY <= 405) && (CounterX > position[lastrow]) && (CounterX <= position[lastrow] + 40) && notes[lastrow][2] && hitConfirm[lastrow]) RGB = gold;
				// if black
			if ((CounterY > 75) && (CounterY <= 175) && (CounterX > position[lastrow]) && (CounterX <= position[lastrow] + 40) && notes[lastrow][0] && hitMiss[lastrow]) RGB = black;
			if ((CounterY > 190) && (CounterY <= 290) && (CounterX > position[lastrow]) && (CounterX <= position[lastrow] + 40) && notes[lastrow][1] && hitMiss[lastrow]) RGB = black;
			if ((CounterY > 305) && (CounterY <= 405) && (CounterX > position[lastrow]) && (CounterX <= position[lastrow] + 40) && notes[lastrow][2] && hitMiss[lastrow]) RGB = black;
		
		end
		
		
		
		// Assigning output color values based on RGB final of a given pixel
		vga_r0 = RGB[7] & inDisplayArea;
		vga_r1 = RGB[6] & inDisplayArea;
		vga_r2 = RGB[5] & inDisplayArea;
		vga_g0 = RGB[4] & inDisplayArea;
		vga_g1 = RGB[3] & inDisplayArea;
		vga_g2 = RGB[2] & inDisplayArea;
		vga_b0 = RGB[1] & inDisplayArea;
		vga_b1 = RGB[0] & inDisplayArea;
	
	
	end
	
	end
	
	///Start Copied Code
	///Source:http://www.digilentinc.com/Products/Detail.cfm?NavPath=2,401,529&Prod=PMOD-JSTK
	
	/////////////////////////////////////////////////////////////////
	//////////////////    JOYSTICK     ///////////////////////////////
	
			input MISO;					// Master In Slave Out, Pin 3, Port JA
			output SS;					// Slave Select, Pin 1, Port JA
			output MOSI;				// Master Out Slave In, Pin 2, Port JA
			output SCLK;				// Serial Clock, Pin 4, Port JA
			output [3:0] AN;			// Anodes for Seven Segment Display
			output [6:0] SEG;			// Cathodes for Seven Segment Display
			
			wire SS;						// Active low
			wire MOSI;					// Data transfer from master to slave
			wire SCLK;					// Serial clock that controls communication
			wire [3:0] AN;				// Anodes for Seven Segment Display
			wire [6:0] SEG;			// Cathodes for Seven Segment Display
			// Holds data to be sent to PmodJSTK
			wire [7:0] sndData;
			// Signal to send/receive data to/from PmodJSTK
			wire sndRec;
			wire [39:0] jstkData;

			//-----------------------------------------------
			//  	  			PmodJSTK Interface
			//-----------------------------------------------
			PmodJSTK PmodJSTK_Int(
					.CLK(board_clk),
					.sndRec(sndRec),
					.DIN(sndData),
					.MISO(MISO),
					.SS(SS),
					.SCLK(SCLK),
					.MOSI(MOSI),
					.DOUT(jstkData)
			);
			//-----------------------------------------------
			//  			 Send Receive Generator
			//-----------------------------------------------
			ClkDiv_5Hz genSndRec(
					.CLK(board_clk),
					.CLKOUT(sndRec)
			);
			//-----------------------------------------------
			//  		Seven Segment Display Controller
			//-----------------------------------------------
			ssdCtrl DispCtrl(
					.CLK(board_clk),
					.DIN(posData),
					.AN(AN),
					.SEG(SEG)
			);
			// End Copied Code
			/////////////////////////
			
			
			assign joy_x = {jstkData[25:24], jstkData[39:32]};
			assign joy_y = {jstkData[9:8], jstkData[23:16]};
	
endmodule
