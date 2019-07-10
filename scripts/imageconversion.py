#!/usr/bin/env python

# Image Conversion Script
# Hoffman / PT-1210

"""Main conversion script for gfx elements."""

import iffparser

PATH_IFF = "../gfx/iff/"
PATH_RAW = "../gfx/raw/"


def convert_font_8x8(filename):
    """Small font conversion.
    Generates raw version for 256 characters.
    """
    font = iffparser.parse_image(PATH_IFF+filename+".iff")
    if font.header.bitplanes != 1:
        raise Exception(filename + " has incorrect number of bitplanes")

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

    save = open(PATH_RAW+filename+".raw", "wb")
    save.write(raw_font)


convert_font_8x8("font-small")
convert_font_8x8("font-big")
print("--> ALL DONE <--")
