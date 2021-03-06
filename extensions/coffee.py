# -*- coding: utf-8 -*-
"""
coffeescript plugin
"""

from hyde.plugin import CLTransformer
from hyde.fs import File

import re
import subprocess


class CoffeeScriptPlugin(CLTransformer):
    """
    The plugin class for less css
    """

    def __init__(self, site):
        super(CoffeeScriptPlugin, self).__init__(site)

    @property
    def executable_name(self):
        return "coffee"

    def _should_parse_resource(self, resource):
        """
        Check user defined
        """
        return getattr(resource, 'meta', {}).get('parse', True)

    def _should_replace_imports(self, resource):
        return getattr(resource, 'meta', {}).get('uses_template', True)

    def begin_site(self):
        """
        Find all the coffee files and set their relative deploy path.
        """
        for resource in self.site.content.walk_resources():
            if resource.source_file.kind == 'coffee': #and \
                #self._should_parse_resource(resource):
                new_name = resource.source_file.name_without_extension + ".js"
                target_folder = File(resource.relative_deploy_path).parent
                resource.relative_deploy_path = target_folder.child(new_name)
                resource.uses_template==False

    def begin_text_resource(self, resource, text):
        """
        Replace @import statements with {% include %} statements.
        """

        if True:
            return text
        #if not resource.source_file.kind == 'coffee' or not \
        #    self._should_parse_resource(resource) or not \
        #    self._should_replace_imports(resource):
        #    return text

        import_finder = re.compile(
                            '^\\s*@import\s+(?:\'|\")([^\'\"]*)(?:\'|\")\s*\;\s*$',
                            re.MULTILINE)

        def import_to_include(match):
            if not match.lastindex:
                return ''
            path = match.groups(1)[0]
            afile = File(resource.source_file.parent.child(path))
            if len(afile.kind.strip()) == 0:
                afile = File(afile.path + '.coffee')
            ref = self.site.content.resource_from_path(afile.path)
            if not ref:
                raise self.template.exception_class(
                        "Cannot import from path [%s]" % afile.path)
            ref.is_processable = False
            return self.template.get_include_statement(ref.relative_path)
        text = import_finder.sub(import_to_include, text)
        return text

    @property
    def plugin_name(self):
        """
        The name of the plugin.
        """
        return "coffee"

    def text_resource_complete(self, resource, text):
        """
        Save the file to a temporary place and run coffee compiler.
        Read the generated file and return the text as output.
        Set the target path to have a js extension.
        """
        if not resource.source_file.kind == 'coffee': #or not \
            #self._should_parse_resource(resource):
            return

        # altering this method a bit:
        # coffee compiler can't target a specific _file_, so we must capture stdout

        #supported = [
        #    "p",
        #    "c"
        #]

        coffee = self.app
        source = File.make_temp(text)
        args = [unicode(coffee)]
        args.extend(["-p","-c", unicode(source)])
        try:
            #self.call_app(args)
            p=subprocess.Popen(args, stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        except subprocess.CalledProcessError:
             raise self.template.exception_class(
                    "Cannot process %s. Error occurred when "
                    "processing [%s]" % (self.app.name, resource.source_file))
        return p.communicate()[0] #(stdout, stderr)
