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

    fontBytes = bytes(font.body)
    fontRaw = bytearray()
    charsPerLine = int(font.header.width/8)
    x = 0
    y = 0
    charCount = 256
    while charCount > 0:
        #copy one character
        lineCount = 8
        yTemp = y
        while lineCount > 0:        # copy one char
            thisByte = fontBytes[(yTemp * charsPerLine)]
            fontRaw.append(thisByte)
            yTemp += 1
            lineCount = lineCount - 1
        # move next
        x += 1
        if x == charsPerLine:
            x = 0
            y += 8

        charCount -= 1
    save = open("..\\gfx\\raw\\font-small.raw", "wb")
    save.write(fontRaw)

if __name__ == "__main__":
    main()