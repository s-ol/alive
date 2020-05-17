As mentioned earlier, `alv` doesn't produce sound by itself. Instead, it is
paired with other tools, and takes the role of a 'Conductor', sending commands
and sequencing other tools.

For the sake of this guide, we will be controlling [Pilot][pilot], a simple
UDP-controlled synthesizer. You can go ahead and download and open it now.
You should see a small window with a bunch of cryptic symbols and a little
command line at the bottom. To verify that everything is working so far,
try typing in `84c` and hitting enter. This should play a short sound (the note
4C, played by the 8th default synthesizer voice in Pilot).

To talk to Pilot from `alv`, we will use the [pilot/][] module. Note that for
this module to work, you have to have the `osc` and `luasocket` dependencies
installed. To play the same sound we played by entering `84c` above every 0.5
seconds, we can use [time/every][] to send a `bang` to [pilot/play][]:

    (import* time)
    (import pilot)
    (pilot/play (every 0.5) 8 4 'c')

You can play with the voice, octave and note values a bit. To add a simple
melody, we can use [util/switch][], which will cycle through a list of
parameters when used together with [time/tick][]:

    (import* time util)
    (import pilot)
    (pilot/play (every 0.5) 8 4
      (switch (tick 0.5) 'c' 'd' 'a' 'f'))

Now we can have the voice change every other loop as well:

    (import* time util)
    (import pilot)
    (pilot/play (every 0.5)
      (switch (tick 4) 8 9)
      4 (switch (tick 0.5) 'c' 'd' 'a' 'f'))

To round off the sound a bit, we can turn on Pilot's reverb using
[pilot/effect][]. Add the following somewhere in your file:

    (pilot/effect "REV" 2 8)

Now it's time to add some rhythm. The kick drum is voice 12 by default,
and we can also add something like a snare on channel 3:

    (pilot/play (every 0.75)
      12 2 'd' 3)
    (pilot/play (every 2)
      13 4 'a' 4)

Note that since we are using multiple individual [time/every][] instances,
the timing of our voices relative to each other is not aligned - each voice
started playing when the file was first saved with it added, and kept the
rhythmn since. By deleting all their tags and re-saving the file, we can force
`alv` to re-instantiate them all at the same time, thereby synchronising
them.

[pilot]: https://github.com/hundredrabbits/Pilot
