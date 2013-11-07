#!/usr/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'pp'
require 'pry'
require 'RMagick'


# proporation of the image which is considered a valid size for a word or letter
# ex. a 1200x1600 image would discard any regions smaller than 96 pixels with MIN_VALID_AREA=0.00005
MIN_VALID_AREA = 0.0000002

image_filename = ARGV[0]
@hocr_filename = ARGV[1]
ext = File.extname(image_filename)
@out_filename = File.basename(image_filename.sub(ext, ".hocr"+ext))

@image = Magick::ImageList.new(image_filename).first.quantize(256, Magick::GRAYColorspace)
@original_image = @image.copy

@rows = @image.rows
@cols = @image.columns

p @rows
p @cols

@rectangle_list = Array.new

class Rectangle
  attr_accessor :min_x, :min_y, :max_x, :max_y, :consolidated
  @@x_tol=12
  @@y_tol=12
  
  def initialize
    @consolidated=false
  end
  
  def self.from_coords(coords)
    me = Rectangle.new
    me.min_x=coords[0]
    me.min_y=coords[1]
    me.max_x=coords[2]
    me.max_y=coords[3]
    me
  end

  def tol_min_x
    min_x - @@x_tol
  end  
  def tol_min_y
    min_y - @@y_tol
  end
  
  def tol_max_x
    max_x + @@x_tol
  end  
  def tol_max_y
    max_y + @@y_tol
  end

  def tol_to_s
    "#{tol_min_x},#{tol_min_y},#{tol_max_x},#{tol_max_y}, c=#{consolidated}"    
  end  
  
  def to_s
    "#{min_x},#{min_y},#{max_x},#{max_y}, c=#{consolidated}"
  end
end


def draw_rectangle(start_x,start_y,end_x,end_y, color, strength, text=nil, caller='dump')
    #MJC (10/2013): added caller parm to indicate where this function is called from
    #               so that I can better control how the text is displayed based on caller.
  gc = Magick::Draw.new

  
  gc.stroke(color)
  gc.stroke_width(strength)


  # top line
  gc.line(start_x, start_y, end_x, start_y)
  # bottom line
  gc.line(start_x, end_y, end_x, end_y)
  # left line
  gc.line(start_x, start_y, start_x, end_y) 
  # right line
  gc.line(end_x, start_y, end_x, end_y)

  if text && text.length > 0
      #MCJ (10/2013): text sent by dump is displayed within the box
      #               text sent by parent is displayed to left of the box
      if caller=='dump'
          gc.stroke_width(2)
          gc.pointsize(18)
          gc.stroke("orange")
          gc.text(start_x+5, start_y+15, text)
      elsif caller=='parent'
            gc.stroke_width(2)
            gc.pointsize(14)
            gc.stroke("orange")
            gc.text(start_x-60, start_y+10, text)
      end

  end
  # # Annotate
  # gc.stroke('transparent')
  # gc.fill('black')
  # gc.text(130, 35, "End")
  # gc.text(188, 135, "Start")
  # gc.text(130, 95, "'Height=120'")
  # gc.text(55, 155, "'Width=80'")

  gc.draw(@image)
end

def coords_from_element(e)
  title = e['title']
  return nil unless title
  coords = title.split(' ') 
  # titles all begin with 'bbox', which we ignore
  return [coords[1].to_i,coords[2].to_i,coords[3].to_i,coords[4].to_i]      
end


def rectangle_from_element(e, color, strength, text)
  coords = coords_from_element(e)
  # titles all begin with 'bbox', which we ignore
#  draw_rectangle(coords[0],coords[1],coords[2],coords[3], color, strength, e.text)      
  draw_rectangle(coords[0],coords[1],coords[2],coords[3], color, strength, text, 'parent')
end

def traverse_parents(e) 
  parent = e.parent
  #MJC (10/2013): uncomment out to display ocr_line boxes
  rectangle_from_element(parent, 'red', 3, e.parent['id'])

  grandparent = parent.parent
#  rectangle_from_element(parent, 'red', 5)
end

def point_in_rectangle?(x,y,rect)
#  print "\tpoint_in_rectangle:X testing whether #{x} >= #{rect.tol_min_x} && #{x} <= #{rect.tol_max_x} \n"
  if x >= rect.tol_min_x && x <= rect.tol_max_x
#    print "\tpoint_in_rectangle:Y testing whether #{y} >= #{rect.tol_min_y} && #{y} <= #{rect.tol_max_y} \n"
    if y >= rect.tol_min_y && y <= rect.tol_max_y
      return true
    end   
  end
  return false
end

def rectangles_overlap?(a,b)
  point_in_rectangle?(a.tol_min_x,a.tol_min_y,b) ||
  point_in_rectangle?(a.tol_min_x,a.tol_max_y,b) || 
  point_in_rectangle?(a.tol_max_x,a.tol_min_y,b) ||
  point_in_rectangle?(a.tol_max_x,a.tol_max_y,b)
end


def max(a, b)
  a > b ? a : b
end

def min(a, b)
  a < b ? a : b
end


def dump_rectangles
  @rectangle_list.each_with_index do |r, index|
    draw_rectangle(r.min_x, r.min_y, r.max_x, r.max_y, 'blue', 3, "#{index}", 'dump')
    
  end
end

def consolidate_rectangles(inner_rectangle,outer_rectangle)
 # print "combining rectangles #{outer_rectangle}  and  #{inner_rectangle}\n"
  draw_rectangle(outer_rectangle.min_x, outer_rectangle.min_y, outer_rectangle.max_x, outer_rectangle.max_y, 'purple', 2)
  draw_rectangle(inner_rectangle.min_x, inner_rectangle.min_y, inner_rectangle.max_x, inner_rectangle.max_y, 'purple', 2)  
  # draw_rectangle(min(outer_rectangle.min_x,inner_rectangle.min_x), 
                 # min(outer_rectangle.min_y,inner_rectangle.min_y),
                 # max(outer_rectangle.max_x,inner_rectangle.max_x), 
                 # max(outer_rectangle.max_y,inner_rectangle.max_y), 
                 # 'blue', 4)  
  r = Rectangle.new
  r.min_x = min(outer_rectangle.min_x,inner_rectangle.min_x) 
  r.min_y = min(outer_rectangle.min_y,inner_rectangle.min_y)
  r.max_x = max(outer_rectangle.max_x,inner_rectangle.max_x) 
  r.max_y = max(outer_rectangle.max_y,inner_rectangle.max_y)
  r.consolidated=true
  r
end


def combine_rectangles
  0.upto(@rectangle_list.length-2) do |i|
 #   print "considering rectangle #{i}\n"
    outer_rectangle = @rectangle_list[i]
    (i+1).upto(@rectangle_list.length-1) do |k|
#      print "\tcomparing rectangle #{k}\n"
#      print "[#{i}][#{k}]\n"
      inner_rectangle = @rectangle_list[k]
      # test each way since apparently I can't do math
      if rectangles_overlap?(outer_rectangle,inner_rectangle) || rectangles_overlap?(inner_rectangle,outer_rectangle)
        consolidated = consolidate_rectangles(inner_rectangle,outer_rectangle)
        # delete old rectangles
        @rectangle_list.delete(outer_rectangle)
        @rectangle_list.delete(inner_rectangle)
        # update outer rectangle
        @rectangle_list << consolidated
        return true
      end
    end
  end
  # we got through every permutation with nothing to consolidate -- time to quit!
  return false
end


def valid_ocr?(e)
  likely_text = e.text =~ /\w\w/ || e.text =~ /\w\.$/ || e.text =~ /^\w$/
  coords = coords_from_element(e)
  
  width = coords[2] - coords[0]
  height = coords[3] - coords[1]
  
  area = width * height
  likely_area = area > (@cols * @rows * MIN_VALID_AREA)
  # print "#{e['id']}: #{likely_area}==#{area} > (#{@cols} * #{@rows} * #{MIN_VALID_AREA})(==#{(@cols * @rows * MIN_VALID_AREA)})\n"
  likely_text && likely_area
end

def process_hocr
  page = Nokogiri::HTML(open(@hocr_filename), nil, 'iso-8859-1')
  
  
  word_spans = page.xpath('//span[@class="ocrx_word"]')
  word_spans.each do |e|
    if valid_ocr?(e) 
      # p 'FOUND WORDS'
#      rectangle_from_element(e, 'green', 3)
      coords = coords_from_element(e)
      @rectangle_list << Rectangle.from_coords(coords)
    else
#     rectangle_from_element(e, 'red', 3)      
    end
    
    traverse_parents(e)
  end


end

# returns a cropped image
def crop_rectangle(r)
  @original_image.crop(r.min_x, r.min_y, r.max_x-r.min_x, r.max_y-r.min_y)  
end

def crop_file_name(n)
  @out_filename.sub(File.extname(@out_filename), ".crop_#{n}#{File.extname(@out_filename)}")
end

def text_file_name(n)
  crop_file = crop_file_name(n)
  crop_file.sub(File.extname(crop_file), '.txt')
end

def text_file_name_for_tesseract(n)
  text_file = text_file_name(n)
  text_file.sub(File.extname(text_file), '')
end


def extract_rectangles()
  pruned_list = []
  @rectangle_list.each do |r|
    pruned_list << r if r.consolidated
  end
  pruned_list.sort { |a,b| a.min_y <=> b.min_y }
  pruned_list.each_with_index do |r, i|
    crop_rectangle(r).write(crop_file_name(i))
  end
  pruned_list
end

def postprocess_rectangles(debug_images=false)
  pass = 1
  @old_image = @image.copy
  while combine_rectangles
    if debug_images
      @image = @old_image.copy
      dump_rectangles
      @image.write(@out_filename.sub(File.extname(@out_filename), ".pass#{pass}#{File.extname(@out_filename)}"))      
    end
    pass = pass + 1
  end
  if debug_images
    @image = @old_image.copy
    dump_rectangles
    @image.write(@out_filename.sub(File.extname(@out_filename), ".pass#{pass}#{File.extname(@out_filename)}"))
  end  
end

def ocr_crops(rectangles)
  ocr_filename = @out_filename.gsub(File.extname(@out_filename), "_cleaned.txt")
  p "rm #{ocr_filename}"
  system "rm #{ocr_filename}"
  rectangles.each_with_index do |r, i|
    p "rm #{text_file_name(i)}"
    system "rm #{text_file_name(i)}"
    p "tesseract #{crop_file_name(i)} #{text_file_name_for_tesseract(i)}"
    system "tesseract #{crop_file_name(i)} #{text_file_name_for_tesseract(i)}"
    p "cat #{text_file_name(i)} >> #{ocr_filename}"
    system "cat #{text_file_name(i)} >> #{ocr_filename}"
  end  
  
end


process_hocr
#postprocess_rectangles
dump_rectangles
@image.write(@out_filename)      
#good_rectangles = extract_rectangles
#ocr_crops(good_rectangles)
