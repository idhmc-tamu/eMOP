#!/usr/bin/python
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

import codecs #keep an eye on encoding stuff...  http://evanjones.ca/python-utf8.html
import sys
import time
import os.path
import csv

def usage(returncode):
  print "Usage:\n\tocr4gamera -x <traindata> [options] <imagefile>"
  print "Options (can be short or long):"
  print "\t-v <int>, --verbosity=<int>\n" + \
      "\t   set verbosity level to <int>; possible values are\n" + \
      "\t   0 (default): silent operation\n" + \
      "\t   1:  information on progress\n" + \
      "\t   >2: segmentation info is written to PNG files with prefix 'debug_'"
  print "\t-h, --help\n" + \
      "\t   this help message"
  print "\t-d, --deskew\n" + \
      "\t   do a skew correction (recommended)"
  print "\t-f, --filter\n" + \
      "\t   filter out very large (images) and very small components (noise)"
  print "\t-a, --automatic-group\n" + \
      "\t   autogroup glyphs with classifier"
  print "\t-x <file>, --xmlfile=<file>\n" + \
      "\t   read training data from <file>"
  print "\t-o <xml>, --output=<xml>\n" + \
      "\t   write recognized text to file <xml>\n" + \
      "\t   (otherwise it is written to stdout)"
  print "\t-c <csv>, --extra_chars_csvfile=<csv>\n" + \
      "\t   read additional class name conversions from file <csv>\n" + \
      "\t   <csv> must contain one conversion per line"
  print "\t-R <rules>, --heuristic_rules=<rules>\n" + \
      "\t   apply heuristic rules <rules> for disambiguation of some chars\n" + \
      "\t   <rules> can be 'roman' (default) or 'none' (for no rules)"
  print "\t-D, --dictionary-correction\n" + \
      "\t   dictionary correction (requires aspell or ispell)"
  print "\t-L <lang>, --dictionary-language=<lang>\n" + \
      "\t   language to be used by aspell (when option -D is set)"
  print "\t-e <int>, --edit-distance=<int>\n" + \
      "\t   dictionary correct only when edit distance not more than <int>"
  print "\t-18\n" + \
      "\t   export as 18thConnect format XML file\n"
  
  sys.exit(returncode)

def correct(sentence, lang):
  import os
  from gamera.plugins.structural import edit_distance
  from popen2 import Popen3
  correct="\*"
  incorrect="&"
  #trim_signs = '.,!?;:"'
  trim_signs = ('.',',','!','?',';',':','"')
  spell_prog = 'aspell'
  lang_opt = '-l'
  new_sentence = ""
  words = sentence.split(" ")
  if(len(words) == 0):
    return sentence
  
  p = Popen3('%s' % spell_prog, True)
  if opt.verbosity:
    print 'Using %s for word-correction.\n' % spell_prog
  if p.childerr.readlines() != []:
    if opt.verbosity:
      print '% is not installed\n' % spell_prog
    spell_prog = 'ispell'
    if opt.verbosity:
      print 'Using % for word-correction.\n' % spell_prog
    lang_opt = '-d'
    p = Popen3('%s Q' % spell_prog, True)
    if  p.childerr.readlines() != ['ispell:  specified file does not exist\n']:
      print 'Wether aspell nor ispell is installed on your system. Please make sure to install either of this programs.'
      exit
  
  # open with local setting language
  if (opt.lang == ''):
    if opt.verbosity:
      if spell_prog == 'aspell':
	print 'No language was given. Will open aspell with locale-settings language.\n'
      if spell_prog == 'ispell':
	print 'No language was given. Will open ispell with default language.\n'
    p = Popen3('%s -a' % spell_prog, True) # True is for also storing error object in return-value
  # user chosen language  
  else:
    p = Popen3('%s -a %s %s' % (spell_prog, lang_opt, lang), True)
  

  out = p.fromchild.readline() # first line gives information about programm
  if (out == '' ): #something went wrong
    print p.childerr.readlines()
    exit
      
  word_count = len(words)
  for word in words:
    #word = word.strip(trim_signs)
    sign = ""
    if word.endswith(trim_signs):
      sign = word[-1:]
      word = word[:-1]
    word_count = word_count - 1
    if(correct_this(word)):
      p.tochild.write('%s\n' % word.encode('utf-8'))
      p.tochild.flush()
      out = p.fromchild.readline()
      while (out=='\n'):
	out = p.fromchild.readline()
      
      if(out[0] == '*'): #spell_prog says: word correct
	new_sentence = new_sentence + word +sign
	if(word_count):
	  new_sentence = new_sentence + " "
	continue
      elif(out[0] == '&'): #spell_prog says: word incorrect
	out = out.split(" ")
	if edit_distance(word, out[4][:-1]) <= opt.distance:
	  word = out[4][:-1].decode('utf-8')
	elif opt.verbosity:
	  print('%d. word: \'%s\' was not corrected to \'%s\'. ' 
	  'Edit_distance: %i is larger than distance: %i.\n' 
	  % (len(words)-word_count, word, out[4][:-1],
	     edit_distance(word, out[4][:-1]), opt.distance))
	
    new_sentence = new_sentence + word + sign
    if(word_count):
      new_sentence = new_sentence + " "
  return new_sentence
	
    
def correct_this(word):
  for character in word:
    if(character == "-"):
      return False
    if(character == "[" or character == "]"):
      return False    
    if(character.isdigit()):
      return False
  if(word == word.upper()):
      return False
  return True


class Options:    
  def __init__(self):
    self.help = False
    self.deskew = False
    self.ccsfilter = False
    self.auto_group = False
    self.dict_correct = False
    
    self.verbosity = 0
    self.output = ""
    self.trainfile = ""
    self.lang = ""
    self.distance = 2
    self.extra_chars_csvfile = ""
    self.heuristic_rules = "roman"
    self.eight = False
    self.despeckle = False
    self.despeckleSize = 1

#
# here starts the main program
#
opt = Options()
args = sys.argv[1:]
imagefile = ""
extra_chars_dict = {}


if(len(args) == 0):
  usage(1)

i =0
while i< len(args):
  # options without second parameter
  if args[i] in ("-h", "--help"):
    usage(0)
  elif args[i] in ("-d", "--deskew"):
    opt.deskew = True
  elif args[i] in ("-f", "--filter"):
    opt.ccsfilter = True
  elif args[i] in ("-a", "--automatic-group"):
    opt.auto_group = True
  elif args[i] in ("-D", "--dictionary-correction"):
    opt.dict_correct = True
  # option for 18th Connect
  elif args[i] in ("-18"):
    opt.eight = True

  # options with second parameter
  # verbosity level
  elif args[i] in ("-v"):
    i+=1
    opt.verbosity = int(args[i])
  elif args[i].startswith("--verbosity="):
    opt.verbosity = int(args[len("--verbosity="):])
  # result file name
  elif args[i] in ("-o"):
    i+=1
    opt.output = args[i]
  elif args[i].startswith("--output="):
    opt.output = args[len("--output="):]
  # training data file
  elif args[i] in ("-x"):
    i+=1
    opt.trainfile = args[i]
  elif args[i].startswith("--xmlfile="):
    opt.trainfile = args[i][len("--xmlfile="):]
  # dictionary language
  elif args[i] in ("-L"):
    i+=1
    opt.lang = args[i]
  elif args[i].startswith("--dictionary-language="):
    opt.lang = args[i][len("--dictionary-language="):]
  # despeckle image
  elif args[i] in ("-k"):
    opt.despeckle = True
    i+=1
    opt.despeckleSize = int(args[i])
  # edit distance for dictionary lookup
  elif args[i] in ("-e"):
    i+=1
    opt.distance = int(args[i])
  elif args[i].startswith("--edit-distance="):
    opt.distance = int(args[i][len("--edit-distance="):])
  # additional translations classname -> character
  elif args[i] in ("-c"):
    i+=1
    opt.extra_chars_csvfile = args[i] 
  elif args[i].startswith("--extra_chars_csvfile="):
    opt.extra_chars_csvfile = args[i][len("--extra_chars_csvfile="):]
  # heuristic disambiguation rules
  elif args[i] in ("-R"):
    i+=1
    opt.heuristic_rules = args[i].lower()
  elif args[i].startswith("--heuristic_rules="):
    opt.heuristic_rules = args[i][len("--heuristic_rules="):].lower()
  # unknown option
  elif args[i][0] == '-':
    print "Error: option %s does not exist" % args[i]
    usage(1)
  else:
    # we assume it is the imagefile
    imagefile=args[i]
  i+=1

if opt.trainfile == "":
  print "Error: no training data given"
  usage(1)
  
if imagefile == "":
  print "Error: no image file given"
  usage(1)


# we import Gamera after parsing the command line arguments
# so that in case of an error the script can be aborted beforehand
from gamera.core import * 
init_gamera()    
from gamera import knn   
from gamera.plugins import pagesegmentation
from gamera.plugins.pagesegmentation import textline_reading_order
from gamera.classify import ShapedGroupingFunction
from gamera.plugins.image_utilities import union_images
from gamera.toolkits.ocr.ocr_toolkit import *
from gamera.toolkits.ocr.classes import Textline,Page,ClassifyCCs
from gamera.plugins.morphology import *

img = load_image(imagefile)
if img.data.pixel_type != ONEBIT:
  img = img.to_onebit()

if opt.extra_chars_csvfile != "":
  f = open(opt.extra_chars_csvfile, "r")
  
  for line in f:
    classname, char = line.split(',', 2)[:2]
    classname = classname.strip()
    char = char.strip("\n\r")
    extra_chars_dict[classname] = char

  f.close()
  
if(opt.despeckle):
  print "started despeckle with size",str(opt.despeckleSize)
  img.despeckle(opt.despeckleSize)


if(opt.ccsfilter):
    count = 0
    ccs = img.cc_analysis()
    print "filter started on",len(ccs) ,"elements..."
    median_black_area = median([cc.black_area()[0] for cc in ccs])
    for cc in ccs:
      if(cc.black_area()[0] > (median_black_area * 10)):
        cc.fill_white()
        del cc
        count = count + 1
    for cc in ccs:
      if(cc.black_area()[0] < (median_black_area / 10)):
        cc.fill_white()
        del cc
        count = count + 1
    print "filter done.",len(ccs)-count,"elements left."


if(opt.deskew):
  #from gamera.toolkits.otr.otr_staff import *
  if opt.verbosity > 0:
    print "\ntry to skew correct..."
  rotation = img.rotation_angle_projections(-10,10)[0]
  img = img.rotate(rotation,0)
  if opt.verbosity > 0:
    print "rotated with",rotation,"angle"

if(opt.auto_group):
  cknn = knn.kNNInteractive([], ["aspect_ratio", "volume64regions", "moments", "nholes_extended"], 0)
  cknn.from_xml_filename(opt.trainfile)
  if(opt.ccsfilter):
    the_ccs = ccs
  else:
    the_ccs = img.cc_analysis()
  median_cc = int(median([cc.nrows for cc in the_ccs]))
  autogroup = ClassifyCCs(cknn)
  autogroup.parts_to_group = 3
  autogroup.grouping_distance = max([2,median_cc / 8])
  p = Page(img, classify_ccs=autogroup)
  if opt.verbosity > 0:
    print "autogrouping glyphs activated."
    print "maximal autogroup distance:", autogroup.grouping_distance
else:
  p = Page(img)

if opt.verbosity > 0:
  print "start page segmentation..."
  t = time.time()

p.segment()

if opt.verbosity > 0:
  t = time.time() - t
  print "\t segmentation done [",t,"sec]"

if opt.verbosity > 1:
  rgbfilename = "debug_lines.png"
  rgb = p.show_lines()
  rgb.save_PNG(rgbfilename)
  print "file '%s' written" % rgbfilename
  rgbfilename = "debug_chars.png"
  rgb = p.show_glyphs()
  rgb.save_PNG(rgbfilename)
  print "file '%s' written" % rgbfilename
  rgbfilename = "debug_words.png"
  rgb = p.show_words()
  rgb.save_PNG(rgbfilename)
  print "file '%s' written" % rgbfilename

if(opt.output == ""):
  sys.stdout = codecs.getwriter('utf-8')(sys.stdout)
elif(opt.eight):
  fullname = os.path.realpath(imagefile)
  (path,file) = os.path.split(fullname)
# Modified by Matt Christy - mchristy@tamu.edu on 7/24/2013
# Changed to add xml tag, minimal header info and change
# <page> tag to include <pageInfo>
  f = codecs.open(opt.output, "a", "utf-8")
  xmltag='<?xml version="1.0" encoding="ISO-8859-1"?>\n' + \
	'<book>\n' + \
	'<text>\n'
  f.write(xmltag)
  pagetag='<page imgno="'+file+'" path="'+path+'">\n' + \
	'<pageInfo>\n' + \
	'<imageLink>'+file+'</imageLink>\n' + \
	'</pageInfo>\n' + \
	'<pageContent>\n'
  f.write(pagetag)
  f.flush()
  f.close()
  

for line in p.textlines:
  if(opt.ccsfilter):
    if(len(line.glyphs) < 2): #a line with one or no glyph is useless
      continue

  cknn = knn.kNNInteractive([], ["aspect_ratio", "moments", "volume64regions", "nholes_extended"], 0)
  cknn.from_xml_filename(opt.trainfile)
  cknn.classify_list_automatic(line.glyphs)

  if(opt.ccsfilter):	#lines with a median confidence lower than 0.005 should be useless too
    if(median([glyph.get_confidence() for glyph in line.glyphs]) < 0.005):
      continue

  line.sort_glyphs()
  line.text =  textline_to_string(line, heuristic_rules=opt.heuristic_rules, extra_chars_dict=extra_chars_dict)
  if(opt.dict_correct):
    line.text = correct(line.text, opt.lang)
  line_text = line.text

  if(opt.output != ""):
    f = codecs.open(opt.output, "a", "utf-8")
    if (opt.eight):
      line_text = textline_to_xml(line, heuristic_rules=opt.heuristic_rules, extra_chars_dict=extra_chars_dict)
    line_text = line_text + "\n"
    f.write(line_text)
    f.flush()
    f.close()
  else:
    print line_text
if opt.verbosity > 0 and opt.output != "":
  print "text has been written to file",opt.output
if((opt.output != "") and (opt.eight)):
# Modified by Matt Christy - mchristy@tamu.edu, 7/24/2013
# add more closing tags from above (pagetag)
  pagetagclose='</pageContent>\n' + \
	'</page>\n' + \
	'</text>\n' + \
	'</book>\n'
  f = codecs.open(opt.output, "a", "utf-8")
  f.write(pagetagclose)
  f.flush()
  f.close()

