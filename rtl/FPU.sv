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
endmodule

 // 2+4+1+0+4+8+8+4+2 = 33
 // 8 -(2 => "-") (33 mod4) = 8 - 1 = 7
 // x = 7
 // y = 31 - x = 24

// Representação de ponto flutuante de 32 bits (IEEE 754):
// a[31] -> 1      (SINAL)
// a[30:24] -> 7   (EXPOENTE)
// a[23:0] -> 24   (MANTISSA)


typedef enum logic [2:0] {
    EXACT, // O resultado foi representado corretamente pela configuração de ponto flutuante e não foi utilizado arredondamento
    OVERFLOW,
    UNDERFLOW, 
    INEXACT // O resultado sofreu arredondamento
} state_t;

state_t state;
