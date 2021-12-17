require "../src/bismuth.cr"

class Assets
  # FIXME: Switch to baked file system
  # extend BakedFileSystem
  # bake_folder "./lib/wgpu/examples/assets/triangle"
  private TRIANGLE_SHADER = `cat #{__DIR__}/../lib/wgpu/examples/assets/triangle/shader.wgsl`

  def self.shader
    TRIANGLE_SHADER
  end
end

class Triangle < App
  @pipeline : WGPU::RenderPipeline?
  @command_buffer : WGPU::CommandBuffer?

  def initialize
    super("Triangle")
  end

  # TODO: Render a triangle

  protected def startup
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

Triangle.new.run
