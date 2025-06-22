`timescale 1ns/1ps

module tb_fpu();

    // Parâmetros
    parameter CLK_PERIOD = 10;

    // Entradas
    logic clk;
    logic reset;
    logic [31:0] a;
    logic [31:0] b;
    logic [1:0] op;

    // Saídas
    logic [31:0] data_out;
    logic [3:0] status_out;

    // Instancia o módulo FPU
    fpu mod (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .op(op),
        .data_out(data_out),
        .status_out(status_out)
    );

    // Geração do clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Sequência de teste
    initial begin
        // Inicializa entradas
        reset = 1;
        a = 32'd0;
        b = 32'd0;
        op = 2'b00;

        #(CLK_PERIOD * 2) reset = 0;
        #(CLK_PERIOD * 2) reset = 1;

        // Casos de teste

        a = 32'b0; 
        b = 32'b0;
        #1000;
        $display("\nTeste 1: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        a = {1'b0, 7'd31, 24'd0};
        b = {1'b0, 7'd31, 24'd0};
        #1000;
        $display("\nTeste 2: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        a = {1'b0, 7'd31, 24'd0};
        b = {1'b1, 7'd31, 24'd0};
        #1000;
        $display("\nTeste 3: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        a = {1'b0, 7'd60, 24'd64};
        b = {1'b0, 7'd5, 24'd64};
        #1000;
        $display("\nTeste 4: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        a = {1'b0, 7'd45, 24'd9000000};
        b = {1'b0, 7'd45, 24'd3000000};
        #1000;
        $display("\nTeste 5: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        a = {1'b0, 7'd20, 24'h7FFFFF};
        b = {1'b0, 7'd20, 24'h000001};
        #1000;
        $display("\nTeste 6: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        a = {1'b0, 7'd127, 24'h7FFFFF};
        b = {1'b0, 7'd127, 24'h7FFFFF};
        #1000;
        $display("\nTeste 7: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        a = {1'b0, 7'd1, 24'd1};
        b = {1'b1, 7'd1, 24'd0};
        #1000;
        $display("\nTeste 8: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        a = {1'b1, 7'd40, 24'd12345};
        b = {1'b1, 7'd40, 24'd12345};
        #1000;
        $display("\nTeste 9: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        a = {1'b0, 7'd60, 24'd1000};
        b = {1'b1, 7'd59, 24'd1000};
        #1000;
        $display("\nTeste 10: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        a = {1'b0, 7'd100, 24'hFFFFFF};
        b = {1'b1, 7'd100, 24'hFFFFFF};
        #1000;
        $display("\nTeste 11: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        $finish;
    end

endmodule
