"""Sub/Superscipt extension for Markdown.

Imitates TeX style sub/super-script syntax

a^{b}  and a_{b}  creates super & sub script respectively

Examples:

>>> import markdown
>>> md = markdown.Markdown(extensions=['superscript'])
>>> md.convert('This is a reference to a footnote^{1}.')
u'<p>This is a reference to a footnote<sup>1</sup>.</p>'

>>> md.convert('This is a reference to a footnote_{1}.')
u'<p>This is a reference to a footnote<sub>1</sub>.</p>'

"""

import markdown

# Global Vars
SUPERSCRIPT_RE = r'([\^_])\{([^\}]+)\}'  # the number is a superscript^{2} or subscript_{2}

class SuperscriptPattern(markdown.inlinepatterns.Pattern):
    """ Return a superscript or subscript Element (`word^{2} or word_{2}`). """
    def handleMatch(self, m):

        tagname = "sup" if m.group(2)=="^" else "sub"
        supr = m.group(3)
        text = supr

        el = markdown.etree.Element(tagname)
        el.text = markdown.AtomicString(text)
        return el

class SuperscriptExtension(markdown.Extension):
    """ Superscript Extension for Python-Markdown. """

    def extendMarkdown(self, md, md_globals):
        """ Replace superscript with SuperscriptPattern """
        md.inlinePatterns['superscript'] = SuperscriptPattern(SUPERSCRIPT_RE, md)

def makeExtension(configs=None):
    return SuperscriptExtension(configs=configs)

if __name__ == "__main__":
    import doctest
    doctest.testmod()
