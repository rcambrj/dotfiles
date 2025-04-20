# based on https://github.com/strayr/strayr-k-macros/blob/fc6dc939ab97481086aa1fb9d96f093ee63775c8/mechanical_level_tmc2209.cfg
{
  "gcode_macro MECHANICAL_GANTRY_CALIBRATION" = {
    gcode = [
      ### config
      "{% set low_current        = 0.1 %}"     # set this very low
      "{% set low_current_travel = 10.0 %}"    # distance to travel beyond z_max
      "{% set low_current_speed  = 6 * 60 %}"  # z travel speed
      "{% set return_to_z        = 50 %}"      # fast return to this z before homing slowly
      ### config

      "{% set oldcurrent = printer.configfile.settings[\"tmc2209 stepper_z\"].run_current %}"
      "{% set oldhold = printer.configfile.settings[\"tmc2209 stepper_z\"].hold_current %}"
      "{% set x_max = printer.toolhead.axis_maximum.x %}"
      "{% set y_max = printer.toolhead.axis_maximum.y %}"
      "{% set z_max = printer.toolhead.axis_maximum.z %}"
      "{% set fast_move_z = printer.configfile.settings[\"printer\"].max_z_velocity %}"
      "{% set fast_move = printer.configfile.settings[\"printer\"].max_velocity %}"
      "{% if printer.homed_axes != 'xyz' %}"
        # home All Axes
        "G28"
      "{% endif %}"
      "G90" # absolute
      "G0 X{x_max / 2} Y{y_max / 2} F{fast_move * 30 }" # put toolhead in the center of the gantry

      "G0 Z{z_max -1} F{fast_move_z * 60}" # go to the Z-max at speed max z speed

      # drop Z current
      "SET_TMC_CURRENT STEPPER=stepper_z CURRENT={low_current}"
      "{% if printer.configfile.settings[\"stepper_z1\"] %}" # test for dual Z
          "SET_TMC_CURRENT STEPPER=stepper_z1 CURRENT={low_current}"
      "{% endif %}"

      "G4 P200" # wait
      "SET_KINEMATIC_POSITION Z={z_max - 2 - low_current_travel}" # force the low-level kinematic code to believe the toolhead is lower than it is
      "G4 P200" # wait
      "G1 Z{z_max - 2} F{low_current_speed}" # move up by low_current_travel
      "G4 P200" # wait
      "G1 Z{z_max - 2 - low_current_travel} F{low_current_speed}" # move back down before reverting current
      "G4 P200" # wait

      # reset Z current
      "SET_TMC_CURRENT STEPPER=stepper_z CURRENT={oldcurrent} HOLDCURRENT={oldhold}"
      "{% if printer.configfile.settings[\"stepper_z1\"] %}" # test for dual Z
          "SET_TMC_CURRENT STEPPER=stepper_z1 CURRENT={oldcurrent} HOLDCURRENT={oldhold}"
      "{% endif %}"

      "G4 P200" # wait
      "G1 Z{return_to_z} F{fast_move_z * 60}" # move down quickly

      "G4 P200" # wait
      "G28 Z" # we MUST home again as the ganty is really in the wrong place.
    ];
  };
}