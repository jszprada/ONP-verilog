module M1_ONP(
    input clk, rst,
    input [3:0] in_data,             
    input wr_data,                  
    input rd_data_fifo,             
    output wire ready_fifo,
    output wire [3:0] o_data_fifo
    );
    
    // operators
    parameter addition  = 4'hA;         // '+'
    parameter subtraction  = 4'hB;       // '-'
    parameter multiplication  = 4'hC;          // '*'
    parameter equal  = 4'hD;           // '='
    parameter left_bracket  = 4'hE;       // '('
    parameter right_bracket  = 4'hF;      // ')'
    
    // algorithm states
    parameter idle = 3'd0, out_queue = 3'd1, stack_queue = 3'd2, push_stack = 3'd3, pop_stack = 3'd4; 
    reg [3:0] counter;                    
    reg [2:0] state;  
    reg [2:0] next_state;

    // stos
	reg [3:0] dane;
    reg [3:0] stos [0:15];
    reg wr_fifo;
    reg [3:0] dane_fifo;
    wire we_fifo_ready;
    reg we_fifo_rd;
    wire [3:0] we_fifo_data;
    
    reg brackets;    
    // dzialania miedzy nawiasami
    always@(posedge clk or posedge rst) begin
        if (rst)
            brackets = 0;
        else if (we_fifo_rd && dane == right_bracket)   // pojawienie sie prawego nawiasu
            brackets = 1;
        else if (state == pop_stack)
                if (stos[counter-1] == left_bracket)   // pojawienie sie lewego nawiasu
                    brackets = 0;                    // zablokowanie zdejmowania danych ze stosu
     end
    wire pop_stack_operator = (brackets) || ( 
                                (counter > 0) && ( stos[counter-1] !=left_bracket) && (stos[counter-1][3:1] >= dane[3:1] &&  (dane >= addition || dane <= multiplication) ||  
                                (dane == equal)));

    always@(posedge clk or posedge rst) begin
        if (rst)
            state <= idle;
        else
            state <= next_state;
    end
         
    // zliczanie elementow stosu
    always@(posedge clk or posedge rst) begin
        if (rst)
            counter <= 4'd0;
        else
            if (state == push_stack)
                counter <= counter + 1;
            else if(state == pop_stack)
                counter <= counter - 1;
    end
    
    integer k;   
    // stack management
    always@(posedge clk or posedge rst) begin
        if (rst)
            for(k = 0; k < 32 ; k = k+1)
                stos[k] <= 0;
        else if (state == push_stack) 
            stos[counter] <= dane;
    end
    //algorithm operation

    always@* begin
        case (state)
            idle : 
                if (we_fifo_rd)
                    if (dane < 4'hA)
                        next_state = out_queue;                 
                    else
                        next_state = stack_queue;               
                else
                    next_state = idle;
                    
            out_queue :
                next_state = idle;
                
            stack_queue :
                if (pop_stack_operator) 
                    next_state = pop_stack;
                else
                    if (dane == equal)
                        next_state = out_queue;
                    else
                        next_state = push_stack;
                                    
            push_stack :
                next_state = idle;
            pop_stack :
                if (stos[counter-1] == left_bracket)
                    next_state = idle;
                else
                    next_state = stack_queue;

            default : next_state = idle;
        endcase
    end
	
    // dane do kolejki wyjsciowej 
    always @(posedge clk or posedge rst) begin
        if (rst)
            wr_fifo <= 0;
        else if (state==out_queue) begin
            dane_fifo <= dane;
            wr_fifo <= 1;
        end
        else if (state==pop_stack) begin
            if (stos[counter-1] != left_bracket) begin
                dane_fifo <= stos[counter-1];
                wr_fifo <= 1;
            end
        end
        else
            wr_fifo <= 0;
    end

    // dane z kolejki wejsciowej
    always@(posedge clk or posedge rst) begin
        if (rst) 
            we_fifo_rd <= 0;
        else if (state == idle && next_state == idle && we_fifo_ready) begin
            we_fifo_rd <= 1;
            dane <= we_fifo_data;
        end
        else
            we_fifo_rd <= 0;
    end
            
fifo 
    #(								  
     .WIDTH(4)
    ) 
    FIFO_WE (
     .CLK(clk),
     .RST(rst),
     .FI_STB(wr_data),
     .FI_DAT(in_data),
     .FI_BSY(),
     .FO_STB(we_fifo_ready),
     .FO_ACK(we_fifo_rd),
     .FO_DAT(we_fifo_data)
    );


    
    
fifo 
    #(								  
     .WIDTH(4)
    ) 
    FIFO_WY (
     .CLK(clk),
     .RST(rst),
     .FI_STB(wr_fifo),
     .FI_DAT(dane_fifo),
     .FI_BSY(),
     .FO_STB(ready_fifo),
     .FO_ACK(rd_data_fifo),
     .FO_DAT(o_data_fifo)
    );

endmodule