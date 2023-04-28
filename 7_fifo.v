module fifo	
#(								  	
parameter WIDTH = 8
)
(                               
input  wire        CLK,         
input  wire        RST,         							
input  wire              FI_STB,      
input  wire  [WIDTH-1:0] FI_DAT,      
output wire              FI_BSY,                           
output wire              FO_STB,      
input  wire              FO_ACK,      
output wire  [WIDTH-1:0] FO_DAT    
);                              
//---------------------------------------
reg   [WIDTH-1:0] ff_dat [0:15];
reg   [3:0] ff_sel;
wire		ff_in_busy;
reg         ff_out_stb;
//---------------------------------------
integer     ff_state;
//---------------------------------------
assign FI_BSY     = ff_in_busy;
//--------------------------------------
assign FO_STB     = ff_out_stb;

//--------------------------------------
assign ff_in_busy = (ff_state==4);
//--------------------------------------
always @(posedge CLK or posedge RST)
 if(RST) 
    begin
		ff_state     <= 0;
		ff_sel       <= 4'hF;
		ff_out_stb   <= 1'b0;
	end	
 else casex(ff_state)
//..............................
// clear state
//..............................
0:  begin
	 ff_sel      <=                  4'hF;
	 ff_out_stb  <=                  1'b0;
	 ff_state    <=                     1;
    end
//..............................
// empty
//..............................
1: if(FI_STB) 		  
	begin
	 ff_sel      <=         ff_sel + 1'b1;
	 ff_out_stb  <=                  1'b1;
	 ff_state    <=                     2;
    end
//..............................
// not empty but only one symbol in the buffer
//..............................
2: if(FI_STB && FO_ACK) 		  
	begin
	 ff_sel      <=                ff_sel;
	 ff_out_stb  <=                  1'b1;
	 ff_state    <=                     2;
    end
   else if(FI_STB)	
	begin
	 ff_sel      <=         ff_sel + 1'b1;
	 ff_out_stb  <=                  1'b1;
	 ff_state    <=                     3;
    end
   else if(FO_ACK)	
	begin
	 ff_sel      <=         ff_sel - 1'b1;
	 ff_out_stb  <=                  1'b0;
	 ff_state    <=                     1;
    end
//..............................
// not empty
//..............................
3: if(FI_STB && FO_ACK) 		  
	begin
	 ff_sel      <=                ff_sel;
	 ff_out_stb  <=                  1'b1;
	 ff_state    <=                     3;
    end
   else if(FI_STB)	
	begin
	 ff_sel      <=         ff_sel + 1'b1;
	 ff_out_stb  <=                  1'b1;
	 ff_state    <= (ff_sel>=14)? 4:3;
    end
   else if(FO_ACK)	
	begin
	 ff_sel      <=         ff_sel - 1'b1;
	 ff_out_stb  <=                  1'b1;
	 ff_state    <= (ff_sel<=1)?      2:3;
    end
//..............................
// full
//..............................
4: if(FI_STB && FO_ACK) 		  
	begin
	 ff_sel      <=                ff_sel;
	 ff_out_stb  <=                  1'b1;
	 ff_state    <=                     4;
    end
   else if(FO_ACK)	
	begin
	 ff_sel      <=         ff_sel - 1'b1;
	 ff_out_stb  <=                  1'b1;
	 ff_state    <= (ff_sel>=14)? 4:3;
    end
//..............................
default: ff_state <= 0;
//..............................
endcase
//----------------------------------------------------------------------------------------
always @(posedge CLK)
 if(FI_STB & ~ff_in_busy) begin 
	                   ff_dat[4'h0] <= FI_DAT;
	                   ff_dat[4'h1] <= ff_dat[4'h0];
	                   ff_dat[4'h2] <= ff_dat[4'h1];
	                   ff_dat[4'h3] <= ff_dat[4'h2];
	                   ff_dat[4'h4] <= ff_dat[4'h3];
	                   ff_dat[4'h5] <= ff_dat[4'h4];
	                   ff_dat[4'h6] <= ff_dat[4'h5];
	                   ff_dat[4'h7] <= ff_dat[4'h6];
	                   ff_dat[4'h8] <= ff_dat[4'h7];
	                   ff_dat[4'h9] <= ff_dat[4'h8];
	                   ff_dat[4'hA] <= ff_dat[4'h9];
	                   ff_dat[4'hB] <= ff_dat[4'hA];
	                   ff_dat[4'hC] <= ff_dat[4'hB];
	                   ff_dat[4'hD] <= ff_dat[4'hC];
	                   ff_dat[4'hE] <= ff_dat[4'hD];
	                   ff_dat[4'hF] <= ff_dat[4'hE];
                      end					   
		   
//----------------------------------------------------------------------------------------
assign                FO_DAT = ff_dat[ff_sel];
//----------------------------------------------------------------------------------------
endmodule
