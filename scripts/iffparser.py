# Amiga IFF Parser
# Hoffman / PT-1210
# started: 2019-07-04, first experience with py

"""IFF parsing functions and data structures."""

import io


class Chunk:
    """IFF Chunk class

    chunk_type = 4 character type (FORM etc.)
    size = binary data size
    data = binary data
    """

    def __init__(self, chunk_type=None, size=None, data=None):
        self.chunk_type = chunk_type
        self.size = size
        self.data = data


class IFFImage:
    """IFF Image class"""

    def __init__(self):
        self.header = BitmapHeader()
        self.body = bytearray()
        self.color_map = []

    def copy_block(self, x, y, width, height):
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
        save_x = x
        save_width = width

        while height > 0:
            while width > 0:
                pos = int(x + y*(self.header.width/8))
                data.append(self.body[pos])
                x += 1
                width -= 1
            width = save_width
            x = save_x
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
        self.x_aspect_ratio = None
        self.y_aspect_ratio = None
        self.page_width = None
        self.page_height = None


def parse_image(filename):
    """Parse Image
    Provide file name and it returns the IFF Image
    """
    image = IFFImage()

    with open(filename, "rb") as f:
        # check FORM
        if f.read(4) != b'FORM':
            raise Exception("not an IFF")

        # check size
        filesize = read_long(f)
        if len(f.read(filesize)) != filesize:
            raise Exception("IFF corrupt")

        # seek back to start
        f.seek(8, 0)
        if f.read(4) != b'ILBM':
            raise Exception("not an IFF")

        # read all chunks into array till end of file
        chunks = []
        while f.read(1):
            f.seek(-1, 1)
            chunk_type = f.read(4).decode("ascii")
            chunk_size = read_long(f)
            chunk_data = f.read(chunk_size)
            if chunk_size > 0:
                chunks.append(Chunk(chunk_type, chunk_size, chunk_data))

    # parse each chunk
    for c in chunks:
        parse_chunk(c, image)

    return image


def parse_chunk(chunk, image):
    """Parses an IFF chunk"""
    if chunk.chunk_type == "BMHD":
        parse_bitmap_header(chunk, image)
    elif chunk.chunk_type == "BODY":
        parse_body(chunk, image)
    elif chunk.chunk_type == "CMAP":
        parse_color_map(chunk, image)


def parse_color_map(chunk, image):
    if chunk.size/3 != pow(2, image.header.bitplanes):
        raise Exception("Color map is corrupt")

    c = chunk.size/3
    f = io.BytesIO(chunk.data)
    while c > 0:
        color = Color()
        color.red = read_byte(f)
        color.green = read_byte(f)
        color.blue = read_byte(f)
        image.color_map.append(color)
        c = c-1


def parse_body(chunk, image):
    if image.header.compress == 0:
        image.body = bytes(chunk.data)
    elif image.header.compress == 1:
        image.body = bytes(run_length_unpack(chunk.data))
    else:
        raise Exception("Unknown compression method")

    if image.header.width/8 * image.header.height * image.header.bitplanes != len(image.body):
        raise Exception("Uncompressed data not correct size")


def parse_bitmap_header(chunk, image):
    f = io.BytesIO(chunk.data)
    image.header.width = read_word(f)
    image.header.height = read_word(f)
    image.header.left = read_word(f)
    image.header.top = read_word(f)
    image.header.bitplanes = read_byte(f)
    image.header.masking = read_byte(f)
    image.header.compress = read_byte(f)
    image.header.padding = read_byte(f)
    image.header.transparency = read_word(f)
    image.header.x_aspect_ratio = read_byte(f)
    image.header.y_aspect_ratio = read_byte(f)
    image.header.page_width = read_word(f)
    image.header.page_height = read_word(f)


def run_length_unpack(data):
    """Run length unpacker"""
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


def read_byte(f):
    """Function for reading byte as int"""
    return int.from_bytes(f.read(1), 'big')


def read_byte_signed(f):
    """Function for reading byte as signed int"""
    return int.from_bytes(f.read(1), 'big', signed=True)


def read_word(f):
    """Function for reading big endian word"""
    return int.from_bytes(f.read(2), 'big')


def read_long(f):
    """Function for reading big endian long word"""
    return int.from_bytes(f.read(4), 'big')
