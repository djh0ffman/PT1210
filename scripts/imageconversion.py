# Image Conversion Script
# Hoffman / PT-1210

import iffparser
import io

def main():
    convertFontSmall()

    # small font conversion
    # generate raw version for 256 characters
def convertFontSmall():
    font = iffparser.parseImage("..\\gfx\\iff\\font-small.iff")
    if font.header.bitplanes != 1:
        raise Exception ("font-small.iff has incorrect number of bitplanes")

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

    save = open("..\\gfx\\raw\\font-small.raw", "wb")
    save.write(rawFont)

if __name__ == "__main__":
    main()