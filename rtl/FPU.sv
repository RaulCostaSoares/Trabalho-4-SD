module fpu(
    input logic clk,
    input logic reset,

    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0] op,
    
    output logic [31:0] data_out,
    output logic [3:0] status_out
);

 // 2+4+1+0+4+8+8+4+2 = 33
 // 8 -(2 => "-") (33 mod4) = 8 - 1 = 7
 // x = 7
 // y = 31 - x = 24

// Representação de ponto flutuante de 32 bits (IEEE 754):
// a[31] -> 1      (SINAL)
// a[30:24] -> 7   (EXPOENTE)
// a[23:0] -> 24   (MANTISSA)

// EXACT // O resultado foi representado corretamente pela configuração de ponto flutuante e não foi utilizado arredondamento
// OVERFLOW
// UNDERFLOW 
// INEXACT // O resultado sofreu arredondamento


    typedef enum logic [1:0] {
        EXPO,       // Ajuste dos expoentes
        ADD_SUB,    // Soma ou subtração da mantissa
        CORRIGE,    // Normalização e arredondamento
        READY       // Resultado pronto
    } state_t;

    state_t estado;

    logic sinalA, sinalB, sinal_result;
    logic bit_overflow, bit_inexact, bit_underflow;

    logic [6:0] expA, expB, exp_result, exp_dif;                // expoente de 7 bits
    logic [24:0] mant_result;                                   // mantissa 25 bits (24 + 1 implícito)
    logic [25:0] mantA, mantB, mantA_shifted, mantB_shifted;    // mantissas 26 bits para alinhamento
    logic [26:0] mant_result_temp;                              // mantissa 27 bits para cálculo com overflow

    // Separando os campos com os tamanhos corretos
    assign sinalA = a[31];
    assign expA = a[30:24];
    assign mantA = (expA == 7'b0) ? {1'b0, a[23:0]} : {1'b1, a[23:0]};

    assign sinalB = b[31];
    assign expB = b[30:24];
    assign mantB = (expB == 7'b0) ? {1'b0, b[23:0]} : {1'b1, b[23:0]};

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            estado <= EXPO;
            bit_inexact <= 0;
            bit_overflow <= 0;
            bit_underflow <= 0;
            sinal_result <= 0;
            status_out <= 0;
            exp_dif <= 0;
            exp_result <= 0;
            mant_result <= 0;
            mantA_shifted <= 0;
            mantB_shifted <= 0;
            mant_result_temp <= 0;
            data_out <= 0;
        end else begin
            case (estado)
                EXPO: begin
                    if (a == 32'd0 && b == 32'd0) begin // os 2 são zero
                        data_out <= 32'd0;
                        status_out <= 4'b0001;  // EXACT
                        estado <= READY;
                    end else begin
                        bit_overflow <= 1'b0;
                        bit_inexact <= 1'b0;
                        bit_underflow <= 1'b0;

                        if (expA > expB) begin
                            exp_dif <= expA - expB;
                            if (exp_dif > 7'd26) begin
                                mantB_shifted <= 26'd0;
                                mantA_shifted <= mantA;
                                exp_result <= expA;
                                if (mantB != 0)
                                    bit_inexact <= 1'b1;
                            end else begin
                                mantB_shifted <= mantB >> exp_dif;
                                mantA_shifted <= mantA;
                                exp_result <= expA;
                                for (int i = 0; i < exp_dif; i++) begin
                                    if (mantB[i])
                                        bit_inexact <= 1'b1;
                                end
                            end
                        end else if (expB > expA) begin 
                            exp_dif <= expB - expA;
                            if (exp_dif > 7'd26) begin
                                mantA_shifted <= 26'd0;
                                mantB_shifted <= mantB;
                                exp_result <= expB;
                                if (mantA != 0)
                                    bit_inexact <= 1'b1;
                            end else begin
                                mantA_shifted <= mantA >> exp_dif;
                                mantB_shifted <= mantB;
                                exp_result <= expB;
                                // verifica bits inexatos
                                for (int i = 0; i < exp_dif; i++) begin
                                    if (mantA[i])
                                        bit_inexact <= 1'b1;
                                end
                            end
                        end else begin
                            mantA_shifted <= mantA;
                            mantB_shifted <= mantB;
                            exp_result <= expA;
                            exp_dif <= 7'd0;
                            bit_inexact <= 1'b0;
                        end
                        estado <= ADD_SUB;
                    end
                end

                ADD_SUB: begin
                    if (sinalA == sinalB) begin // Soma direta
                        mant_result_temp <= mantA_shifted + mantB_shifted;
                        sinal_result <= sinalA;
                    end else begin              // Subtração
                        if (mantA_shifted >= mantB_shifted) begin
                            mant_result_temp <= mantA_shifted - mantB_shifted;
                            sinal_result <= sinalA;
                        end else begin
                            mant_result_temp <= mantB_shifted - mantA_shifted;
                            sinal_result <= sinalB;
                        end
                    end
                    estado <= CORRIGE;
                end

                CORRIGE: begin
                    if (mant_result_temp == 27'd0) begin  // resultado é zero
                        mant_result <= 25'd0;
                        exp_result <= 7'd0;
                        estado <= READY;
                    end else if (exp_result >= 7'd127) begin
                        bit_overflow <= 1'b1;
                        mant_result_temp <= 27'd0;
                        estado <= READY;
                    end else if (mant_result_temp[26]) begin
                        mant_result_temp <= mant_result_temp >> 1;
                        exp_result <= exp_result + 1;
                    end else if (mant_result_temp[25] == 1'b0) begin
                        if (exp_result == 7'd0) begin
                            mant_result_temp <= 27'd0;
                            bit_underflow <= 1'b1;
                            estado <= READY;
                        end else begin
                            mant_result_temp <= mant_result_temp << 1;
                            exp_result <= exp_result - 1;
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

                READY: begin
                    if (bit_overflow) begin
                        data_out <= 32'd0;
                        status_out <= 4'b0100; // caso de overflow
                    end else if (bit_underflow) begin
                        data_out <= 32'd0;
                        status_out <= 4'b1000; // caso de underflow
                    end else begin
                        data_out <= {sinal_result, exp_result, mant_result[23:0]};
                        if (bit_inexact)
                            status_out <= 4'b0010; // inexato
                        else
                            status_out <= 4'b0001; // exato
                    end
                    estado <= EXPO;
                end
                default: estado <= EXPO;
            endcase
        end
    end
endmodule
