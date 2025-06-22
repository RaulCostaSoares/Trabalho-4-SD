onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mod/a
add wave -noupdate /mod/b
add wave -noupdate /mod/data_out
add wave -noupdate /mod/status_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {377768 ns} 0}
quietly wave cursor active 1

TreeUpdate auto
WaveRestoreZoom auto

update
WaveRestoreZoom {0 ns} {1050 us}
view wave
WaveCollapseAll -1
