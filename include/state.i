;
;   ____ _____     _ ____  _  ___
;  |  _ |_   _|   / |___ \/ |/ _ \
;  | |_) || |_____| | __) | | | | |
;  |  __/ | |_____| |/ __/| | |_| |
;  |_|    |_|     |_|_____|_|\___/
;
;  Protracker DJ Player
;
;  state.i
;  Program state information.
;

; Player state data structure
	rsreset
ps_channel_toggle			rs.w 1
ps_loop_active				rs.b 1
ps_loop_start				rs.b 1
ps_loop_end					rs.b 1
ps_loop_size				rs.b 1
ps_slip_on					rs.b 1
ps_repitch_enabled			rs.b 1
ps_repitch_lock_enabled		rs.b 1
ps_pattern_slip_pending		rs.b 1
ps_size						rs.b 0

; Global state data structure
	rsreset
gs_screen					rs.l 1
gs_player					rs.b ps_size
gs_size						rs.b 0

; Imports from C code
	xref					_pt1210_state
