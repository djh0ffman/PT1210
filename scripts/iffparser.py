# Amiga IFF Parser
# Hoffman / PT-1210
# started: 2019-07-04, first experience with py

import io

# IFF Chunk class
# type = 4 character type (FORM etc.)
# size = binary data size
# data = binary data
class Chunk:
    def __init__(self, type=None, size=None, data=None):
        self.type = type
        self.size = size
        self.data = data

# IFF Image Class
class IFFImage:
    def __init__(self):
        self.header = BitmapHeader()
        self.body = bytearray()
        self.colorMap = []

    def copyBlock(self, x, y, width, height):
        # do copy boundary checks
        if x*8 > self.header.width:
            raise Exception("copy block: x position out of bounds")
        if y > self.header.height:
            raise Exception("copy block: y position out of bounds")
        if x+width*8 > self.header.width:
            raise Exception("copy block: width out of bounds")
        if y+height > self.header.width:
            raise Exception("copy block: height out of bounds")

        data = bytearray()
        saveX = x
        saveWidth = width

        while height > 0:
            while width > 0:
                pos = int(x + y*(self.header.width/8))
                data.append(self.body[pos])
                x += 1
                width -= 1
            width = saveWidth
            x = saveX
            height -= 1
            y += 1
        return data

class Color:
    def __init__(self):
        self.red = None
        self.green = None
        self.blue = None

class BitmapHeader:
    def __init__(self):
        self.width = None
        self.height = None
        self.left = None
        self.top = None
        self.bitplanes = None
        self.masking = None
        self.compress = None
        self.padding = None
        self.transparency = None
        self.xAspectRatio = None
        self.yAspectRatio = None
        self.pageWidth = None
        self.pageHeight = None

# Parse Image
# Provide file name and it returns the IFF Image
def parseImage(filename):
    image = IFFImage()

    with open(filename, "rb") as f:
        #check FORM
        if f.read(4) != b'FORM':
            raise Exception("not an IFF")
        
        #check size
        filesize = readLong(f)
        if len(f.read(filesize)) != filesize:
            raise Exception("IFF corrupt")
        
        # seek back to start
        f.seek(8,0)
        if f.read(4) != b'ILBM':
            raise Exception("not an IFF")

        # read all chunks into array till end of file
        chunks = []
        while f.read(1):
            f.seek(-1,1)
            chunkType = f.read(4).decode("ascii")
            chunkSize = readLong(f)
            chunkData = f.read(chunkSize)
            if chunkSize > 0:
                chunks.append(Chunk(chunkType, chunkSize, chunkData))

    # parse each chunk
    for c in chunks:
        parseChunk(c, image)

    return image

def parseChunk(chunk, image):
    if chunk.type == "BMHD":
        parseBitmapHeader(chunk, image)
    elif chunk.type == "BODY":
        parseBody(chunk, image)
    elif chunk.type == "CMAP":
        parseColorMap(chunk, image)
    return

def parseColorMap(chunk, image):
    if chunk.size/3 != pow(2,image.header.bitplanes):
        raise Exception("Color map is corrupt")

    c = chunk.size/3
    f = io.BytesIO(chunk.data)
    while c > 0:
        color = Color()
        color.red = readByte(f)
        color.green = readByte(f)
        color.blue = readByte(f)
        image.colorMap.append(color)
        c = c-1
    return

def parseBody(chunk, image):
    if image.header.compress == 0:
        image.body = bytes(chunk.data)
    elif image.header.compress == 1:
        image.body = bytes(runLengthUnpack(chunk.data))
    else:
        raise Exception("Unknown compression method")

    if image.header.width/8 * image.header.height * image.header.bitplanes != len(image.body):
        raise Exception ("Uncompressed data not correct size")
    return

def parseBitmapHeader(chunk, image):
    f = io.BytesIO(chunk.data)
    image.header.width = readWord(f)
    image.header.height = readWord(f)
    image.header.left = readWord(f)
    image.header.top = readWord(f)
    image.header.bitplanes = readByte(f)
    image.header.masking = readByte(f)
    image.header.compress = readByte(f)
    image.header.padding = readByte(f)
    image.header.transparency = readWord(f)
    image.header.xAspectRatio = readByte(f)
    image.header.yAspectRatio = readByte(f)
    image.header.pageWidth = readWord(f)
    image.header.pageHeight = readWord(f)
    return

# run length unpacker
def runLengthUnpack(data):
    source = io.BytesIO(data)
    output = io.BytesIO()
    current = source.read(1)

    while current != b'':
        value = int.from_bytes(current, 'big', signed=True)
        if 0 <= value <= 127:                        # literal copy
            output.write(source.read(value+1))  
        elif -127 <= value <= -1:                    # byte copy
            value = -value+1
            dupe = source.read(1)
            while value > 0:
                output.write(dupe)
                value = value - 1
            
        current = source.read(1)

    output.seek(0, 0)
    data = output.read()
    return data

# function for reading byte as int
def readByte(f):
    return int.from_bytes(f.read(1), 'big')

# function for reading byte as int
def readByteS(f):
    return int.from_bytes(f.read(1), 'big', signed=True)

# function for reading big endian word
def readWord(f):
    return int.from_bytes(f.read(2), 'big')

# function for reading big endian long word
def readLong(f):
    return int.from_bytes(f.read(4), 'big')

