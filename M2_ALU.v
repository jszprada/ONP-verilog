module M2_ALU(
    input  clk, rst,
    input wire [3:0] i_data,                // wejsciowe wartosci
    input wire i_data_ready,                // wskazanie o gotowosci
    output wire ack_data,                   // potwierdzenie 
    output signed[31:0] o_result,
    output o_result_ready
    );
    // operators
    parameter addition  = 4'hA;         // '+'
    parameter subtraction  = 4'hB;       // '-'
    parameter multiplication  = 4'hC;          // '*'
    parameter equal  = 4'hD;           // '='
    reg [3:0] actual_operator; 

	// stack management
    reg push_stb_stack ;
	reg pop_ack_stack;
    reg [31:0] push_data_stack;
    wire push_ack_stack;
    wire pop_stb_stack;
    wire [31:0] pop_data_stack;
    parameter sprawdzenie = 3'd0, push_stack = 3'd1, push_stack_ready = 3'd2, pop_stack = 3'd3, pop_stack_ready = 3'd4, calculate = 3'd5;
    reg [2:0] state ;
    reg [2:0] next_state ;
    
    parameter POP_RESULT = 2'd1, POP_DATA = 2'd2;
    reg [1:0] POP_TYPE;     
    reg [1:0] COUNTER ;
    
    reg wynik_gotowy; 
    
    reg signed [31:0] data_a, data_b;
    reg signed [31:0] wynik ;
    
    assign o_result = data_a;
    assign o_result_ready = wynik_gotowy;
    always@(posedge clk or posedge rst) begin
        if (rst)
            state <= sprawdzenie;
        else
            state <= next_state;
    end
    
    reg ack_fifo; 
    assign ack_data = ack_fifo;
    always@(posedge clk or posedge rst) begin
        if (rst) 
            ack_fifo <= 0;
        else if (state == sprawdzenie && i_data_ready)
            ack_fifo <= 1;
        else
            ack_fifo <= 0;
    end
    
    // Implementing machine
    always@* begin
        case (state)
            sprawdzenie : begin
                wynik_gotowy = 0;
                if (i_data_ready) begin
                    if (i_data < addition)                      // zapis liczb na stos
                        next_state = push_stack;
                    else if ( i_data < equal )begin            //  pojawienie sie operatora obliczeń
                        actual_operator = i_data;
                        next_state = pop_stack;
                        POP_TYPE = POP_DATA;
                    end
                    else if (i_data == equal) begin            // wejscie jest znakiem '='
                        POP_TYPE = POP_RESULT;
                        next_state = pop_stack;
                    end
                end
            end
            pop_stack :
                next_state = pop_stack_ready;
            pop_stack_ready :
                if (pop_stb_stack)begin                             
                    if (COUNTER == POP_TYPE) begin                  
                        if (POP_TYPE == POP_DATA)                  
                            next_state = calculate;
                        else begin                                
                            wynik_gotowy = 1;
                            next_state = sprawdzenie;
                        end
                    end
                    else
                        next_state = pop_stack;
                end
            push_stack :
                    next_state = push_stack_ready;
           
            push_stack_ready :
                if (push_ack_stack)
                    next_state = sprawdzenie;
           calculate :
                next_state = push_stack;
            default :
                next_state = sprawdzenie;
        endcase
    end

    // wprowadzenie na stos
    always@(posedge clk or posedge rst) begin
        if (rst)
            push_stb_stack <= 0;
        else if (state == push_stack)
            push_stb_stack <= 1;
        else
            push_stb_stack <= 0;
    end
    
    // zdjecie ze stosu
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            COUNTER <= 0;
            pop_ack_stack <= 0;
        end 
        else if (state == pop_stack || state == pop_stack_ready) begin
            if (state == pop_stack) begin
                COUNTER <= COUNTER + 1;
                pop_ack_stack <= 1;
            end
            else
                pop_ack_stack <= 0;
        end
        else begin
            COUNTER <= 0;
            pop_ack_stack <= 0;
        end
    end

    // przypisanie danych do obliczen
    always@( COUNTER or pop_data_stack or pop_ack_stack) begin
        if (COUNTER == 2'd1 && pop_ack_stack)
            data_a = pop_data_stack;
        else if (COUNTER == 2'd2 && pop_ack_stack) 
            data_b = pop_data_stack;
    end

    // wykonanie operacji, dodawanie, odejmowanie, mnozenie
    always@* begin
        case (actual_operator)
            addition:
                wynik = data_b + data_a;
            subtraction :
                wynik = data_b - data_a;
            multiplication :
                wynik = data_b * data_a;
            default :
                wynik = 0;
        endcase
    end

    // wejscie danych na stos
    always@(state, i_data, wynik) begin
        if ( state == sprawdzenie)           // wejsciowe dane
            push_data_stack = i_data;
        else if ( state == calculate)       // wynik obliczen
            push_data_stack = wynik;
     end






    stack stack_inst
        (
         .CLK(clk),
         .RST(rst),
         .PUSH_STB(push_stb_stack),
         .PUSH_DAT(push_data_stack),
         .PUSH_ACK(push_ack_stack),
         .POP_STB(pop_stb_stack),
         .POP_DAT(pop_data_stack),
         .POP_ACK(pop_ack_stack)
        );

endmodule