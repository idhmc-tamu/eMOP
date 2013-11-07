This code is part of a fork from https://github.com/idigbio-aocr/LabelExtraction created by Ben Brumfield for the iDigBio OCR hackathon.

hocr_to_image.rb is just one of many Ruby apps created to help improve the OCR process on photographs of biological specimen labels. It has been slightly modified to meet the needs of the eMOP team in examining Tesseract output.

hocr_to_image.rb takes as input an image file (in jpg or png format) and an xml or hocr file (in Tesseract's hOCR format) and produces an image that contains the original image overlaid with the bounding boxes tesseract identified for all lines and words in the document. It is called from the command line in the following way:

	>ruby hocr_to_image.rb 39460-2.png 39460-2.xml
	
This command will produce a file called "39460-2.hocr.png".

Dependencies:
	nokogiri
	ImageMagick
	Rmagick


Big thanks to Ben Brumfield for the source and his help, and to iDigBio for permission to reuse.

==========================================
This software is released under the Apache 2.0 license.

For details see http://www.apache.org/licenses/LICENSE-2.0.html
