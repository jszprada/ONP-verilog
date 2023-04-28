module tb(
    );
    reg clk, rst, zapis; 
    reg [3:0] wejscie;
       
    parameter addition  = 4'hA;         
    parameter subtraction  = 4'hB;       
    parameter multiplication  = 4'hC;          
    parameter equal  = 4'hD;           
    parameter left_bracket  = 4'hE;       
    parameter right_bracket  = 4'hF;      

    wire ready_fifo;     
    wire [3:0] ONP;  

	wire	rd_data_fifo; 
	wire signed [31:0] wynik;
    wire ready;


    initial clk  <= 0;
	always #10  clk <= ~clk;



initial begin
    rst <= 1;
    zapis <= 0;
    wejscie <= 4'h0;
    #100;
    rst <= 0;
    #100;
    
    
    wejscie <= 4'h7;    
    zapis <= 1;
    #20;
    zapis <= 0;
    #20;   
    wejscie <= 4'hB;     
    zapis <= 1;
    #20;
    zapis <= 0;
    #20;
    wejscie <= 4'h1;     
    zapis <= 1;
    #20;
    zapis <= 0;
    #20;     
    wejscie <= 4'hA;     
    zapis <= 1;
    #20;
    zapis <= 0;
    #100;  
    wejscie <= 4'h5;     
    zapis <= 1;
    #20;
    zapis <= 0;
    #100;
    wejscie <= 4'hD;     
    zapis <= 1;
    #20;
    zapis <= 0;
    #20;    
    while (ready != 1) begin
    #10;
    end
    #100;
    $stop;
end
 

M1_ONP M1
    (.clk(clk),
     .rst(rst),
     .in_data(wejscie),
     .wr_data(zapis),
     .rd_data_fifo(rd_data_fifo),
     .ready_fifo(ready_fifo),
     .o_data_fifo(ONP)
    );

M2_ALU M2
    (.clk(clk), 
     .rst(rst), 
     .i_data(ONP), 
     .i_data_ready(ready_fifo),
     .ack_data(rd_data_fifo), 
     .o_result(wynik),		
     .o_result_ready(ready) 
    );

endmodule