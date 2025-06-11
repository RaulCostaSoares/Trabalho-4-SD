if {[file isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

vlog -work work ../../HDL/fila.sv
vlog -work work ../../HDL/deserializador.sv
vlog -work work ../../HDL/clock_divisor.sv

vlog -work work ../../HDL/top.sv

vlog -work work tb_top.sv
vsim -voptargs=+acc work.tb_top

quietly set StdArithNoWarnings 1
quietly set StdVitalGlitchNoWarnings 1

do wave.do
run -all

