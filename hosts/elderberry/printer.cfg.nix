let
  # bed spec: 235x235
  max_x = 225; # will go to 245 beyond the bed
  max_y = 225; # artificially high to permit the probe to go as far as possible, nozzle hits bed edge at 214
  max_z = 235;
  probe_offset_x = 2;
  probe_offset_y = -41;
in {
  force_move = {
    enable_force_move = true;
  };

  "mcu" = {
    serial = "/dev/serial/by-id/usb-Klipper_stm32g0b0xx_11002C000D50415833323520-if00";
    baud = 115200;
    restart_method = "command";
  };

  "mcu EBB" = {
    canbus_uuid = "463a079eacd1";
  };

  adxl345 = {
    cs_pin = "EBB: PB12";
    spi_software_sclk_pin = "EBB: PB10";
    spi_software_mosi_pin = "EBB: PB11";
    spi_software_miso_pin = "EBB: PB2";
    axes_map = "x,y,z";
  };

  stepper_x = {
    step_pin = "PB13";
    dir_pin = "!PB12";
    enable_pin = "!PB14";
    microsteps = 16;
    rotation_distance = 40;
    endstop_pin = "^PC0";
    position_endstop = 0;
    position_max = max_x;
    homing_speed = 50;
    second_homing_speed = 10;
  };

  "tmc2209 stepper_x" = {
    uart_pin = "PC11";
    tx_pin = "PC10";
    uart_address = 0;
    run_current = 0.580;
    stealthchop_threshold = 999999;
  };

  stepper_y = {
    step_pin = "PB10";
    dir_pin = "!PB2";
    enable_pin = "!PB11";
    microsteps = 16;
    rotation_distance = 40;
    endstop_pin = "^PC1";
    position_endstop = 0;
    position_max = max_y;
    homing_speed = 30; # go slowly because the switch is attached with t-slots
    second_homing_speed = 10;
  };

  "tmc2209 stepper_y" = {
    uart_pin = "PC11";
    tx_pin = "PC10";
    uart_address = 2;
    run_current = 0.580;
    stealthchop_threshold = 999999;
  };

  stepper_z = {
    step_pin = "PB0";
    dir_pin = "PC5";
    enable_pin = "!PB1";
    microsteps = 16;
    rotation_distance = 8;
    endstop_pin = "probe:z_virtual_endstop";
    position_min = -5;
    position_max = max_z;
  };

  "tmc2209 stepper_z" = {
    uart_pin = "PC11";
    tx_pin = "PC10";
    uart_address = 1;
    # single Z
    run_current = 0.580;
    # dual Z
    # run_current = 1.16;
    stealthchop_threshold = 999999;
  };

  stepper_z1 = {
    step_pin = "PB3";
    dir_pin = "PB4";
    enable_pin = "!PD1";
    microsteps = 16;
    rotation_distance = 8;
  };

  "tmc2209 stepper_z1" = {
    uart_pin = "PC11";
    tx_pin = "PC10";
    uart_address = 3;
    # single Z
    run_current = 0.580;
    # dual Z
    # run_current = 1.16;
    stealthchop_threshold = 999999;
  };

  safe_z_home = {
    home_xy_position = "${toString (max_x / 2)}, ${toString (max_y / 2)}";
    speed = 200;
    z_hop = 5;
    z_hop_speed = 5;
  };

  extruder = {
    step_pin = "EBB: PD0";
    dir_pin = "!EBB: PD1";
    enable_pin = "!EBB: PD2";
    heater_pin = "EBB: PB13";
    sensor_pin = "EBB: PA3";
    sensor_type = "EPCOS 100K B57560G104F";
    microsteps = 16;
    max_extrude_only_distance = 500;
    rotation_distance = 7.5620;
    nozzle_diameter = 0.400;
    filament_diameter = 1.750;
    min_temp = 0;
    max_temp = 250;
    # mandatory, but replaced with SAVE_CONFIG
    # comment once calibrated to avoid SAVE_CONFIG breaking
    # control = "pid";
    # pid_Kp = "1";
    # pid_Ki = "1";
    # pid_Kd = "1";
  };

  "tmc2209 extruder" = {
    uart_pin = "EBB: PA15";
    run_current = 0.650;
    stealthchop_threshold = 999999;
  };

  heater_bed = {
    heater_pin = "PC9";
    sensor_type = "EPCOS 100K B57560G104F";
    sensor_pin = "PC4";
    min_temp = 0;
    max_temp = 130;
    # mandatory, but replaced with SAVE_CONFIG
    # comment once calibrated to avoid SAVE_CONFIG breaking
    # control = "pid";
    # pid_Kp = "1";
    # pid_Ki = "1";
    # pid_Kd = "1";
  };

  "heater_fan heatbreak_cooling_fan" = {
    pin = "EBB: PA1";
  };

  "controller_fan mainboard_fan" = {
    pin = "PC7";
  };

  fan = { # part fan
    pin = "EBB: PA0";
  };

  "temperature_sensor Host" = {
    sensor_type = "temperature_host";
    sensor_path = "/sys/class/thermal/thermal_zone3/temp";
    min_temp = 10;
    max_temp = 100;
  };

  "temperature_sensor BTT-SKR" = {
    sensor_type = "temperature_mcu";
    sensor_mcu = "mcu";
    min_temp = 0;
    max_temp = 100;
  };

  "temperature_sensor BTT-EBB" = {
    sensor_type = "temperature_mcu";
    sensor_mcu = "EBB";
    min_temp = 0;
    max_temp = 100;
  };

  printer = {
    kinematics = "cartesian";
    # it'll do 300 but it sounds a bit ropey, go 200 max
    max_velocity = 200;
    max_accel = 3000;
    max_z_velocity = 10;
    max_z_accel = 100;
  };

  "gcode_macro PROBE_DOWN" = {
    gcode = [
      "SET_PIN PIN=probe_enable VALUE=1"
    ];
  };

  "gcode_macro PROBE_UP" = {
    gcode = [
      "SET_PIN PIN=probe_enable VALUE=0"
    ];
  };

  "output_pin probe_enable" = {
    pin = "EBB: PB9";
    value = 0;
  };

  screws_tilt_adjust = {
    # move the probe to the correct location and record coordinates
    screw1_name = "rear left";
    screw1 = "28, 221";
    screw2_name = "front left";
    screw2 = "28, 51";
    screw3_name = "front right";
    screw3 = "197, 51";
    screw4_name = "rear right";
    screw4 = "197, 221";
    speed = 200;
    screw_thread = "CW-M4";
  };

  axis_twist_compensation = {
    speed = 100;
    # move the nozzle to the correct location and record coordinates
    calibrate_start_x = 0 + probe_offset_x; # cannot be zero
    calibrate_end_x = 225;
    calibrate_y = 110;
  };

  probe = {
    pin = "^!EBB: PB8";
    deactivate_on_each_sample = false;
    x_offset = probe_offset_x;
    y_offset = probe_offset_y;
    speed = 5; # probing speed
    # there is no non-probing speed config
    lift_speed = 5;
    samples = 2;
    samples_tolerance = 0.01;
    samples_tolerance_retries = 3;
    activate_gcode = [
      "PROBE_UP"
      "PROBE_DOWN"
      "G4 P500"
    ];
    deactivate_gcode = [
      "PROBE_UP"
    ];
    # mandatory, but replaced with SAVE_CONFIG
    # comment once calibrated to avoid SAVE_CONFIG breaking
    # z_offset = 0;
  };

  bed_mesh = {
    # debug slowly
    # speed = 25;
    # probe_count = 3;
    speed = 150;
    probe_count = 9;
    horizontal_move_z = 2;
    algorithm = "bicubic";
    # move the nozzle to the correct location and record coordinates
    mesh_min = "${toString (0 + probe_offset_x)},0";
    mesh_max = "225,${toString (max_y + probe_offset_y)}";
  };

  "delayed_gcode bed_mesh_init" = {
    initial_duration = 0.01;
    gcode = [
      "BED_MESH_PROFILE LOAD=default"
    ];
  };

  # make these macros appear in fluidd
  "gcode_macro MACRO_SCREWS_TILT_CALCULATE".gcode = ["SCREWS_TILT_CALCULATE"];
  "gcode_macro MACRO_PROBE_CALIBRATE".gcode = ["PROBE_CALIBRATE"];
  "gcode_macro MACRO_AXIS_TWIST_COMPENSATION_CALIBRATE".gcode = ["AXIS_TWIST_COMPENSATION_CALIBRATE"];

  # other macros
  "gcode_macro CALIBRATE_PID_EXTRUDER".gcode = ["PID_CALIBRATE HEATER=extruder TARGET=220"];
  "gcode_macro CALIBRATE_PID_BED".gcode = ["PID_CALIBRATE HEATER=heater_bed TARGET=65"];

  # TODO: put this back on
  # "filament_switch_sensor runout" = {
  #   pause_on_runout = true;
  #   # runout_gcode= ''
  #   #     PAUSE
  #   #   '';
  #   # insert_gcode= ''
  #   #     RESUME
  #   #   '';
  #   event_delay = 1.0;
  #   switch_pin = "^PC2";
  # };

  # TODO: calibrate this
  # input_shaper = {
  #   shaper_freq_x = 29.6;
  #   shaper_freq_y = 32.3;
  # };
}