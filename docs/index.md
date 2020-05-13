# `alv` - livecoding with persistent expressions

`alv` (pronounced "alive") is a new type of programming environment and
language specifically designed for (live) performances where code is edited
while it is running, such as *livecoding* or *algorave* music performances.

<iframe class="embed" allowfullscreen="true" frameborder="0"
  height="315" width="560" src="https://www.youtube.com/embed/z0XZYnY3Evc"
></iframe>

Unlike other livecoding languages, programming with `alv` does not mean
evaluating separate pieces of code and sending individual commands to the
programming environment. Instead, you can keep editing the program as a whole
and whenever you save the file, `alv` will apply your changes to the running
system seamlessly, without resetting any part of your program (unless you want
it to).

`alv` is free and open source software. The code is currently being hosted
[on github][:*repo*:], and is licensed under [GPLv3][license].

If you want to learn more or try out `alv` yourself, the
[getting started][guide] page is a good place to start. On the other hand, if
you are a curious about the motivations and concepts behind `alv`, you can find
more in-depth information on these topics in the
['persistent expressions' article][rationale].

[guide]: guide.html
[rationale]: https://s-ol.nu/alivecoding
[license]: https://github.com/s-ol/alive/blob/master/LICENSE
