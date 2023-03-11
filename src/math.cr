struct Vector2
  property x, y

  def initialize(@x : Float32, @y : Float32)
  end
end

struct Vector3
  property x, y, z

  def initialize(@x : Float32, @y : Float32, @z : Float32)
  end
end

struct Vector4
  property x, y, z, w

  def initialize(@x : Float32, @y : Float32, @z : Float32, @w : Float32)
  end
end
