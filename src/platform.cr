require "glfw"
require "wgpu"

module Platform
  def self.create_surface(name : String, window : Glfw::Window*) : WGPU::Surface
    {% if flag?(:apple) %}
      metal_layer = LibPlatform.get_metal_layer Glfw.get_cocoa_window(window)
      return WGPU::Surface.from_metal_layer("#{name} Metal Layer", metal_layer)
    {% end %}
    {% if flag?(:linux) %}
      return WGPU::Surface.from_xlib("#{name} X11 Window", get_x11_display, get_x11_window(window))
    {% else %}
      raise "Unsupported platform!"
    {% end %}
  end
end

{% if flag?(:apple) %}
  @[Link("glfw3")]
  lib Glfw
    fun get_cocoa_window = glfwGetCocoaWindow(Glfw::Window*) : Void*;
  end

  @[Link(framework: "Cocoa")]
  @[Link(framework: "QuartzCore")]
  lib LibPlatform
    fun get_metal_layer = bismuthPlatformGetMetalLayer(LibObjC::Id) : LibObjC::Id
  end

  @[Link("objc")]
  lib LibObjC
    alias Id = Void*
  end
{% end %}

{% if flag?(:linux) %}
  lib X11
    alias Display = Void*
    alias Window = UInt32
  end

  @[Link("glfw3")]
  lib Glfw
    fun get_x11_display = glfwGetX11Display() : X11::Display
    fun get_x11_window = glfwGetX11Window(Glfw::Window*) : X11::Window
  end
{% end %}

# TODO: fun get_win32_window = glfwGetWin32Window(Glfw::Window*) : HWND
