{
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
    position_max = 245;
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
    position_max = 230;
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
    position_max = 235;
  };

  "tmc2209 stepper_z" = {
    uart_pin = "PC11";
    tx_pin = "PC10";
    uart_address = 1;
    # single Z
    # run_current = 0.580;
    # dual Z
    run_current = 1.16;
    stealthchop_threshold = 999999;
  };

  safe_z_home = {
  # 220 / 2 - x/y offset
    home_xy_position = "110, 152";
    speed = 200;
    z_hop = 5;
    z_hop_speed = 5;
  };

  extruder = {
    # SKR
    # step_pin = "PB3";
    # dir_pin = "!PB4";
    # enable_pin = "!PD1";
    # heater_pin = "PC8";
    # sensor_pin = "PA0";
    # EBB
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
    # SKR
    # uart_pin = "PC11";
    # tx_pin = "PC10";
    # uart_address = 3;
    # EBB
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
    # SKR
    # pin = "PA1";
    # EBB
    pin = "EBB: PB9";
    value = 0;
  };

  screws_tilt_adjust = {
    # toolhead cannot go back far enough to reach rear screws, go max instead.
    screw1_name = "rear left";
    screw1 = "28, 230";
    screw2_name = "front left";
    screw2 = "28, 77";
    screw3_name = "front right";
    screw3 = "197, 77";
    screw4_name = "rear right";
    screw4 = "197, 230";
    speed = 200;
    screw_thread = "CW-M4";
  };

  axis_twist_compensation = {
    speed = 100;
    calibrate_start_x = 20;
    calibrate_end_x = 210;
    calibrate_y = 112.5;
  };

  probe = {
    pin = "^!EBB: PB8";
    deactivate_on_each_sample = false;
    x_offset = 2;
    y_offset = -41;
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
    speed = 200;
    probe_count = 9;
    horizontal_move_z = 2;
    algorithm = "bicubic";
    # this is probe position (gets automatically adjusted by probe offset)
    mesh_min = "10,20";
    mesh_max = "220,189";
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