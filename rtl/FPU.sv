module fpu(
    input logic clk,
    input logic reset,

    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0] op,
    
    output logic [31:0] data_out,
    output logic [3:0] status_out
    // output logic [3:0] flags_out
);    

 // 2+4+1+0+4+8+8+4+2 = 33
 // 8 -(2 => "-") (33 mod4) = 8 - 1 = 7
 // x = 7
 // y = 31 - x = 24

// Representação de ponto flutuante de 32 bits (IEEE 754):
// a[31] -> 1      (SINAL)
// a[30:24] -> 7   (EXPOENTE)
// a[23:0] -> 24   (MANTISSA)


// typedef enum logic [1:0] {   // Resutado do FPU
//     EXACT, // O resultado foi representado corretamente pela configuração de ponto flutuante e não foi utilizado arredondamento
//     OVERFLOW,
//     UNDERFLOW, 
//     INEXACT // O resultado sofreu arredondamento
// } state_t;

    typedef enum logic [1:0] {   // Resutado do FPU
        EXPO,
        ADD_SUB,
        CORRIGE,
        READY
    } state_t;
    state_t estado;

    logic sinalA, sinalB, sinal_result;
    logic bit_overflow, bit_inexact, bit_underflow;

    logic [6:0]   expA, expB, exp_result, exp_dif;              // expoente de 7 bits
    logic [24:0]  mant_result;                                  // 24 bits para a mantissa + 1 bit implicito = 25
    logic [25:0]  mantA, mantB, mantA_shifted, mantB_shifted;   // 25 bits para mantissa + 1 bit implicito = 26
    logic [26:0]  mant_result_temp;                             // 26 bits para mantissa + 1 bit de overflow = 27

    assign sinalA = a[31]; 
    assign expA   = a[30:24];                                   // 7 bits para o expoente
    assign mantA  = (expA == 7'b0) ? {1'b0, a[23:0]} : {1'b1, a[23:0]};

    assign sinalB = b[31]; 
    assign expB   = b[30:24];                                   // 7 bits para o expoente
    assign mantB  = (expB == 7'b0) ? {1'b0, b[23:0]} : {1'b1, b[23:0]};

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            estado     <= EXPO;
            bit_inexact       <= 1'b0;
            bit_overflow      <= 1'b0;
            bit_underflow     <= 1'b0;
            sinal_result      <= 1'b0;
            status_out        <= 4'b0;
            exp_dif           <= 7'b0;
            exp_result        <= 7'b0;
            mant_result       <= 25'b0;
            mantA_shifted     <= 26'b0;
            mantB_shifted     <= 26'b0;
            mant_result_temp  <= 27'b0;
            data_out          <= 32'b0;

        end else begin
            case (estado)
                EXPO:
                    begin
                        if (a == 32'd0 && b == 32'd0) begin // caso ambos 0, retorna zero
                            data_out <= 32'd0;
                            estado <= READY;
                            status_out   <= 4'b0001; // exact
                        end else begin

                            bit_overflow  <= 1'b0;
                            bit_inexact   <= 1'b0;
                            bit_underflow <= 1'b0;

                        if (expA > expB) begin
                            exp_dif <= expA - expB; // diferenca entre os expoentes
                            if (exp_dif > 7'd26) begin // caso expoente for maior q a mantissa
                                mantB_shifted <= 26'd0;
                                if (mantB != 0) bit_inexact <= 1'b1; //
                            end else begin
                                mantB_shifted <= mantB >> exp_dif;
                                mantA_shifted <= mantA;
                                exp_result    <= expA;
                                for (int i = 0; i < exp_dif; i++) begin
                                    if (mantB[i]) bit_inexact <= 1'b1;
                                end
                            end
                        end else if (expB > expA) begin
                            exp_dif <= expB - expA;
                            if (exp_dif > 7'd26) begin
                                mantA_shifted <= 26'd0;
                                if (mantA != 0) bit_inexact <= 1'b1;
                            end else begin
                                mantA_shifted <= mantA;
                                mantB_shifted <= mantB >> exp_dif;
                                exp_result    <= expB;
                                for (int i = 0; i < exp_dif; i++) begin
                                    if (mantA[i]) bit_inexact <= 1'b1;
                                end
                            end
                        end else begin
                            mantA_shifted <= mantA;
                            mantB_shifted <= mantB;
                            exp_result    <= expA;
                        end

                            estado <= ADD_SUB; // estado de adicao/subtracao
                        end
                    end
        
                ADD_SUB:
                    begin
                        if (sinalA == sinalB) begin                         // soma
                        mant_result_temp <= mantA_shifted + mantB_shifted;
                        sinal_result      <= sinalA;
                        end 
                        else begin                                          // subtracao
                        if (mantA_shifted >= mantB_shifted) begin           // A maior ou igual a B
                            mant_result_temp <= mantA_shifted - mantB_shifted;
                            sinal_result      <= sinalA;
                        end else begin                                      // B maior que A
                            mant_result_temp <= mantB_shifted - mantA_shifted;
                            sinal_result      <= sinalB;
                        end
                    end
                    estado <= CORRIGE;
                    end
                
                CORRIGE:
                    begin
                        if (mant_result_temp == 27'd0) begin // se o resultado for zero
                            mant_result <= 25'd0;
                            exp_result  <= 7'd0;
                            estado <= READY;
                        end else if (exp_result >= 7'd127) begin // se expoente for maior/igual que 127
                            bit_overflow     <= 1'b1;
                            mant_result_temp <= 27'd0;
                            estado    <= READY;
                        end else if (mant_result_temp[26]) begin
                            mant_result_temp <= mant_result_temp >> 1;
                            exp_result       <= exp_result + 1;
                        end else if (mant_result_temp[25] == 1'b0) begin
                            if (exp_result == 7'd0) begin
                                mant_result_temp <= 27'd0;
                                bit_underflow    <= 1'b1; 
                                estado    <= READY;
                            end else begin
                                mant_result_temp <= mant_result_temp << 1;
                                exp_result       <= exp_result - 1;
                            end
                        end else begin
                            mant_result <= mant_result_temp[24:0];
                            if (mant_result_temp[0]) begin
                                bit_inexact <= 1'b1;
                                mant_result <= mant_result + 1;

                                if (mant_result + 1 == 25'b1000000000000000000000000) begin
                                    mant_result <= (mant_result + 1) >> 1;

                                    if (exp_result == 7'd127) begin
                                        bit_overflow <= 1'b1; 
                                    end else begin
                                        exp_result <= exp_result + 1;
                                    end
                                end
                            end

                            estado <= READY;
                        end
                    end
                READY:
                    begin
                    if (bit_overflow) begin
                        data_out   <= 32'd0;
                        status_out <= 4'b0100;
                    end else if (bit_underflow) begin
                        data_out   <= 32'd0;
                        status_out <= 4'b1000;
                    end else begin 
                        data_out   <= {sinal_result, exp_result, mant_result};
                        if (bit_inexact)
                            status_out <= 4'b0010;
                        else
                            status_out <= 4'b0001;
                    end
                    estado <= EXPO;
                end
            endcase 
        end
    end
endmodule   