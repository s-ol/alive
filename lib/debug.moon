import Op from require 'base'

class out extends Op
  setup: (name, @chld) =>
    @name = name\getc!

  update: =>
    print "#{@name} << ", @chld\get!

{
  :out
}
