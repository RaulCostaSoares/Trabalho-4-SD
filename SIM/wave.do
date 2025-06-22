onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /uut/clk
add wave -noupdate /uut/reset
add wave -noupdate /uut/a
add wave -noupdate /uut/b
add wave -noupdate /uut/op
add wave -noupdate /uut/data_out
add wave -noupdate /uut/status_out
add wave -noupdate /uut/flags_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {377768 ns} 0}
quietly wave cursor active 1
add wave -noupdate /uut/current_state
add wave -noupdate /uut/expA
add wave -noupdate /uut/expB
add wave -noupdate /uut/exp_result
add wave -noupdate /uut/exp_dif
add wave -noupdate /uut/mant_result
add wave -noupdate /uut/mantA
add wave -noupdate /uut/mantB
add wave -noupdate /uut/mantA_shifted
add wave -noupdate /uut/mantB_shifted
add wave -noupdate /uut/mant_result_temp
add wave -noupdate /uut/sinalA
add wave -noupdate /uut/sinalB
add wave -noupdate /uut/sinal_result
add wave -noupdate /uut/bit_overflow
add wave -noupdate /uut/bit_inexact
add wave -noupdate /uut/bit_underflow

TreeUpdate auto
WaveRestoreZoom auto

update
WaveRestoreZoom {0 ns} {1050 us}
view wave
WaveCollapseAll -1
