While it is possible to simply run finished programs as we just did with the
`hello.alv` example, `alv` is a *livecoding language*, which means that it is
designed so that programs can be written interactively while they are already
running. To see how this works, let's re-write the `hello.alv` example
step-by-step.

First you will need an empty file to start from. Open a new file in your
preferred text editor and save it as `test.alv`. Before adding any code, start
the copilot (see the last page on the two ways of doing that).

    $ alv test.alv
    changes to files: test.alv
    
You should see a note indicating that `alv` processed the file. The note will
show up in the upper pane labelled `eval` (in the GUI), or colored green (in
the terminal). This marks the message as an *eval-time message*, meaning that
the message was printed as a direct response to the file changing or being
loaded the first time. Other messages that might print to the `eval` section
are things like errors in your program, and one-time debugging messages. 

Now that the copilot is running, whenever you change `test.alv` and save it, the
copilot will reload it and execute your new code. When you are done, you can
stop the copilot at any time by closing the GUI window or pressing `^C`
(control-C) in the terminal.

Let's start with a simple operator, [print][]: [print][] is used simply to print
messages to the copilot console. Enter the following in your file and save it:

    (print "hello world!")

As soon as you save the file, you should notice two things happening:

1. The copilot will print two new lines:

       changes to files: hello.alv
       hello world!

   In the first line, it notifies us that the file has changed. In the second
   line, you can see the output from the [print][] expression.
2. The copilot will make a small modification to your file. Depending on the
   editor you are using, this may either result in you seeing the modification
   immediately, or a notice appearing that offers the option to reload the
   file. If it is the latter, confirm the notification to accept the changes.
   If there is an option to do so, you may want to configure your editor to
   always reload the file automatically.

The code should now look like this:

    ([1]print "hello world")

The `[1]` that the copilot added to your expression is that expression's `tag`.
In `alv`, every expression has a tag that helps the copilot to identify the
individual expressions as you make changes to your code. The copilot will make
sure that all expressions are tagged by adding missing tags when you save the
file, but you have to watch out not to duplicate a tag when copying and pasting
code. When you duplicate code that already has tags, you can either manually
change the tags to be unique, or simply delete the whole tag (including the
square brackets) and let the copilot generate a new one for you the next time
you save the file.
