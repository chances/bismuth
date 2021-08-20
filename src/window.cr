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

  def initialize(@title : String, @width : UInt16 = 800, @height : UInt16 = 600, @fullscreen = false, @cursor_visible = false)
    @input = Input.new self
    @primary_monitor = Glfw.get_primary_monitor

    Glfw.window_hint(Glfw::VISIBLE, @visible = false)
    Glfw.window_hint(Glfw::CLIENT_API, Glfw::NO_API) # Graphics are handled by wgpu
    @handle = Glfw.create_window(@width, height, @title, @fullscreen ? Glfw.get_primary_monitor : Pointer(Void).null, nil)
    abort("Failed to initialize a new GLFW Window", 1) if @handle.null?
  end

  def startup
    @surface = Platform.create_surface @title, @handle
    abort("Failed to create graphics surface", 1) unless @surface.not_nil!.is_valid?
    puts "Created native graphics surface"
  end

  def size : RenderLoop::Size
    Glfw.get_window_size @handle, out width, out height
    {@width = width, @height = height}
  end

  def size(s : RenderLoop::Size)
    Glfw.set_window_size @handle, @width = s[0], @height = s[1]
  end

  def fullscreen?
    @fullscreen
  end

  def visible?
    @visible
  end

  def swap_chain_descriptor(adapter : WGPU::Adapter)
    surface = @surface.not_nil!
    abort("Window surface is not valid", 1) unless surface.is_valid?
    future { SwapChainDescriptor.from_window self, surface.preferred_format(adapter).get }
  end

  def should_close? : Bool
    Glfw.window_should_close(@handle) == Glfw::TRUE
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
    raise "Window input is nil" if @input.nil?
    @input.as(Input)
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
