module stack
(
	input	wire				CLK,
	input	wire				RST,
	input	wire				PUSH_STB,
	input	wire [31:0]	PUSH_DAT,
	output	wire				PUSH_ACK,
	output	wire				POP_STB,
	output	wire [31:0]	POP_DAT,
	input	wire				POP_ACK
);
//-------------------------------------------------------------------------------
reg	[4:0] push_ptr;
//-------------------------------------------------------------------------------
reg [31:0]	RAM[0:15];
wire full	= push_ptr[4];

always@(posedge CLK or posedge RST)
	if(RST)
	begin
	push_ptr <= 4'h0;
	end
  else if(PUSH_STB & ~full) 
	begin
	push_ptr <= push_ptr + 4'd1;
	RAM[push_ptr] <= PUSH_DAT;
	end
  else if(POP_STB)
	begin
	push_ptr <= push_ptr - 4'd1;
	end
assign POP_STB		=	POP_ACK;
assign	POP_DAT		=	RAM[push_ptr-1];
assign	PUSH_ACK	=	PUSH_STB & ~full;

endmodule