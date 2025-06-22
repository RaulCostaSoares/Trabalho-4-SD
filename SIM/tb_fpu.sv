`timescale 1ns/1ps

module tb_fpu();

    // Parameters
    parameter CLK_PERIOD = 10;

    // Inputs
    logic clk;
    logic reset;
    logic [31:0] a;
    logic [31:0] b;
    logic [1:0] op;

    // Outputs
    logic [31:0] data_out;
    logic [3:0] status_out;

    // Instantiate the FPU module
    fpu uut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .op(op),
        .data_out(data_out),
        .status_out(status_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        a = 32'd0;
        b = 32'd0;
        op = 2'b00; // Addition

        #(CLK_PERIOD * 2) reset = 0; // Assert reset
        #(CLK_PERIOD * 2) reset = 1; // Deassert reset

        // Test cases from the second testbench
        // Test Case 1: A = 0, B = 0
        a = 32'b0; 
        b = 32'b0;
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 1: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        // Test Case 2: A = {1'b0, 6'd31, 25'd0}, B = {1'b0, 6'd31, 25'd0}
        a = {1'b0, 6'd31, 25'd0};
        b = {1'b0, 6'd31, 25'd0};
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 2: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        // Test Case 3: A = {1'b0, 6'd31, 25'd0}, B = {1'b1, 6'd31, 25'd0}
        a = {1'b0, 6'd31, 25'd0};
        b = {1'b1, 6'd31, 25'd0};
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 3: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        // Test Case 4: A = {1'b0, 6'd50, 25'd100}, B = {1'b0, 6'd10, 25'd100}
        a = {1'b0, 6'd50, 25'd100};
        b = {1'b0, 6'd10, 25'd100};
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 4: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        // Test Case 5: A = {1'b0, 6'd31, 25'd5000000}, B = {1'b0, 6'd31, 25'd1000000}
        a = {1'b0, 6'd31, 25'd5000000};
        b = {1'b0, 6'd31, 25'd1000000};
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 5: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        // Test Case 6: A = {1'b0, 6'd31, 25'b0111111111111111111111111}, B = {1'b0, 6'd31, 25'b0000000000000000000000001}
        a = {1'b0, 6'd31, 25'b0111111111111111111111111};
        b = {1'b0, 6'd31, 25'b0000000000000000000000001};
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 6: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        // Test Case 7: A = {1'b0, 6'd63, 25'b1111111111111111111111111}, B = {1'b0, 6'd63, 25'b1111111111111111111111111}
        a = {1'b0, 6'd63, 25'b1111111111111111111111111};
        b = {1'b0, 6'd63, 25'b1111111111111111111111111};
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 7: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        // Test Case 8: A = {1'b0, 6'd1, 25'd1}, B = {1'b1, 6'd1, 25'd0}
        a = {1'b0, 6'd1, 25'd1};
        b = {1'b1, 6'd1, 25'd0};
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 8: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        // Test Case 9: A = {1'b1, 6'd32, 25'd0}, B = {1'b1, 6'd32, 25'd0}
        a = {1'b1, 6'd32, 25'd0};
        b = {1'b1, 6'd32, 25'd0};
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 9: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        // Test Case 10: A = {1'b0, 6'd33, 25'd0}, B = {1'b1, 6'd32, 25'd0}
        a = {1'b0, 6'd33, 25'd0};
        b = {1'b1, 6'd32, 25'd0};
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 10: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        // Test Case 11: A = {1'b0, 6'd63, 25'b1111111111111111111111111}, B = {1'b1, 6'd63, 25'b1111111111111111111111111}
        a = {1'b0, 6'd63, 25'b1111111111111111111111111};
        b = {1'b1, 6'd63, 25'b1111111111111111111111111};
        op = 2'b00; // Addition
        #1000;
        $display("\nTest Case 11: A = %h, B = %h, Output = %h, Status = %b", a, b, data_out, status_out);

        $finish;
    end

endmodule