let
  # bed spec: 235x235
  max_x = 249;
  min_x_printable = 0;
  max_x_printable = max_x + probe_offset_x; # edge of bed is 230, but probe can't reach
  center_x = (max_x_printable - min_x_printable) / 2 + min_x_printable;
  max_y = 235;
  min_y_printable = 10;
  max_y_printable = max_y + probe_offset_y; # edge of bed is 235, but probe can't reach
  center_y = (max_y_printable - min_y_printable) / 2 + min_y_printable;
  max_z = 235;
  probe_offset_x = -39;
  probe_offset_y = -9;
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

  "adxl345 x" = {
    cs_pin = "EBB: PB12";
    spi_software_sclk_pin = "EBB: PB10";
    spi_software_mosi_pin = "EBB: PB11";
    spi_software_miso_pin = "EBB: PB2";
    axes_map = "z,-y,x";
  };

  "adxl345 y" = {
    cs_pin                = "PD2"; # CS
    spi_software_miso_pin = "PD3"; # SDO
    spi_software_mosi_pin = "PD4"; # SDA
    spi_software_sclk_pin = "PD5"; # SCL
    axes_map = "y,x,z"; # TODO
  };

  resonance_tester = {
    accel_chip_x = "adxl345 x";
    accel_chip_y = "adxl345 y";
    probe_points = "${toString center_x}, ${toString center_y}, 25";
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
    homing_speed = 50;
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
    home_xy_position = "${toString (center_x - probe_offset_x)}, ${toString (center_y - probe_offset_y)}";
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
    pin = "PB15";
    fan_speed = 0.6;
  };

  fan = { # part fan
    pin = "EBB: PA0";
  };

  "temperature_sensor Host" = {
    sensor_type = "temperature_host";
    # seems to follow the hottest core
    sensor_path = "/sys/class/thermal/thermal_zone2/temp";
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

  screws_tilt_adjust = {
    # move the probe to the correct location and record coordinates
    screw1_name = "rear left";
    screw1 = "68, 219";
    screw2_name = "front left";
    screw2 = "68, 49";
    screw3_name = "front right";
    screw3 = "239, 49";
    screw4_name = "rear right";
    screw4 = "239, 219";
    speed = 200;
    horizontal_move_z = 15;
    screw_thread = "CW-M4";
  };

  axis_twist_compensation = {
    speed = 100;
    # move the nozzle to the correct location and record coordinates
    calibrate_start_x = 0 + probe_offset_x; # cannot be zero
    calibrate_end_x = 225;
    calibrate_y = 110;
  };

  bltouch = {
    sensor_pin = "^EBB: PB8";
    control_pin = "EBB: PB9";
    stow_on_each_sample = false;
    # probe_with_touch_mode = true; # breaks bltouch clone
    speed = 5; # probing speed
    # there is no non-probing speed config
    lift_speed = 5;
    samples = 2;
    sample_retract_dist = 3;
    samples_tolerance = 0.02; # biqu microprobe is more accurate at 0.01
    samples_tolerance_retries = 3;
    # mandatory, but replaced with SAVE_CONFIG
    # comment once calibrated to avoid SAVE_CONFIG breaking
    z_offset = 0;
  };

  bed_mesh = {
    # debug slowly
    # speed = 25;
    # probe_count = 3;
    speed = 150;
    probe_count = 9;
    horizontal_move_z = 15;
    algorithm = "bicubic";
    # move the probe to the correct location and record coordinates
    mesh_min = "${toString (min_x_printable - probe_offset_x)},${toString (min_y_printable - probe_offset_y)}";
    mesh_max = "${toString (max_x_printable - probe_offset_x)},${toString (max_y_printable - probe_offset_y)}";
  };

  "delayed_gcode bed_mesh_init" = {
    initial_duration = 0.01;
    gcode = [
      "BED_MESH_PROFILE LOAD=default"
    ];
  };

  exclude_object = {};

  # make these macros appear in fluidd
  "gcode_macro SCREWS_TILT_CALCULATE_".gcode = ["SCREWS_TILT_CALCULATE"];
  "gcode_macro PROBE_CALIBRATE_".gcode = ["PROBE_CALIBRATE"];
  "gcode_macro AXIS_TWIST_COMPENSATION_CALIBRATE_".gcode = ["AXIS_TWIST_COMPENSATION_CALIBRATE"];
  "gcode_macro SHAPER_CALIBRATE_".gcode = ["SHAPER_CALIBRATE"];

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
}