// 100 kHz clock
typedef enum logic[3:0] {
    S_DECODE,
    S_ALIGN,
    S_OPERATE,
    S_NORMALIZE,
    S_WRITEBACK
} fsm_state_t;

typedef enum logic[3:0] {
    ST_OVERFLOW,
    ST_UNDERFLOW,
    ST_EXACT,
    ST_INEXACT
} result_status_t;

module FPU (
    input logic clk_100k,
    input logic rst_n, // asynchronous reset
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,
    output logic [31:0] result,
    output result_status_t status
);

fsm_state_t current_state, next_state;
logic op_a_sign, op_b_sign, result_sign, carry_flag, is_larger, init_cycle, decode_done, align_done, compute_done, normalize_done, write_done;
logic [21:0] mantissa_a, mantissa_b, mantissa_temp, mantissa_result, mantissa_a_buf, mantissa_b_buf;
logic [9:0] exponent_a, exponent_b, exponent_temp, exponent_result, exponent_a_buf, exponent_b_buf;
logic [9:0] exp_diff;
logic [4:0] shift_count;

// State register
always_ff @(posedge clk_100k or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= S_DECODE;
    end else begin
        current_state <= next_state;
    end
end

// Next state logic
always_comb begin
    next_state = current_state;
    case (current_state)
        S_DECODE:    next_state = decode_done ? S_ALIGN : S_DECODE;
        S_ALIGN:     next_state = align_done ? S_OPERATE : S_ALIGN;
        S_OPERATE:   next_state = compute_done ? S_NORMALIZE : S_OPERATE;
        S_NORMALIZE: next_state = normalize_done ? S_WRITEBACK : S_NORMALIZE;
        S_WRITEBACK: next_state = write_done ? S_DECODE : S_WRITEBACK;
        default:     next_state = S_DECODE;
    endcase
end

// Operand comparison and temporary storage
always_comb begin
    is_larger = (operand_a[30:21] >= operand_b[30:21]) ? 1'b1 : 1'b0;
    mantissa_a_buf = is_larger ? {1'b1, operand_a[20:0]} : {1'b1, operand_b[20:0]};
    exponent_a_buf = is_larger ? (operand_a[30:21] - 10'd511) : (operand_b[30:21] - 10'd511);
    op_a_sign = is_larger ? operand_a[31] : operand_b[31];
    
    mantissa_b_buf = is_larger ? {1'b1, operand_b[20:0]} : {1'b1, operand_a[20:0]};
    exponent_b_buf = is_larger ? (operand_b[30:21] - 10'd511) : (operand_a[30:21] - 10'd511);
    op_b_sign = is_larger ? operand_b[31] : operand_a[31];
    
    exp_diff = exponent_a_buf - exponent_b_buf;
end

// Main processing logic
always_ff @(posedge clk_100k or negedge rst_n) begin
    if (!rst_n) begin
        result <= 32'd0;
        status <= ST_EXACT;
        mantissa_temp <= 22'd0;
        exponent_temp <= 10'd0;
        shift_count <= 5'd0;
        init_cycle <= 1'b1;
        decode_done <= 1'b0;
        align_done <= 1'b0;
        compute_done <= 1'b0;
        normalize_done <= 1'b0;
        write_done <= 1'b0;
    end else begin
        case (current_state)
            S_DECODE: begin
                if (init_cycle) begin
                    mantissa_a <= mantissa_a_buf;
                    exponent_a <= exponent_a_buf;
                    op_a_sign <= op_a_sign;
                    mantissa_b <= mantissa_b_buf;
                    exponent_b <= exponent_b_buf;
                    op_b_sign <= op_b_sign;
                    init_cycle <= 1'b0;
                    decode_done <= 1'b1;
                end else begin
                    init_cycle <= 1'b1;
                end
            end
            S_ALIGN: begin
                mantissa_b <= mantissa_b >> exp_diff;
                align_done <= 1'b1;
            end
            S_OPERATE: begin
                if (op_a_sign == op_b_sign) begin
                    {carry_flag, mantissa_temp} <= mantissa_a + mantissa_b;
                end else begin
                    mantissa_temp <= mantissa_a - mantissa_b;
                    carry_flag <= 1'b0;
                end
                exponent_temp <= exponent_a;
                
                if (carry_flag) begin
                    mantissa_temp <= mantissa_temp >> 1;
                    exponent_temp <= exponent_temp + 1;
                end
                shift_count <= 5'd0;
                compute_done <= 1'b1;
            end
            S_NORMALIZE: begin
                if (!mantissa_temp[21] && exponent_temp > 0 && shift_count < 21) begin
                    mantissa_temp <= mantissa_temp << 1;
                    exponent_temp <= exponent_temp - 1;
                    shift_count <= shift_count + 1;
                end else begin
                    normalize_done <= 1'b1;
                end
            end
            S_WRITEBACK: begin
                result <= {op_a_sign, (exponent_temp + 10'd511), mantissa_temp[20:0]};
                write_done <= 1'b1;
                
                if (exponent_temp == 10'd0)
                    status <= ST_UNDERFLOW;
                else if (exponent_temp == 10'd1023)
                    status <= ST_OVERFLOW;
                else if (|mantissa_temp[0])
                    status <= ST_INEXACT;
                else
                    status <= ST_EXACT;
            end
        endcase
    end
end

endmodule