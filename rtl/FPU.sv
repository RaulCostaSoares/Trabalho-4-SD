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


parameter EXP_WIDTH = 7;
parameter MANT_WIDTH = 24;
parameter BIAS = (1 << (EXP_WIDTH - 1)) - 1;

logic a_sign, b_sign;
logic [EXP_WIDTH-1:0] a_exp, b_exp;
logic [MANT_WIDTH-1:0] a_mant, b_mant;

assign a_sign = a[31];
assign a_exp = a[30:31-EXP_WIDTH];
assign a_mant = a[31-EXP_WIDTH-1:0];

assign b_sign = b[31];
assign b_exp = b[30:31-EXP_WIDTH];
assign b_mant = b[31-EXP_WIDTH-1:0];

logic res_sign;
logic [EXP_WIDTH-1:0] res_exp;
logic [MANT_WIDTH-1:0] res_mant;

localparam EXT_MANT_WIDTH = MANT_WIDTH + 3;
logic [EXT_MANT_WIDTH-1:0] a_ext_mant, b_ext_mant;

logic [EXT_MANT_WIDTH-1:0] aligned_a_mant, aligned_b_mant;
logic [EXP_WIDTH:0] exp_diff;

logic [EXT_MANT_WIDTH:0] sum_mant;

logic exato_flag, overflow_flag, underflow_flag, inexato_flag;

always_comb begin
data_out = 32'b0;
status_out = 4'b0000;

exato_flag = 1'b0;
overflow_flag = 1'b0;
underflow_flag = 1'b0;
inexato_flag = 1'b0;

a_ext_mant = {1'b1, a_mant, 2'b00};
b_ext_mant = {1'b1, b_mant, 2'b00};

if (a_exp > b_exp) begin
exp_diff = a_exp - b_exp;
aligned_a_mant = a_ext_mant;
if (exp_diff < EXT_MANT_WIDTH) begin
aligned_b_mant = b_ext_mant >> exp_diff;
end else begin
aligned_b_mant = 0;
end
res_exp = a_exp;
end else if (b_exp > a_exp) begin
exp_diff = b_exp - a_exp;
aligned_b_mant = b_ext_mant;
if (exp_diff < EXT_MANT_WIDTH) begin
aligned_a_mant = a_ext_mant >> exp_diff;
end else begin
aligned_a_mant = 0;
end
res_exp = b_exp;
end else begin
exp_diff = 0;
aligned_a_mant = a_ext_mant;
aligned_b_mant = b_ext_mant;
res_exp = a_exp;
end

if (op == 2'b00) begin
if (a_sign == b_sign) begin
res_sign = a_sign;
sum_mant = aligned_a_mant + aligned_b_mant;
end else begin
if (aligned_a_mant >= aligned_b_mant) begin
res_sign = a_sign;
sum_mant = aligned_a_mant - aligned_b_mant;
end else begin
res_sign = b_sign;
sum_mant = aligned_b_mant - aligned_a_mant;
end
end
end else if (op == 2'b01) begin
if (a_sign != b_sign) begin
res_sign = a_sign;
sum_mant = aligned_a_mant + aligned_b_mant;
end else begin
if (aligned_a_mant >= aligned_b_mant) begin
res_sign = a_sign;
sum_mant = aligned_a_mant - aligned_b_mant;
end else begin
res_sign = ~b_sign;
sum_mant = aligned_b_mant - aligned_a_mant;
end
end
end

logic [EXP_WIDTH-1:0] norm_shift = 0;
logic [EXT_MANT_WIDTH:0] temp_mant = sum_mant;

if (sum_mant == 0) begin
res_exp = 0;
res_mant = 0;
exato_flag = 1'b1;
end else begin
if (temp_mant[EXT_MANT_WIDTH] == 1'b1) begin
temp_mant = temp_mant >> 1;
res_exp = res_exp + 1;
end

for (int i = EXT_MANT_WIDTH - 1; i >= 0; i--) begin
if (temp_mant[i] == 1'b1) begin
norm_shift = (EXT_MANT_WIDTH - 1) - i;
temp_mant = temp_mant << norm_shift;
break;
end
end
res_exp = res_exp - norm_shift;

logic guarda_bit = temp_mant[MANT_WIDTH-1];
logic arredonda_bit = temp_mant[MANT_WIDTH-2];
logic sticky_bit = |temp_mant[MANT_WIDTH-3:0];

res_mant = temp_mant[EXT_MANT_WIDTH-1:EXT_MANT_WIDTH-MANT_WIDTH];

if (guarda_bit == 1'b1 && (arredonda_bit == 1'b1 || sticky_bit == 1'b1 || res_mant[0] == 1'b1)) begin
res_mant = res_mant + 1;
inexato_flag = 1'b1;
end

if (res_mant[MANT_WIDTH] == 1'b1) begin
res_mant = res_mant >> 1;
res_exp = res_exp + 1;
end
end

localparam MAX_EXP = (1 << EXP_WIDTH) - 1;
localparam MIN_EXP = 0;

if (res_exp > MAX_EXP) begin
overflow_flag = 1'b1;
res_exp = MAX_EXP;
res_mant = 0;
end else if (res_exp < MIN_EXP) begin
underflow_flag = 1'b1;
res_exp = MIN_EXP;
res_mant = 0;
end

if (!inexato_flag && !overflow_flag && !underflow_flag && sum_mant != 0) begin
exato_flag = 1'b1;
end

data_out = {res_sign, res_exp, res_mant};

if (exato_flag) status_out[0] = 1'b1;
if (overflow_flag) status_out[1] = 1'b1;
if (underflow_flag) status_out[2] = 1'b1;
if (inexato_flag) status_out[3] = 1'b1;
end
endmodule
