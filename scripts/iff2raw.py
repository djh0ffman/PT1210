#!/usr/bin/env python

# Image Conversion Script
# Hoffman / PT-1210

"""Main conversion script for gfx elements."""

import argparse
import os
import sys
import iffparser


def convert_font_8x8(input_path, output_path):
    """Small font conversion.
    Generates raw version for 256 characters.
    """
    font = iffparser.parse_image(input_path)
    if font.header.bitplanes != 1:
        raise Exception(
            '{} has incorrect number of bitplanes'.format(input_path))

    raw_font = bytearray()
    char_count = 256
    x = 0
    y = 0
    while char_count > 0:
        char_count -= 1
        raw_font += font.copy_block(x, y, 1, 8)
        x += 1
        if x >= font.header.width/8:
            x = 0
            y += 8

    # Create directory for output file if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'wb') as output:
        output.write(raw_font)


# Parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument('input', type=str, help='path to input IFF file')
parser.add_argument('output', type=str, help='path to output RAW file')
parser.add_argument('-q', '--quiet', action='store_true',
                    help='suppress output')

args = parser.parse_args()

# Attempt the conversion
try:
    convert_font_8x8(args.input, args.output)
    if not args.quiet:
        print('Successfully converted {} --> {}'.format(args.input, args.output))
except Exception as exc:
    print('Error converting {}: {}'.format(args.input, exc), file=sys.stderr)
    exit(1)
