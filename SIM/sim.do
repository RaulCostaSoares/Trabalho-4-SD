if {[file isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work

vlog -work work ../rtl/fpu.sv

vlog -work work tb_fpu.sv
vsim -voptargs=+acc work.tb_fpu

quietly set StdArithNoWarnings 1
quietly set StdVitalGlitchNoWarnings 1

do wave.do
run -all