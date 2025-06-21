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


// typedef enum logic [2:0] {   // Resutado do FPU
//     EXACT, // O resultado foi representado corretamente pela configuração de ponto flutuante e não foi utilizado arredondamento
//     OVERFLOW,
//     UNDERFLOW, 
//     INEXACT // O resultado sofreu arredondamento
// } state_t;

    typedef enum logic [2:0] {   // Resutado do FPU
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
        end else begin
            case (estado)
                EXPO:
                    begin

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