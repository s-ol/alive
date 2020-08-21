[if][] can be used to make choices at evaltime. It takes an evaltime constant
boolean as its first argument and then either evaluates its second argument
(the 'then' expression, if the condition was truthy) or its third argument
(the 'else' expression, if it wasn't). The 'else' expression can be omitted if
it is not needed.

    (def print-first true)
    (print (if print-first
      "First!"
      "Second :("))
    
    #(prints nothing)
    (if false
      (print "Another message"))

If multiple expressions (with side effects) need to be switched, [when][] can
be used instead: it evaluates all arguments as a block, only if the condition
is truthy:

    (def enable-things true)
    
    (when enable-things
      (print "the things are enabled.")
      (print "they should happen soon.")
      (print "thank you for enabling them."))

This is equivalent to using a [do][] block inside the [if][] expression:

    (def enable-things true)
    
    (if enable-things
      (do
        (print "the things are enabled.")
        (print "they should happen soon.")
        (print "thank you for enabling them.")))
