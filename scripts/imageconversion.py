#!/usr/bin/env python

# Image Conversion Script
# Hoffman / PT-1210

import iffparser
import io

pathIff = "../gfx/iff/"
pathRaw = "../gfx/raw/"

    # main conversion script for gfx elements
def main():
    convertFont8x8("font-small")
    convertFont8x8("font-big")
    print("--> ALL DONE <--")



    # small font conversion
    # generate raw version for 256 characters
def convertFont8x8(filename):
    font = iffparser.parseImage(pathIff+filename+".iff")
    if font.header.bitplanes != 1:
        raise Exception (filename + " has incorrect number of bitplanes")

    rawFont = bytearray()
    charCount = 256
    x = 0
    y = 0
    while charCount > 0:
        charCount -= 1
        rawFont += font.copyBlock(x,y,1,8)
        x += 1
        if (x >= font.header.width/8):
            x = 0
            y += 8

    save = open(pathRaw+filename+".raw", "wb")
    save.write(rawFont)

if __name__ == "__main__":
    main()