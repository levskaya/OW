Ontological Warfare Code
------------------------

This is the collection of python, java-/coffee-script, math, design
files, etc. that constitutes the code and media necessary to generate
my online content at [Ontological Warfare][ow].

It uses Hyde with some rough-hewn custom extensions.  An extended
Markdown is used with a few extra extensions.  A few jinja2 filters
were written for transformation of content into full-feed
RSS-appropriate forms for feedreaders.

This site is:

- assembled by the static generator [Hyde][hyde].
- uses the [Bootstrap][bootstrap] less/css library from Twitter for layout.
- uses [MathJax][mathjax] to render mathematics dynamically.
- uses [coffeescript][coffee], jQuery, [D3][d3], and many other libraries for the frontend.

All the original text and imagery on this site is released under the [CCBY][ccby] license.

All original code found herein is released under the [MIT][mit] License.

Please let [me][al] know if you find anything in here of interest or
utility!  Naturally it's a bricolage of hacks that work for me, but
perhaps something in here is of more general interest.

Dependencies
------------

In addition to the Hyde dependencies, this requirs a working TeX
install w. dvipng for autoconverting the TeX elements to PNGs for RSS
feeds.  There are custom extensions to Hyde (esp. its Jinja2 template
plugin) and to Markdown that need to be emplaced.

TODO
-----

- improve CSS for iphone / ipad viewing, maybe a separate CSS file
  altogether?
- static tex image generator doesn't make it's own directory
- markdown footnote urls are full-urls, not local, which makes them
  useless in RSS feeds

[hyde]: https://github.com/hyde/hyde
[bootstrap]: https://github.com/twitter/bootstrap
[mathjax]: https://github.com/mathjax/MathJax
[ccby]: http://creativecommons.org/licenses/by/3.0/
[mit]: http://www.opensource.org/licenses/mit-license.php
[d3]: http://mbostock.github.com/d3/
[owgh]: https://github.com/levskaya/OW
[coffee]: http://jashkenas.github.com/coffee-script/
[ow]: http://ontologicalwarfare.com
[al]: http://anselmlevskaya.com
