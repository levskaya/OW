"""
makes margin note markup

"""
import markdown

# Global Vars
MARGINALIA_RE = r'\.\.\.\((.+?)\)\.\.\.'  # ...( margin note )...

class MarginaliaPattern(markdown.inlinepatterns.Pattern):
    """ Return a margin note span marker and element. """
    def handleMatch(self, m):

        supr = m.group(2)        
        text = supr
        
        el = markdown.etree.Element("span")
        el.set('class',"marginmarker hidden")
        #el2 = markdown.etree.SubElement(el,"span")
        #el2.set('class',"hidden marginnote")
        el.text = text
        return el

class MarginaliaExtension(markdown.Extension):
    """ Marginalia Extension for Python-Markdown. """

    def extendMarkdown(self, md, md_globals):
        """ Replace superscript with MarginaliaPattern """
        md.inlinePatterns['marginalia'] = MarginaliaPattern(MARGINALIA_RE, md)

def makeExtension(configs=None):
    return MarginaliaExtension(configs=configs)

if __name__ == "__main__":
    import doctest
    doctest.testmod()












