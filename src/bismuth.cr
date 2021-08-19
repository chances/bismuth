require "glfw"
require "wgpu"

require "./platform.cr"

abstract class App
  # Whether this App is in debug mode.
  @debug = true
  @adapter : WGPU::Adapter
  @device : WGPU::Device
  @windows = Array(Glfw::Window*).new

  def initialize(name : String, width : UInt16 = 800, height : UInt16 = 600, fullscreen = false)
    @name = name
    @active = true
    {% if flag?(:release) %}
      @debug = false
    {% end %}
    WGPU.set_log_level(@debug ? WGPU::LogLevel::Trace : WGPU::LogLevel::Warning)

    Glfw.set_error_callback ->(num, msg) { puts String.new(msg) }
    abort("Could not initialize GLFW", 1) unless Glfw.init

    @primary_monitor = Glfw.get_primary_monitor

    # Glfw.window_hint(Glfw::VISIBLE, false)
    Glfw.window_hint(Glfw::CLIENT_API, Glfw::NO_API) # Graphics are handled by wgpu
    @main_window = Glfw.create_window(width, height, name, fullscreen ? @primary_monitor : Pointer(Void).null, nil)
    abort("Failed to initialize a new GLFW Window", 1) if @main_window.null?
    puts "Created main window"
    @windows.push @main_window

    @surface = Platform.create_surface @name, @main_window
    abort("Failed to create graphics surface", 1) unless @surface.is_valid?
    puts "Created native graphics surface"

    @adapter = WGPU::Adapter.request(@surface).get
    abort("Failed to initialize graphics adapter") unless @adapter.is_ready?
    @device = WGPU::Device.request(
      @adapter,
      @name,
      @debug ? Path[Dir.current].join("#{@name.split(" ").join("-")}_gpu_trace").to_s : nil
    ).get
    abort("Failed to initialize graphics device") unless @device.is_valid?
  end

  def run
    Glfw.show_window @main_window
    Glfw.poll_events
    puts "Main window shown"

    while @active
      Glfw.poll_events
      @active = false if Glfw.window_should_close(@main_window) == Glfw::TRUE
      Fiber.yield
    end
  end
end
