require "future"
require "glfw"
require "render_loop"
require "wgpu"

require "./input.cr"
require "./platform.cr"

class SwapChainDescriptor < WGPU::SwapChainDescriptor
  def self.from_window(window : Window, format : WGPU::TextureFormat, present_mode = WGPU::PresentMode::Fifo)
    raise ArgumentError.new "Window surface is not valid" unless window.surface.not_nil!.is_valid?

    self.new(LibWGPU::SwapChainDescriptor.new(
      label: window.title,
      usage: WGPU::TextureUsage::RenderAttachment,
      format: format,
      width: window.width,
      height: window.height,
      present_mode: present_mode,
    ))
  end
end

alias Input = RenderLoop::Input(Key, MouseButton)

class Window < RenderLoop::Window(Key, MouseButton)
  @handle : Glfw::Window* = Pointer(Void).null
  getter title : String
  getter width : UInt16
  getter height : UInt16
  # Graphics resources
  getter surface : WGPU::Surface?
  getter swap_chain : WGPU::SwapChain?

  def initialize(@title : String, @width : UInt16 = 800, @height : UInt16 = 600, @fullscreen = false, @cursor_visible = false)
    @input = Input.new self
    @primary_monitor = Glfw.get_primary_monitor
    @old_size = {width: @width, height: @height}
  end

  def startup
    Glfw.window_hint(Glfw::VISIBLE, @visible = false)
    Glfw.window_hint(Glfw::CLIENT_API, Glfw::NO_API) # Graphics are handled by wgpu
    @handle = Glfw.create_window(@width, height, @title, @fullscreen ? Glfw.get_primary_monitor : Pointer(Void).null, nil)
    abort("Failed to initialize a new GLFW Window", 1) if @handle.null?

    @surface = Platform.create_surface @title, @handle
    abort("Failed to create graphics surface", 1) unless @surface.not_nil!.is_valid?
    puts "Created native graphics surface for #{@title} window"
  end

  def startup(adapter : WGPU::Adapter, device : WGPU::Device)
    self.startup

    @device = device
    @surface.not_nil!.preferred_format(adapter)
    self.update
  end

  def size : RenderLoop::Size
    Glfw.get_window_size @handle, out width, out height
    @width = UInt16.new(width)
    @height = UInt16.new(height)
    {width: Int32.new(@width), height: Int32.new(@height)}
  end

  def size(s : RenderLoop::Size)
    Glfw.set_window_size @handle, @width = s[:width], @height = s[:height]
  end

  def fullscreen?
    @fullscreen
  end

  def visible?
    @visible
  end

  def should_close? : Bool
    Glfw.window_should_close(@handle) == Glfw::TRUE
  end

  def update
    # Recreate this window's swap chain if the window is new or its size has changed
    if @swap_chain.nil? || @old_size != self.size
      @old_size = {width: @width, height: @height}
      surface = @surface.not_nil!
      abort("Window surface is not valid", 1) unless surface.is_valid?

      future_swap_chain_desc = future { SwapChainDescriptor.from_window self, surface.preferred_format.not_nil!.get }
      # TODO: Destroy swap chain if it is not nil
      @swap_chain = @device.not_nil!.create_swap_chain @surface.not_nil!, future_swap_chain_desc.get
    end
  end

  def render
  end

  def destroy
    Glfw.destroy_window @handle
  end

  def title=(title : String)
    Glfw.set_window_title @handle, @title = title
  end

  def input
    @input.not_nil!.as(Input)
  end

  def key_pressed?(k : Key) : Bool
    Glfw.get_key(@handle, k.value) == Glfw.PRESS
  end

  def mouse_button_pressed?(b : MouseButton) : Bool
    Glfw.get_mouse_button(@handle, b.value) == Glfw.PRESS
  end

  def cursor_position : RenderLoop::Position
    Glfw.get_cursor_pos @handle, out x, out y
    {x, y}
  end

  def cursor_position=(position : RenderLoop::Position)
    Glfw.set_cursor_pos @handle, position[0], position[1]
  end

  def cursor_visible?
    @cursor_visible
  end

  def cursor_visible=(visible : Bool)
    Glfw.set_input_mode @handle, Glfw::CURSOR, visible ? Glfw::CURSOR_NORMAL : Glfw::CURSOR_DISABLED
    @cursor_visible = get_input_mode(@handle, Glfw::CURSOR) == Glfw::CURSOR_NORMAL
  end

  def show
    Glfw.show_window @handle
    @visible = true
  end

  def hide
    Glfw.hide_window @handle
    @visible = false
  end
end
