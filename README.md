# Projeto: FPU

Uma FPU (Unidade de Ponto Flutuante) é um componente de hardware responsável por realizar operações matemáticas com números em ponto flutuante, como adição, subtração, multiplicação e divisão. Ela é otimizada para lidar com a representação e o cálculo de números reais (com casas decimais), seguindo padrões como o IEEE 754. Isso permite maior precisão e desempenho em cálculos científicos, gráficos e aplicações que exigem manipulação de valores não inteiros.

### Configuração do Expoente e Mantissa

Nesta FPU, o formato de 32 bits é definido por:

- 1 bit de sinal  
- \(X\) bits para o expoente  
- \(Y\) bits para a mantissa  

Os valores de \(X\) e \(Y\) são calculados a partir da matrícula do autor, que determina:

- \(X = 8 - (\sum d \mod 4)\), onde \(\sum d\) é a soma dos dígitos da matrícula  
- \(Y = 31 - X\)

No caso da matricula 24104884-2, temos  **\(X = 7\)** bits para o expoente e **\(Y = 24\)** bits para a mantissa.

---
## 📌 Objetivo do Projeto

Este projeto implementa uma **FPU (Floating Point Unit)** simplificada utilizando a linguagem **Verilog**, com o propósito de realizar **operações de soma e subtração em ponto flutuante**, porém com algumas alterações feitas pela proposta do trabalho:

- **1 bit para o sinal** (bit 31)
- **7 bits para o expoente**
- **24 bits para a mantissa**

A FPU foi desenvolvida como parte de um trabalho acadêmico, com foco em compreender a lógica por trás das operações aritméticas em ponto flutuante, além de aplicar boas práticas em projetos sequenciais com máquinas de estados finitos.

---


## 🔧 Estados

- Operação de `adição` e `subtração` entre dois operandos de 32 bits
- Controle interno de `overflow`, `underflow` e `arredondamento`
- Máquina de estados finita com os estados:
  - `EXPO`: Alinhamento de expoentes
  - `ADD_SUB`: Operação aritmética (soma/subtração)
  - `CORRIGE`: Normalização e arredondamento do resultado
  - `READY`: Geração da saída final

---

## Execução

#### Imagens da execução da calculadora
