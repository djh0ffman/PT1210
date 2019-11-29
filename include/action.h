/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * action.h
 * Actions which can be triggered by input events.
 */

#ifndef ACTION_H
#define ACTION_H

/* Actions which can be bound to keys */
void pt1210_action_switch_screen();
void pt1210_action_pitch_up();
void pt1210_action_pitch_down();
void pt1210_action_pitch_up_fine();
void pt1210_action_pitch_down_fine();
void pt1210_action_nudge_forward();
void pt1210_action_nudge_backward();
void pt1210_action_nudge_forward_hard();
void pt1210_action_nudge_backward_hard();
void pt1210_action_play_pause();
void pt1210_action_restart();
void pt1210_action_slip_restart();
void pt1210_action_pattern_cue_set();
void pt1210_action_pattern_cue_move_forward();
void pt1210_action_pattern_cue_move_backward();
void pt1210_action_pattern_loop();
void pt1210_action_loop_increase();
void pt1210_action_loop_decrease();
void pt1210_action_loop_cycle();
void pt1210_action_toggle_line_loop();
void pt1210_action_toggle_slip();
void pt1210_action_toggle_channel_1();
void pt1210_action_toggle_channel_2();
void pt1210_action_toggle_channel_3();
void pt1210_action_toggle_channel_4();
void pt1210_action_toggle_repitch();
void pt1210_action_kill_sound_dma();
void pt1210_action_move_forward_line_loop();
void pt1210_action_move_forward_pattern();
void pt1210_action_move_backward_line_loop();
void pt1210_action_move_backward_pattern();
void pt1210_action_quit();

/* File selector actions */
void pt1210_action_fs_char_handler(char character);
void pt1210_action_fs_move_up();
void pt1210_action_fs_move_down();
void pt1210_action_fs_page_up();
void pt1210_action_fs_page_down();
void pt1210_action_fs_parent();
void pt1210_action_fs_select();
void pt1210_action_fs_sort_name();
void pt1210_action_fs_sort_bpm();
void pt1210_action_fs_rescan();

#endif /* ACTION_H */
