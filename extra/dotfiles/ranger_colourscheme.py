from ranger.colorschemes.default import Default
from ranger.gui.color import BRIGHT, magenta


class Scheme(Default):
    def use(self, context):
        fg, bg, attr = Default.use(self, context)

        # Show the selected item as reversed bright magenta.
        if context.in_browser and context.main_column and context.selected:
            fg = BRIGHT + magenta

        return fg, bg, attr
