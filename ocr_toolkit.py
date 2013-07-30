#
# Copyright (C) 2009-2010 Rene Baston, Christoph Dalitz
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#

from gamera.core import * 
init_gamera()    
from gamera import knn   
from gamera.plugins import pagesegmentation
from gamera.classify import ShapedGroupingFunction
from gamera.plugins.image_utilities import union_images
from gamera.plugins.listutilities import median
from gamera.toolkits.ocr.classes import Textline
import unicodedata
import sys
import time

def return_char(unicode_str, extra_chars_dict={}):
  """Converts a unicode character name to a unicode symbol.

Signature:

    ``return_char (classname, extra_chars_dict={})``

with

    *classname*:
      A class name derived from a unicode character name.
      Example: ``latin.small.letter.a`` returns the character ``a``.
      
    *extra_chars_dict*
      A dictionary of additional translations of classnames to character codes.
      This is necessary when you use class names that are not unicode names.
      The character 'code' does not need to be an actual code, but can be
      any string. This can be useful, e.g. for ligatures:

    .. code:: Python

       return_char(glyph.get_main_id(), {'latin.small.ligature.st':'st'})

When *classname* is not listed in *extra_chars_dict*, it must correspond
to a `standard unicode character name`_,
as in the examples of the following table:

.. _`standard unicode character names`: http://www.unicode.org/charts/


+-----------+----------------------------+----------------------------+
| Character | Unicode Name               | Class Name                 |
+===========+============================+============================+
| ``!``     | ``EXCLAMATION MARK``       | ``exclamation.mark``       |
+-----------+----------------------------+----------------------------+
| ``2``     | ``DIGIT TWO``              | ``digit.two``              |
+-----------+----------------------------+----------------------------+
| ``A``     | ``LATIN CAPITAL LETTER A`` | ``latin.capital.letter.a`` |
+-----------+----------------------------+----------------------------+
| ``a``     | ``LATIN SMALL LETTER A``   | ``latin.small.letter.a``   |
+-----------+----------------------------+----------------------------+

"""
  if len(extra_chars_dict) > 0:
    try:
      return extra_chars_dict[unicode_str]      
    except:
      pass
  
  name = unicode_str.upper()  
  # some xml-files might be corrupted due to wrong grouping
  if name.startswith('_GROUP.'):
    name = name[len('_GROUP.'):]
  if name.startswith('_PART.'):
    name = name[len('_PART.'):]
  name = name.replace(".", " ")
  
  try:
    return unicodedata.lookup(name)
  except KeyError:
    strings = unicode_str.split(".")
    if(strings[0] == "collated"):
      return strings[1]
    if(strings[0] == "cursive"):
      return return_char(unicode_str[8:])
    else:
      print "ERROR: Name not found:", name
      return ""

 
def chars_make_words(lines_glyphs,threshold=None):
  """Groups the given glyphs to words based upon the horizontal distance
between adjacent glyphs.

Signature:
    ``chars_make_words (glyphs, threshold=None)``

with

    *glyphs*:
      A list of ``Cc`` data types, each of which representing a character.
      All glyphs must stem from the same single line of text.

    *threshold*:
      Horizontal white space greater than *threshold* will be considered
      a word separating gap. When ``None``, the threshold value is
      calculated automatically as 2.5 times teh median white space
      between adjacent glyphs.
  
The result is a nested list of glyphs with each sublist representing
a word. This is the same data structure as used in `Textline.words`_

.. _`Textline.words`: gamera.toolkits.ocr.classes.Textline.html
"""

  glyphs = lines_glyphs[:]
  wordlist = []
  
  if(threshold == None):
    spacelist = []
    total_space = 0
    for i in range(len(glyphs) - 1):
      spacelist.append(glyphs[i + 1].ul_x - glyphs[i].lr_x)
    if(len(spacelist) > 0):
      threshold = median(spacelist)
      threshold = threshold * 2.5
    else:
      threshold  = 0

  word = []
  for i in range(len(glyphs)):
    if i > 0:
      if((glyphs[i].ul_x - glyphs[i - 1].lr_x) > threshold):
        wordlist.append(word)
        word = []
    word.append(glyphs[i])

  if(len(word) > 0):
    wordlist.append(word)
  return wordlist

def textline_to_string(line, heuristic_rules="roman", extra_chars_dict={}):
  """Returns a unicode string of the text in the given ``Textline``.

Signature:

    ``textline_to_string (textline, heuristic_rules="roman", extra_chars_dict={})``

with

    *textline*:
      A ``Textline`` object containing the glyphs. The glyphs must already
      be classified.
      
    *heuristic_rules*:
      Depending on the alphabeth, some characters can very similar and
      need further heuristic rules for disambiguation, like apostroph and
      comma, which have the same shape and only differ in their position
      relative to the baseline.

      When set to \"roman\", several rules specific for latin alphabeths
      are applied.
    
    *extra_chars_dict*
      A dictionary of additional translations of classnames to character codes.
      This is necessary when you use class names that are not unicode names.
      Will be passed to `return_char`_.

As this function uses `return_char`_, the class names of the glyphs in
*textline* must corerspond to unicode character names, as described in
the documentation of `return_char`_.

.. _`return_char`: #return-char

"""
  wordlist = line.words
  s = ""
  char = ""
  for i in range(len(wordlist)):
    if(i):
      s = s + " "
    for glyph in wordlist[i]:
      char = return_char(glyph.get_main_id(), extra_chars_dict)
      if (heuristic_rules == "roman"):
        # disambiguation of similar roman characters
	if (char == "x" or char == "X"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.x")
          else:
            glyph.classify_heuristic("latin.small.letter.x")
	  char = return_char(glyph.get_main_id())

	if (char == "p" or char == "P"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.p")
          else:
            glyph.classify_heuristic("latin.small.letter.p")
	  char = return_char(glyph.get_main_id())

	if (char == "o" or char == "O"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.o")
          else:
            glyph.classify_heuristic("latin.small.letter.o")
	  char = return_char(glyph.get_main_id())

	if (char == "w" or char == "W"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.w")
          else:
            glyph.classify_heuristic("latin.small.letter.w")
	  char = return_char(glyph.get_main_id())

	if (char == "v" or char == "V"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.v")
          else:
            glyph.classify_heuristic("latin.small.letter.v")
	  char = return_char(glyph.get_main_id())

	if (char == "z" or char == "Z"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.z")
          else:
            glyph.classify_heuristic("latin.small.letter.z")
	  char = return_char(glyph.get_main_id())

	if (char == "s" or char == "S"):
          # not for long s
          if (glyph.get_main_id().upper() != "LATIN.SMALL.LETTER.LONG.S"):   
            if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
              glyph.classify_heuristic("latin.capital.letter.s")
            else:
              glyph.classify_heuristic("latin.small.letter.s")
            char = return_char(glyph.get_main_id())

	#if(char == "T" and (float(glyph.nrows)/float(glyph.ncols)) > 1.5):
	#  glyph.classify_heuristic("LATIN SMALL LETTER F")
	#  char = return_char(glyph.get_main_id()) 

	if (char == "'" or char == ","):
          if (glyph.ul_y < line.bbox.center_y):
            glyph.classify_heuristic("APOSTROPHE")
            char = "'"	
          else:
            glyph.classify_heuristic("COMMA")
            char = ","

      s = s + char
  return s

def textline_to_xml(line, heuristic_rules="roman", extra_chars_dict={}):
  """Returns xml encoding of words and coordinates for the text in the given ``Textline``.

Signature:

    ``textline_to_xml (textline, heuristic_rules="roman", extra_chars_dict={})``

with

    *textline*:
      A ``Textline`` object containing the glyphs. The glyphs must already
      be classified.
      
    *heuristic_rules*:
      Depending on the alphabeth, some characters can very similar and
      need further heuristic rules for disambiguation, like apostroph and
      comma, which have the same shape and only differ in their position
      relative to the baseline.

      When set to \"roman\", several rules specific for latin alphabeths
      are applied.
    
    *extra_chars_dict*
      A dictionary of additional translations of classnames to character codes.
      This is necessary when you use class names that are not unicode names.
      Will be passed to `return_char`_.

As this function uses `return_char`_, the class names of the glyphs in
*textline* must corerspond to unicode character names, as described in
the documentation of `return_char`_.

.. _`return_char`: #return-char

"""
# This function was added by Dave Woods - woodsdm2@muohio.edu in 9/2010
# It is based on the textline_to_string function, but modified to produce output with XML tags
# These tags add tagging of words, along with the coordinates for the upper right and lower 
# left corners of the word bounding box.
# Added to support the requirements of the 18th Connect project.
#
# Modified by Matt Christy - mchristy@tamu.edu on 7/24/2013
# Correcting to more accurately reflect the Gale OCR XML structure:
#	chainge <line> to <p>
  wordlist = line.words
  s = "<p>\n"
  char = ""
  for i in range(len(wordlist)):
    word = ""
#set left/right x and upper/lower y from first glyph
    word_leftx = wordlist[i][0].ul_x
    word_uppery = wordlist[i][0].ul_y
    word_rightx = wordlist[i][0].lr_x
    word_lowery = wordlist[i][0].lr_y
    for glyph in wordlist[i]:
#update right x and (conditionally) upper/lower y from current glyph
      word_rightx = glyph.lr_x
      if (glyph.ul_y < word_uppery):
	word_uppery = glyph.ul_y
      if (glyph.lr_y > word_lowery):
	word_lowery = glyph.lr_y
      char = return_char(glyph.get_main_id(), extra_chars_dict)
      if (heuristic_rules == "roman"):
        # disambiguation of similar roman characters
	if (char == "x" or char == "X"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.x")
          else:
            glyph.classify_heuristic("latin.small.letter.x")
	  char = return_char(glyph.get_main_id())
	  
	if (char == "p" or char == "P"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.p")
          else:
            glyph.classify_heuristic("latin.small.letter.p")
	  char = return_char(glyph.get_main_id())

	if (char == "o" or char == "O"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.o")
          else:
            glyph.classify_heuristic("latin.small.letter.o")
	  char = return_char(glyph.get_main_id())

	if (char == "w" or char == "W"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.w")
          else:
            glyph.classify_heuristic("latin.small.letter.w")
	  char = return_char(glyph.get_main_id())

	if (char == "v" or char == "V"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.v")
          else:
            glyph.classify_heuristic("latin.small.letter.v")
	  char = return_char(glyph.get_main_id())

	if (char == "z" or char == "Z"):
          if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
            glyph.classify_heuristic("latin.capital.letter.z")
          else:
            glyph.classify_heuristic("latin.small.letter.z")
	  char = return_char(glyph.get_main_id())

	if (char == "s" or char == "S"):
          # not for long s
          if (glyph.get_main_id().upper() != "LATIN.SMALL.LETTER.LONG.S"):   
            if (glyph.ul_y <= line.bbox.center_y-(line.bbox.nrows/4)):
              glyph.classify_heuristic("latin.capital.letter.s")
            else:
              glyph.classify_heuristic("latin.small.letter.s")
            char = return_char(glyph.get_main_id())

	#if(char == "T" and (float(glyph.nrows)/float(glyph.ncols)) > 1.5):
	#  glyph.classify_heuristic("LATIN SMALL LETTER F")
	#  char = return_char(glyph.get_main_id()) 

	if (char == "'" or char == ","):
          if (glyph.ul_y < line.bbox.center_y):
            glyph.classify_heuristic("APOSTROPHE")
            char = "'"	
          else:
            glyph.classify_heuristic("COMMA")
            char = ","
# Handle XML predefined entities - &, ', ", <, and >
        if (char == '&'):
          char = '&amp;'
        if (char == "'"):
          char = '&apos;'
        if (char == '"'):
          char = '&quot;'
        if (char == '<'):
          char = '&lt;'
        if (char == '>'):
          char = '&gt;'
	word = word + char    
# end of glyph processing for word
    pos = "pos=\"" +str(word_leftx)+','+str(word_uppery)+','+str(word_rightx)+','+str(word_lowery)+'"'
    s = s + "<wd "+pos+">"+word+"</wd>\n"
  s = s + "</p>\n"
  return s


def check_upper_neighbors(item,glyph,line):
  """Check for small signs grouped beside each other like quotation marks.

  Signature:
    
    ``check_upper_neighbors(item,glyph,line)``

  with

    *item*:
      Some connected-component.

    *glyph*:
      Some connected-component.

    *line*:
      The ``Textline`` Object which includes ``item`` and ``glyph``

Returns an array with two elements. The first element keeps a list of
characters (images that has been united to a single image) and the
second image is a list of characters which has to be removed as
these have been united to a single character.
  """

  remove = []
  add = []
  result = []
  minheight = min([item.nrows,glyph.nrows])
  # glyphs must be small, of similar size and on the same height
  if(not(glyph.lr_y >= line.center_y and glyph.lr_y-(glyph.nrows/3) <= line.lr_y)): 
    if (glyph.contains_y(item.center_y) and item.contains_y(glyph.center_y)):
      minwidth = min([item.ncols,glyph.ncols])
      distance = item.lr_x - glyph.lr_x
      if(distance > 0 and distance <= minwidth*3):
	remove.append(item)
	remove.append(glyph)
	new = union_images([item,glyph])
	add.append(new)
  result.append(add) 		#result[0] == ADD
  result.append(remove)		#result[1] == REMOVE
  return result

def check_glyph_accent(item,glyph):
  """Check two glyphs for beeing grouped to one single character. This function is for unit connected-components like i, j or colon.

  Signature:
    ``check_glyph_accent(item,glyph)``

  with

    *item*:
      Some connected-component.

    *glyph*:
      Some connected-component.

  There is returned an array with two elements. The first element keeps a list of characters (images that has been united to a single image) and the second image is a list of characters which has to be removed as these have been united to a single character.
  """

  remove = []
  add = []
  result = []
  if(glyph.contains_x(item.ul_x) or glyph.contains_x(item.lr_x) or glyph.contains_x(item.center_x)): ##nebeinander?
    if(not(item.contains_y(glyph.ul_y) or item.contains_y(glyph.lr_y) or item.contains_y(glyph.center_y))): ##nicht y-dimensions ueberschneident
      remove.append(item)
      remove.append(glyph)
      new = union_images([item,glyph])
      add.append(new)
  result.append(add)		#result[0] == ADD
  result.append(remove)		#result[1] == REMOVE
  return result


def get_line_glyphs(image,textlines):
  """Splits image regions representing text lines into characters.

Signature:

    ``get_line_glyphs (image, segments)``

with

    *image*:
      The document image that is to be further segmentated. It must contin the
      same underlying image data as the second argument *segments*

    *segments*:
      A list ``Cc`` data types, each of which represents a text line region.
      The image views must correspond to *image*, i.e. each pixels has a value
      that is the unique label of the text line it belongs to. This is the
      interface used by the plugins in the \"PageSegmentation\" section of the
      Gamera core.

The result is returned as a list of Textline_ objects.

.. _Textline: gamera.toolkits.ocr.classes.Textline.html

"""

  i=0
  show = []
  lines = []
  ret,sub_ccs = image.sub_cc_analysis(textlines)

  for ccs in sub_ccs:
    line_bbox = Rect(textlines[i])
    i = i + 1
    glyphs = ccs[:]
    newlist = []

    remove = []
    add = []
    result = []
    glyphs.sort(lambda x,y: cmp(x.ul_x, y.ul_x))
    for position, item in enumerate(glyphs):
      if(True):
      #if(not(glyph.lr_y >= line_bbox.center_y and glyph.lr_y-(glyph.nrows/3) <= line_bbox.lr_y)):  ## is this part of glyph higher then line.center_y ?

        left = position - 2
        if(left < 0):
          left = 0
        right = position + 2
        if(right > len(glyphs)):
          right = len(glyphs)	
        checklist = glyphs[left:right]

        for glyph in checklist:
          if (item == glyph):
            continue

          result = check_upper_neighbors(glyph,item,line_bbox)
          if(len(result[0]) > 0):  #something has been joind...
            joind_upper_connection = result[0][0]   #joind glyph
            add.append(joind_upper_connection)
            remove.append(result[1][0])	     #first part of joind one
            remove.append(result[1][1])	     #second part of joind one
            for glyph2 in checklist: #maybe the upper joind glyphs fits to a glyph below...
              if(glyphs == joind_upper_connection):
                continue
              if(joind_upper_connection.contains_x(glyph2.center_x)):   #fits for example on ae, oe, ue in german alph
                new = union_images([glyph2,joind_upper_connection])
                add.append(new)
                remove.append(glyph2)
                add.remove(joind_upper_connection)
                break
        for elem in remove:
          if (elem in checklist):
            checklist.remove(elem)

        for glyph in checklist:
          if(item == glyph):
            continue

          result = check_glyph_accent(item,glyph)
          if(len(result[0]) > 0):  #something has been joind...
            add.append(result[0][0])   #joind glyph
            remove.append(result[1][0])	     #first part of joind one
            remove.append(result[1][1])	     #second part of joind one

    for elem in remove:
      if(elem in glyphs):
	glyphs.remove(elem)
    for elem in add:
      glyphs.append(elem)

    new_line = Textline(line_bbox)
    final = []
    if(len(glyphs) > 0):
      for glyph in glyphs:
        final.append(glyph)

    new_line.add_glyphs(final,False)
    new_line.sort_glyphs()  #reading order -- from left to right
    lines.append(new_line)

    for glyph in glyphs:
      show.append(glyph)

  return lines

def show_bboxes(image,glyphs):
  """Returns an RGB image with bounding boxes of the given glyphs as
hollow rects. Useful for visualization and debugging of a segmentation.

Signature:
    
    ``show_bboxes (image, glyphs)``

with:

    *image*:
      An image of the textdokument which has to be segmentated.

    *glyphs*:
      List of rects which will be drawn on ``image`` as hollow rects.
      As all image types are derived from ``Rect``, any image list can 
      be passed.

"""

  rgb = image.to_rgb()
  if(len(glyphs) > 0):
    for glyph in glyphs:
      rgb.draw_hollow_rect(glyph, RGBPixel(255,0,0), 1.0)
  return rgb
