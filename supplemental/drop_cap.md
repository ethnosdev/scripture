# Drop cap implementation strategy

In order to show the chapter number in drop cap style, put all of the chapter numbers in a sprite sheet (png file). Then find the hight of a single word. Multiply that height by the number of lines to drop the chapter number. Resize the chapter number sprite to fit the desired height (will have to take into account the baseline position of the bottom line). Then based on the width of the resized sprite, indent the words for the first two lines (or however many lines the chapter number drops).

This is easier than trying to choose the correct font size because the visual size is different that the top and bottom of the glyph in the font metrics (due to the ascender and descender).