Ontological Warfare Code
------------------------

This is the sundry collection of python, java-/coffee-script, math,
design files, etc. that constitutes the code and media necessary to generate my online content.

It uses Hyde with custom extensions.  An extended Markdown is used.

CC-BY-SA

TODO
-----

FIX the RSS feed mechanism, this basically needs an entirely separate
build tree to produce static files (svg/png) of dynamic content - at
the very least mathjax elements into PNGs.

- map margin notes to footnotes (inline w. other footnotes, so first
convert to markdown footnotes format, then allow the rest of processing to occur)
- render tex fragments to svg/png
- other weird visual shit needs to have a static img representation such that some small part of it can go out to
   rss readers, this is simplest to simply do manually w. a
   screenshot, frankly.  Although some of it could in theory be done
   for d3/canvas visual tricks using Phantom.js though only after a
   lot of hacking!
