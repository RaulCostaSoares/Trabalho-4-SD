module FPU #(
    parameter WIDTH = 32
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic [1:0]        op,       // 00: soma, 01: subtração, 10: multiplicação, 11: divisão
    input  logic [WIDTH-1:0]  a,
    input  logic [WIDTH-1:0]  b,
    output logic [WIDTH-1:0]  result,
    output logic              valid
);

    logic [WIDTH-1:0] add_res, sub_res, mul_res, div_res;

    // Soma em ponto flutuante
    assign add_res = a + b;
    // Subtração em ponto flutuante
    assign sub_res = a - b;
    // Multiplicação em ponto flutuante
    assign mul_res = a * b;
    // Divisão em ponto flutuante (simples, não compatível com IEEE)
    assign div_res = (b != 0) ? a / b : '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= '0;
            valid  <= 1'b0;
        end else begin
            case (op)
                2'b00: result <= add_res;
                2'b01: result <= sub_res;
                2'b10: result <= mul_res;
                2'b11: result <= div_res;
                default: result <= '0;
            endcase
            valid <= 1'b1;
        end
    end

endmodule