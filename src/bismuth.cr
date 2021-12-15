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

    @adapter = WGPU::Adapter.request(@main_window.surface).get
    abort("Failed to initialize graphics adapter") unless @adapter.is_ready?
    @device = WGPU::Device.request(
      @adapter,
      @name,
      @debug ? Path[Dir.current].join("#{@name.split(" ").join("-")}_gpu_trace").to_s : nil
    ).get
    abort("Failed to initialize graphics device") unless @device.is_valid?

    @main_window.startup(@adapter, @device)
    puts "Created #{@name} main window"
    @windows.push @main_window
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
      puts "#{@name} main window shown"
    end

    startup_time = Time.monotonic.total_milliseconds
    frame_time = Time::Span::ZERO

    while @active
      desired_frame_time = 1.0_f64 / @desired_fps

      # How long the previous frame took
      elapsed_time = Time.measure do
        Glfw.poll_events
        @active = false if @main_window.should_close?

        @windows.each { |window| window.update }

        tick = Tick.new(desired_frame_time, frame_time.total_seconds, startup_time)
        self.tick tick, @main_window.input

        @windows.each do |window|
          window.render
          self.render(window)
          window.title= "#{@name} - Frame time: #{sprintf "%1.2d", frame_time.total_milliseconds}ms" if @debug
        end

        self.flush
      end

      break unless @active
      frame_time = elapsed_time.not_nil!

      # Don't thrash the CPU if rendering faster than desired FPS
      while frame_time.total_seconds < desired_frame_time
        wait_time = desired_frame_time * 1000 - frame_time.total_milliseconds
        frame_time += Time.measure do
          # Sleep for 0.5 milliseconds
          sleep Time::Span.new(nanoseconds: 1000000 * wait_time.to_i32)
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

  # Called at intervals designated by the configured frame rate.
  # This is used to render the scene for each of the app's windows.
  abstract def render(window : Window)

  # Called to perform cleanup operations after the screen has been rendered.
  private def flush
    @windows.each do |window|
      window.swap_chain.not_nil!.present
    end
  end

  # Called when the application is shutting down.
  protected def shutdown
  end
end
