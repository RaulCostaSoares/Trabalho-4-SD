module FPU(
    input logic clk,
    input logic reset,

    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0] op,
    
    output logic [31:0] data_out,
    output logic [3:0] status_out,
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
        ARRED,
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
    assign mantA  = (expA == 7'd0) ? {1'b0, a[23:0]} : {1'b1, a[23:0]}; // 24 bits para a mantissa

    assign sinalB = b[31]; 
    assign expB   = b[30:24];                                   // 7 bits para o expoente
    assign mantB  = (expB == 7'd0) ? {1'b0, b[23:0]} : {1'b1, b[23:0]}; // 24 bits para a mantissa

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            current_state     <= MOD_EXPO;
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
                        if (a == 32'd0 && b == 32'd0) begin // se os dois forem zero, ja retorna zero
                            data_out <= 32'd0;
                            estado <= READY;
                        end else if (expA == 7'd0 && expB == 7'd0) begin // se ambos forem zero, retorna zero
                            data_out <= 32'd0;
                            estado <= READY;
                        end else begin
                            // Calcula a diferença dos expoentes
                            if (expA > expB) begin
                                exp_dif <= expA - expB;
                                mantB_shifted <= {mantB, 1'b0} >> exp_dif; // Desloca mantissa B para a direita
                                mantA_shifted <= {mantA, 1'b0}; // Mantissa A não é deslocada
                            end else if (expB > expA) begin
                                exp_dif <= expB - expA;
                                mantA_shifted <= {mantA, 1'b0} >> exp_dif; // Desloca mantissa A para a direita
                                mantB_shifted <= {mantB, 1'b0}; // Mantissa B não é deslocada
                            end else begin
                                exp_dif <= 7'b0; // Expoentes iguais, não há deslocamento necessário
                                mantA_shifted <= {mantA, 1'b0};
                                mantB_shifted <= {mantB, 1'b0};
                            end

                            estado <= ADD_SUB; // Próximo estado para realizar a operação de adição/subtração
                        end
                    end
        
                ADD_SUB:
                    begin

                    end
                
                ARRED:
                    begin

                    end
                READY:
                    begin

                    end
            endcase 
        end
    end
endmodule   