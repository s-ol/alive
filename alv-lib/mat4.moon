import Constant, T, Array, PureOp, any from require "alv.base"

unpack or= table.unpack

vec3 = Array 3, T.num
vec4 = Array 4, T.num
mat4 = Array 4, vec4

identity = Constant.meta
  meta:
    name: 'identity'
    summary: "The identity Matrix."

  value: mat4\mk_const {
    { 1, 0, 0, 0 }
    { 0, 1, 0, 0 }
    { 0, 0, 1, 0 }
    { 0, 0, 0, 1 }
  }

scale = Constant.meta
  meta:
    name: 'scale'
    summary: "Create a 3d scale matrix."
    examples: { "(mat4/scale scale)", "(mat4/scale x y z)" }
    description: "This is a pure op.

`scale` can be a single number for uniform scaling, or an array
of three numbers that will be used like `x`, `y` and `z`."

  value: class extends PureOp
    pattern: any.num / (any.num\rep 3, 3) / any(vec3)
    type: mat4
    tick: =>
      scale = @unwrap_all! 
      x, y, z = if "number" == type scale
        scale, scale, scale
      else
        unpack scale

      @out\set {
        { x, 0, 0, 0 }
        { 0, y, 0, 0 }
        { 0, 0, z, 0 }
        { 0, 0, 0, 1 }
      }

translate = Constant.meta
  meta:
    name: 'translate'
    summary: "Create a 3d translation matrix."
    examples: { "(mat4/translate vec)", "(mat4/translate x y z)" }
    description: "This is a pure op.

`vec` is a num[3] array."

  value: class extends PureOp
    pattern: (any.num\rep 3, 3) / any(vec3)
    type: mat4
    tick: =>
      { x, y, z } = @unwrap_all! 

      @out\set {
        { 1, 0, 0, 0 }
        { 0, 1, 0, 0 }
        { 0, 0, 1, 0 }
        { x, y, z, 1 }
      }

rotate = Constant.meta
  meta:
    name: 'rotate'
    summary: "Create a 3d rotation matrix from an axis and angle"
    examples: { "(mat4/translate axis angle)" }
    description: "This is a pure op.

`axis` is a num[3] array representing a unit vector."

  value: class extends PureOp
    pattern: any(vec3) + any.num
    type: mat4
    tick: =>
      { { l, m, n }, a } = @unwrap_all! 

      len = math.sqrt l*l + m*m + n*n
      l, m, n = l/len, m/len, n/len

      ca, sa = (math.cos a), math.sin a
      na = 1 - ca

      @out\set {
        {
          l * l * na + ca
          l * m * na + n * sa
          l * n * na - m * sa
          0
        }
        {
          m * l * na - n * sa
          m * m * na + ca
          m * n * na + l * sa
          0
        }
        {
          n * l * na + m * sa
          n * m * na - l * sa
          n * n * na + ca
          0
        }
        { 0, 0, 0, 1 }
      }

ypr = Constant.meta
  meta:
    name: 'yaw-pitch-roll'
    summary: "Create a 3d rotation matrix from euler angles."
    examples: { "(yaw-pitch-roll vec3)", "(yaw-pitch-roll y p r)" }
    description: "This is a pure op."

  value: class extends PureOp
    pattern: (any.num\rep 3, 3) / any(vec3)
    type: mat4
    tick: =>
      { yaw, pitch, roll } = @unwrap_all! 
  
      ch, sh = math.cos(yaw),   math.sin yaw
      cp, sp = math.cos(pitch), math.sin pitch
      cb, sb = math.cos(roll),  math.sin roll

      @out\set {
        {
          ch * cb + sh * sp * sb
          sb * cp
          ch * sp * sb - sh * cb
          0
        }
        {
          sh * sp * cb - ch * sb
          cb * cp
          sb * sh + ch * sp * cb
          0
        }
        { sh * cp, -sp, ch * cp, 0 }
        { 0, 0, 0, 1 }
      }

Constant.meta
  meta:
    name: 'mat4'
    summary: "Operators for generating 4x4 Matrices."

  value:
    :identity
    :scale
    :translate
    :rotate
    'yaw-pitch-roll': ypr
    '*': mul
