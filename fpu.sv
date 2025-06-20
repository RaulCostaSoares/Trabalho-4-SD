// Clock de 100 kHz
typedef enum logic[3:0] {
    DECODIFICAR,
    ALINHAR,
    CALCULAR,
    NORMALIZAR,
    ESCREVER
} estado_t;

typedef enum logic[3:0] {
    MUITO_GRANDE,
    MUITO_PEQUENO,
    EXATO,
    APROXIMADO
} resultado_t;

module FPU (
    input logic clock,
    input logic reset, // reset assíncrono (ativo em baixo)
    input logic [31:0] numero_a,
    input logic [31:0] numero_b,
    output logic [31:0] saida,
    output resultado_t status
);

estado_t estado_atual, proximo_estado;
logic sinal_a, sinal_b, maior, inicio, pronto_decod, pronto_alinhar, pronto_calcular, pronto_normalizar, pronto_escrever, bit_extra;
logic [21:0] mantissa_a, mantissa_b, mantissa_temp;
logic [9:0] expoente_a, expoente_b, expoente_temp;
logic [9:0] diferenca_exp;
logic [4:0] contador;

// Atualiza o estado
always_ff @(posedge clock or negedge reset) begin
    if (!reset) begin
        estado_atual <= DECODIFICAR;
    end else begin
        estado_atual <= proximo_estado;
    end
end

// Decide próximo estado
always_comb begin
    proximo_estado = estado_atual;
    if (estado_atual == DECODIFICAR && pronto_decod) proximo_estado = ALINHAR;
    else if (estado_atual == ALINHAR && pronto_alinhar) proximo_estado = CALCULAR;
    else if (estado_atual == CALCULAR && pronto_calcular) proximo_estado = NORMALIZAR;
    else if (estado_atual == NORMALIZAR && pronto_normalizar) proximo_estado = ESCREVER;
    else if (estado_atual == ESCREVER && pronto_escrever) proximo_estado = DECODIFICAR;
end

// Compara os números
always_comb begin
    if (numero_a[30:21] >= numero_b[30:21]) begin
        maior = 1;
    end else begin
        maior = 0;
    end
end

// Processa tudo
always_ff @(posedge clock or negedge reset) begin
    if (!reset) begin
        saida <= 32'd0;
        status <= EXATO;
        mantissa_temp <= 22'd0;
        expoente_temp <= 10'd0;
        contador <= 5'd0;
        inicio <= 1;
        pronto_decod <= 0;
        pronto_alinhar <= 0;
        pronto_calcular <= 0;
        pronto_normalizar <= 0;
        pronto_escrever <= 0;
    end else begin
        case (estado_atual)
            DECODIFICAR: begin
                if (inicio) begin
                    if (maior) begin
                        mantissa_a <= {1'b1, numero_a[20:0]};
                        expoente_a <= numero_a[30:21] - 511;
                        sinal_a <= numero_a[31];
                        mantissa_b <= {1'b1, numero_b[20:0]};
                        expoente_b <= numero_b[30:21] - 511;
                        sinal_b <= numero_b[31];
                    end else begin
                        mantissa_a <= {1'b1, numero_b[20:0]};
                        expoente_a <= numero_b[30:21] - 511;
                        sinal_a <= numero_b[31];
                        mantissa_b <= {1'b1, numero_a[20:0]};
                        expoente_b <= numero_a[30:21] - 511;
                        sinal_b <= numero_a[31];
                    end
                    diferenca_exp <= expoente_a - expoente_b;
                    inicio <= 0;
                    pronto_decod <= 1;
                end else begin
                    inicio <= 1;
                end
            end
            ALINHAR: begin
                mantissa_b <= mantissa_b >> diferenca_exp;
                pronto_alinhar <= 1;
            end
            CALCULAR: begin
                if (sinal_a == sinal_b) begin
                    {bit_extra, mantissa_temp} <= mantissa_a + mantissa_b;
                end else begin
                    mantissa_temp <= mantissa_a - mantissa_b;
                    bit_extra <= 0;
                end
                expoente_temp <= expoente_a;
                if (bit_extra) begin
                    mantissa_temp <= mantissa_temp >> 1;
                    expoente_temp <= expoente_temp + 1;
                end
                contador <= 5'd0;
                pronto_calcular <= 1;
            end
            NORMALIZAR: begin
                if (mantissa_temp[21] == 0 && expoente_temp > 0 && contador < 21) begin
                    mantissa_temp <= mantissa_temp << 1;
                    expoente_temp <= expoente_temp - 1;
                    contador <= contador + 1;
                end else begin
                    pronto_normalizar <= 1;
                end
            end
            ESCREVER: begin
                saida <= {sinal_a, (expoente_temp + 511), mantissa_temp[20:0]};
                pronto_escrever <= 1;
                if (expoente_temp == 0)
                    status <= MUITO_PEQUENO;
                else if (expoente_temp == 1023)
                    status <= MUITO_GRANDE;
                else if (mantissa_temp[0] != 0)
                    status <= APROXIMADO;
                else
                    status <= EXATO;
            end
        endcase
    end
end

endmodule