#!/usr/bin/env python

from __future__ import print_function

import sys
if sys.version_info[0] < 3:
    from HTMLParser import HTMLParser
else:
	from html.parser import HTMLParser

# Match <input ... name="$1" ... value="(...)">

class InputParser(HTMLParser):
	"""
	HTMLParser subclass designed only for extracting input elements with
	name="expectedNameAttr".
	"""
	def __init__(self, expectedNameAttr):
		if sys.version_info[0] < 3:
			HTMLParser.__init__(self)
		else:
			super(InputParser, self).__init__()
		self.expectedNameAttr = expectedNameAttr
	
	def handle_starttag(self, tag, attrs):
		"""
		Handler for start tag in HTML input. We only want "input" elements.
		"""
		# Extract input tag
		if tag == 'input':
			attrDict = dict(attrs)
			if 'name' in attrDict and attrDict['name'] == self.expectedNameAttr:
				print(attrDict['value'] if 'value' in attrDict else "")
		pass
			
# CLI
import argparse

parser = argparse.ArgumentParser(description='Extract the value of input with specified name.')
parser.add_argument('fieldname', help='Name of input to extract.')
parser.add_argument('infile', nargs='?', type=argparse.FileType('r'), default=sys.stdin,
					help='Input HTML file. Default: STDIN')

args = parser.parse_args()

p = InputParser(args.fieldname)
p.feed(args.infile.read())

