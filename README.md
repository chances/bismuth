# Bismuth

A generic, bring your own framework/engine graphics library for games and visualizations.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     bismuth:
      github: chances/bismuth
   ```

2. Run `shards install`

## Usage

```crystal
require "bismuth"

# TODO: Write usage instructions here
```

See the [API documentation](https://chances.github.io/bismuth).

### Debian Linux

Required libraries:

- [`libvulkan-dev`](https://github.com/KhronosGroup/Vulkan-Loader)
- `mesa-vulkan-drivers`

#### For NVidia GPUs

- `nvidia-driver-470`

### Running Examples

#### Triangle

##### macOS

```shell
make bin/triangle.app
open bin/triangle.app
```

##### Linux

```shell
make bin/triangle
./bin/triangle
```

## Behind the Name

Bismuth germanium oxide is one of [many other piezoelectric materials](https://en.wikipedia.org/wiki/Crystal_oscillator#Other_materials) used as crystal oscillators.

> A crystal oscillator is an electronic oscillator circuit that uses the mechanical resonance of a vibrating crystal of piezoelectric material to create an electrical signal with a constant frequency.

<small>[Crystal oscillator](https://en.wikipedia.org/wiki/Crystal_oscillator), Wikipedia, 2021.</small>
