require "glfw"
require "render_loop"
require "wgpu"

require "./window.cr"

alias Tick = RenderLoop::Tick

# A Bismuth application.
abstract class App < RenderLoop::Engine
  # Whether this application is in debug mode.
  @debug = true
  @active = false
  @windows = Array(Window).new
  # Graphics resources
  @adapter : WGPU::Adapter
  getter device : WGPU::Device

  def initialize(name : String, width : UInt16 = 800, height : UInt16 = 600, fullscreen = false, @desired_fps = 60_u32)
    @name = name
    {% if flag?(:release) %}
    @debug = false
    {% end %}

    at_exit { puts "#{@name} app exited" }

    WGPU.set_log_level(@debug ? WGPU::LogLevel::Trace : WGPU::LogLevel::Warning)

    Glfw.set_error_callback ->(num, msg) { puts String.new(msg) }
    abort("Could not initialize GLFW", 1) unless Glfw.init

    @main_window = Window.new @name
    puts "Created main window"
    @main_window.startup
    @windows.push @main_window

    @adapter = WGPU::Adapter.request(@main_window.surface).get
    abort("Failed to initialize graphics adapter") unless @adapter.is_ready?
    @device = WGPU::Device.request(
      @adapter,
      @name,
      @debug ? Path[Dir.current].join("#{@name.split(" ").join("-")}_gpu_trace").to_s : nil
    ).get
    abort("Failed to initialize graphics device") unless @device.is_valid?
  end

  def desired_fps
    @desired_fps
  end

  def desired_fps(fps : UInt32)
    @desired_fps = fps
  end

  def run
    @active = true
    self.startup

    unless @main_window.visible?
      @main_window.show
      puts "Main window shown"
    end

    startup_time = Time.monotonic.total_milliseconds # When the loop started
    last_time = Time.monotonic.total_milliseconds
    unprocessed_time = 0_f64

    while @active
      should_render = false
      start_time = Time.monotonic.total_milliseconds
      passed_time = start_time - last_time # How long the previous frame took
      last_time = start_time
      unprocessed_time += passed_time
      frame_time = 1.0f64 / @desired_fps

      while unprocessed_time > frame_time
        should_render = true
        unprocessed_time -= frame_time

        Glfw.poll_events
        @active = false if @main_window.should_close?
        break unless @active

        tick = Tick.new(frame_time, passed_time, startup_time)
        self.tick tick, @main_window.input
      end

      # Sleep for 1 millisecond
      sleep(Time::Span.new(nanoseconds: 1000000)) unless should_render

      if should_render
        self.render
        self.flush

        @windows.each do |window|
          window.render
          window.title= "#{@name} - Frame time: #{sprintf "%1.2d", passed_time}ms" if @debug
        end
      end
    end

    self.shutdown

    Glfw.terminate
    puts "Main window destroyed"
  end

  # Called when the main loop is starting up.
  # Use this to set things up.
  abstract def startup

  private def tick(tick : Tick, input : RenderLoop::Input)
    self.tick tick
  end

  # Called at each iteration of the main loop.
  # This is when application state should be updated.
  abstract def tick(tick : Tick)

  # Called at intervals desigated by the configured frame rate.
  # This is used to render the scene.
  abstract def render

  # Called to perform cleanup operations after the sceen has been rendered.
  protected def flush
  end

  # Called when the application is shutting down.
  protected def shutdown
  end
end
