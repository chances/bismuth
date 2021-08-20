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
  @swap_chain : WGPU::SwapChain
  @pipeline : WGPU::RenderPipeline?
  @command_buffer : WGPU::CommandBuffer?

  def initialize
    super("Triangle")

    @swap_chain = @device.create_swap_chain @main_window.surface.not_nil!, @main_window.swap_chain_descriptor(@adapter).get
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
      primitive: LibWGPU::PrimitiveState.new(
        topology: LibWGPU::PrimitiveTopology::TriangleList,
        strip_index_format: LibWGPU::IndexFormat::Undefined,
        front_face: LibWGPU::FrontFace::CCW,
        cull_mode: LibWGPU::CullMode::None
      ),
      multisample: LibWGPU::MultisampleState.new(
        count: 1,
        mask: ~0,
        alpha_to_coverage_enabled: false,
      ),
      fragment: WGPU::FragmentState.new(
        @shader.not_nil!,
        entry_point: "fs_main",
        targets: [
          LibWGPU::ColorTargetState.new(
            format: @swap_chain.format,
            blend: WGPU::BlendState.new(
              color: WGPU::BlendComponent::SRC_ONE_DST_ZERO_ADD,
              alpha: WGPU::BlendComponent::SRC_ONE_DST_ZERO_ADD
            ),
            write_mask: LibWGPU::ColorWriteMask::All
          ),
        ],
      ),
      depth_stencil: nil,
    )
  end

  protected def tick(tick : Tick)
  end

  protected def render
    next_texture = @swap_chain.current_texture_view
    raise "Could not acquire next swap chain texture" unless next_texture.is_valid?

    encoder = @device.create_command_encoder(LibWGPU::CommandEncoderDescriptor.new)
    color_attachment = LibWGPU::RenderPassColorAttachmentDescriptor.new(
      attachment: next_texture,
      resolve_target: LibWGPU::TextureView.null,
      load_op: LibWGPU::LoadOp::Clear,
      store_op: LibWGPU::StoreOp::Store,
      clear_color: WGPU::Colors::GREEN
    )
    render_pass = encoder.begin_render_pass(LibWGPU::RenderPassDescriptor.new(
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

  protected def flush
    @swap_chain.present
  end
end

Triangle.new.run
