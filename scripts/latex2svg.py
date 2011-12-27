import os, subprocess, tempfile
import optparse
from jinja2 import Environment, FileSystemLoader, Template

SCALE=1.5

DISPLAY_TEMPLATE = '''
\documentclass[border=5pt]{standalone}
\usepackage{amsfonts,amssymb,amsmath}
\\begin{document}
\[
{{eq}}
\]
\end{document}
'''
INLINE_TEMPLATE = """
\documentclass[border=5pt]{standalone}
\usepackage{amsfonts,amssymb,amsmath}
\begin{document}
${{eq}}$
\end{document}
"""

def renderEq(fname, inline, scale):
    #env = Environment(loader=FileSystemLoader('./'))
    #template = env.get_template('display_eq.j2')
    if inline:
        template = Template(INLINE_TEMPLATE)
    else:
        template = Template(DISPLAY_TEMPLATE)

    eq_str = open(fname,'r').read()
    print eq_str

    out_str = template.render(eq=eq_str[:-1])
    print out_str

    outfile=open('/var/tmp/eq_render.tex','w')
    outfile.write(out_str)
    outfile.close()

#def call_latex():
    #call latex to convert tex->dvi
    subprocess.call(["latex","--output-directory=/var/tmp/","/var/tmp/eq_render.tex"])

#def call_dvi2svg():
    #call dvi2svgm to convert dvi->svg
    subprocess.call(["dvisvgm","-a","-e","-n","-c"+str(scale)+","+str(scale), "/var/tmp/eq_render.dvi", "--output=eq_render.svg"])

def main():
    parser = optparse.OptionParser()
    parser.add_option('-i','--inline', action="store_true", default=False)
    parser.add_option('-s','--scale', action="store", type="float", default=1.0)
    options, remainder = parser.parse_args()

    #print options
    #print remainder

    renderEq(remainder[0],options.inline, options.scale)

if __name__ == "__main__":
    main()
