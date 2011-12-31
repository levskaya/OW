# -*- coding: utf-8 -*-
"""
Contains code to render latex to png/svg server-side in hyde
"""
from hyde import loader

from hyde.plugin import Plugin

from hyde.exceptions import HydeException
from hyde.fs import File, Folder
from hyde.util import getLoggerWithNullHandler, first_match, discover_executable
from hyde.model import Expando

#from functools import partial
import fnmatch

import os
import re
import subprocess
import traceback
import sys
import tempfile

from sha import sha

def sha_hash(str):
    "get sha1 digest of string"
    return sha(str).hexdigest()


# Default packages to use when generating output
default_packages = [
        'amsmath',
        'amsthm',
        'amssymb',
        'bm'
        ]

def __build_preamble(packages):
    preamble = '\documentclass{article}\n'
    for p in packages:
        preamble += "\usepackage{%s}\n" % p
    preamble += "\pagestyle{empty}\n\\begin{document}\n"
    return preamble

def __write_output(infile, outdir, workdir = '.', prefix = '', size = 1):
    try:
        # Generate the DVI file
        latexcmd = 'latex -halt-on-error -output-directory %s %s'\
                % (workdir, infile)
        rc = os.system(latexcmd)
        # Something bad happened, abort
        if rc != 0:
            raise Exception('latex error')

        # Convert the DVI file to PNG's
        dvifile = infile.replace('.tex', '.dvi')
        outprefix = os.path.join(outdir, prefix)
        dvicmd = "dvipng -T tight -x %i -z 9 -bg Transparent "\
                "-o %s.png %s" % (size * 1000, outprefix, dvifile)
        rc = os.system(dvicmd)
        if rc != 0:
            raise Exception('dvipng error')
    finally:
        # Cleanup temporaries
        basefile = infile.replace('.tex', '')
        tempext = [ '.aux', '.dvi', '.log' ]
        for te in tempext:
            tempfile = basefile + te
            if os.path.exists(tempfile):
                os.remove(tempfile)

def math2png(eq, outdir, packages = default_packages, prefix = '', size = 1, inline=True, nobrackets=False):
    """
    Generate png images from $...$ style math environment equations.

    Parameters:
        eqs         - A list of equations
        outdir      - Output directory for PNG images
        packages    - Optional list of packages to include in the LaTeX preamble
        prefix      - Optional prefix for output files
        size        - Scale factor for output
    """
    try:
        # Set the working directory
        workdir = tempfile.gettempdir()

        # Get a temporary file
        fd, texfile = tempfile.mkstemp('.tex', 'eq', workdir, True)

        # Create the TeX document
        with os.fdopen(fd, 'w+') as f:
            f.write(__build_preamble(packages))
            print __build_preamble(packages)
            if inline:
                f.write("$%s$\n" % eq)
                print "$%s$\n" % eq
            else:
                if nobrackets: #for things like \begin{eqnarray}
                    f.write("%s\n" % eq)
                    print "%s\n" % eq
                else:
                    f.write("\\[\n%s\n\\]\n" % eq)
                    print "\\[\n%s\n\\]\n" % eq
            f.write('\end{document}')
            print '\end{document}'

        __write_output(texfile, outdir, workdir, prefix, size)
    finally:
        if os.path.exists(texfile):
            os.remove(texfile)

#re.compile(r'(?<!\\)(\$\$?)(.+?)\1')
#re.compile(r'(\$)(.+?(?:\n.+?)?)\1')
#re.compile(r'(?<!\$)(?:\$)(?!\$)(.+?(?:\n.+?)?)(?<!\$)(?:\$)(?!\$)')

class LatexRenderPlugin(Plugin):
    """
    finds latex regions in page, then renders png/svg to media/latex directory using
    sha1 hashes of latex string to prevent reprocessing / unique referrals
    """

    def __init__(self, site):
        super(LatexRenderPlugin, self).__init__(site)
        config = getattr(site.config, self.plugin_name, None)

    @property
    def plugin_name(self):
        """
        The name of the plugin. Makes an intelligent guess.
        """
        return self.__class__.__name__.replace('Plugin', '').lower()

    @property
    def tex_image_dir(self):
        """
        The default directory to place rendered images
        """
        return "media/images/tex"

    @property
    def inline_regex(self):
        """
        The default pattern for inline elements
        """
        return re.compile(r'(?<!\$)(?:\$)(?!\$)(.+?)(?<!\$)(?:\$)(?!\$)')

    @property
    def display_regex(self):
        """
        The default pattern for display elements.
        """
        return re.compile(r'(?:\$\$)(.+?)(?:\$\$)',re.DOTALL)

    @property
    def nobrackets_regex(self):
        """
        The pattern for detecting when not to insert \[ \] pairs in display mode.
        """
        # A hack to deal with \begin{eqnarray} which can't be placed inside of \[ \] pairs,
        # MathJax automagically deals with this, I'm not sure how many other danger elements there are like this in LaTeX math environments.
        return re.compile(r'\\begin\{eqnarray')

    def begin_text_resource(self, resource, text):
        """
        """
        if not resource.source_file.kind == 'html':
            return text

        #print "file: ", unicode(resource.source_file)

        target = Folder(self.site.config.deploy_root_path.child(self.tex_image_dir))
        #print "target: ", str(target)

        inlinematches = self.inline_regex.findall(text)
        for eq in inlinematches:
            #print "inline: ", eq
            stripped_eq = eq.rstrip().lstrip()
            sha1hash = sha_hash(stripped_eq)
            if not os.path.exists(str(target)+"/"+sha1hash+".png"):
                math2png(stripped_eq, str(target), packages = default_packages, prefix = sha1hash, size = 1,inline=True)

        displaymatches = self.display_regex.findall(text)
        for eq in displaymatches:
            #print "display: ", eq
            stripped_eq = eq.rstrip().lstrip()
            if len(self.nobrackets_regex.findall(stripped_eq))>0:
                eqnarraypresent = True
            else:
                eqnarraypresent = False
            sha1hash = sha_hash(stripped_eq)
            if not os.path.exists(str(target)+"/"+sha1hash+".png"):
                math2png(stripped_eq, str(target), packages = default_packages, prefix = sha1hash, size = 1,inline=False, nobrackets=eqnarraypresent)

        # the text itself is unchanged
        return text
