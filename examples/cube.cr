require "../src/bismuth.cr"
require "../src/math.cr"

class Assets
  # FIXME: Switch to baked file system
  # extend BakedFileSystem
  # bake_folder "./assets"
  private CUBE_SHADER = `cat #{__DIR__}/assets/cube.wgsl`

  def self.shader
    CUBE_SHADER
  end
end

struct PositionColor
  @x = 0_f32
  @y = 0_f32
  @z = 0_f32
  @r = 0_f32
  @g = 0_f32
  @b = 0_f32
  @a = 1_f32

  def position
    Vector3.new(@x, @y, @z)
  end

  def color
    Vector4.new(@r, @g, @b, @a)
  end

  def self.vertex_attributes
    [
      WGPU::VertexAttribute.new(
        format: WGPU::VertexFormat::Float32x3,
        offset: offsetof(PositionColor, @x),
        shader_location: 0,
      ),
      WGPU::VertexAttribute.new(
        format: WGPU::VertexFormat::Float32x4,
        offset: offsetof(PositionColor, @r),
        shader_location: 1,
      ),
    ]
  end
end

class Cube < App
  @pipeline : WGPU::RenderPipeline?
  @command_buffer : WGPU::CommandBuffer?
  @cube_vertices : WGPU::Buffer?
  @cube_indices : WGPU::Buffer?

  def initialize
    super("Cube")
  end

  # TODO: Render a cube

  protected def startup
    # FIXME: This next line panics
    @cube_vertices = @device.create_buffer WGPU::BufferDescriptor.new(
      usage : WGPU::BufferUsage::MapWrite | WGPU::BufferUsage::Vertex,
      size: sizeof(PositionColor) * 8,
      mapped_at_creation: true,
    )
    abort("Could not create vertex buffer", 1) unless @cube_vertices.not_nil!.is_valid?
    @cube_vertices.not_nil!.map_write_async(0, @cube_vertices.not_nil!.size)

    @cube_indices = @device.create_buffer WGPU::BufferDescriptor.new(
      usage : WGPU::BufferUsage::MapWrite | WGPU::BufferUsage::Index,
      size: 6 * 6 * sizeof(UInt16),
      mapped_at_creation: true,
    ).not_nil!
    abort("Could not create index buffer", 1) unless @cube_indices.not_nil!.is_valid?
    @cube_indices.not_nil!.map_write_async(0, @cube_indices.not_nil!.size)

    vertex_attributes = PositionColor.vertex_attributes
    vertex_layout = WGPU::VertexBufferLayout.new(
      array_stride: UInt64.new(sizeof(PositionColor)),
      step_mode: WGPU::InputStepMode::Vertex,
      attribute_count: vertex_attributes.size,
      attributes: vertex_attributes.to_unsafe,
    )

    @shader = WGPU::ShaderModule.from_wgsl(@device, Assets.shader)
    abort("Could not compile shader", 1) if @shader.nil? || (@shader.not_nil!.is_valid? == false)

    pipeline_layout = WGPU::PipelineLayout.empty @device
    pipeline_label = "Render pipeline"
    @pipeline = @device.create_render_pipeline WGPU::RenderPipelineDescriptor.new(
      label: pipeline_label,
      layout: pipeline_layout,
      vertex: WGPU::VertexState.from(@shader.not_nil!, entry_point: "vs_main"),
      primitive: WGPU::PrimitiveState.new(
        topology: WGPU::PrimitiveTopology::TriangleList,
        strip_index_format: WGPU::IndexFormat::Undefined,
        front_face: WGPU::FrontFace::CCW,
        cull_mode: WGPU::CullMode::None
      ),
      multisample: WGPU::MultisampleState.new(
        count: 1,
        mask: ~0,
        alpha_to_coverage_enabled: false,
      ),
      fragment: WGPU::FragmentState.new(
        @shader.not_nil!,
        entry_point: "fs_main",
        targets: [
          WGPU::ColorTargetState.new(
            format: @main_window.swap_chain.not_nil!.format,
            blend: WGPU::BlendState.new(
              color: WGPU::BlendComponent::SRC_ONE_DST_ZERO_ADD,
              alpha: WGPU::BlendComponent::SRC_ONE_DST_ZERO_ADD
            ),
            write_mask: WGPU::ColorWriteMask::All
          ),
        ],
      ),
      depth_stencil: nil,
    )
  end

  protected def tick(tick : Tick)
  end

  protected def render(window : Window)
    next_texture = window.swap_chain.not_nil!.current_texture_view
    raise "Could not acquire next swap chain texture" unless next_texture.is_valid?

    encoder = @device.create_command_encoder(WGPU::CommandEncoderDescriptor.new)
    color_attachment = WGPU::RenderPassColorAttachmentDescriptor.new(
      attachment: next_texture,
      resolve_target: WGPU::TextureView.null,
      load_op: WGPU::LoadOp::Clear,
      store_op: WGPU::StoreOp::Store,
      clear_color: WGPU::Colors::GREEN
    )
    render_pass = encoder.begin_render_pass(WGPU::RenderPassDescriptor.new(
      color_attachments: pointerof(color_attachment),
      color_attachment_count: 1,
      depth_stencil_attachment: nil
    ))

    render_pass.pipeline = @pipeline.not_nil!
    render_pass.draw(3, 1, 0, 0)
    render_pass.end_pass

    @command_buffer = encoder.finish
    raise "Could not finish recording command buffer" unless @command_buffer.not_nil!.is_valid?
    @device.queue.submit @command_buffer.not_nil!
  end
end

Cube.new.run
