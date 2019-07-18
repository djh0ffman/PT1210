#!/usr/bin/env python

# Image Conversion Script
# Hoffman / PT-1210

"""Main conversion script for gfx elements."""

import argparse
import os
import sys
import iffparser
import yaml

class GfxTask(yaml.YAMLObject):
    yaml_tag = u'!GfxTask'
    def __init__(self, source, output, operation, bitplanes, x, y, width, height):
        self.source = source
        self.output = output
        self.operation = operation
        self.bitplanes = bitplanes
        self.x = x
        self.y = y
        self.width = width
        self.height = height

class HudCut(yaml.YAMLObject):
    yaml_tag = u'!HudCut'
    def __init__(self, control_id, control_name, cut_x, cut_y):
        self.control_id = control_id
        self.control_name = control_name
        self.cut_x = cut_x
        self.cut_y = cut_y

def process_task_list(yaml_task_list, input_path, output_path):
    doc = open(yaml_task_list, 'r')
    tasks = yaml.load(doc, Loader=yaml.Loader)
    for task in tasks:        
        convert_task(task, input_path, output_path)

def process_cut_list(yaml_cut_list, hud_iff, input_path, output_path):
    print("processing cut list: {}".format(yaml_cut_list))
    doc = open(yaml_cut_list, 'r')
    huds = yaml.load(doc, Loader=yaml.Loader)
    hud_image = iffparser.parse_image(os.path.join(input_path, hud_iff))
    values = "\nhud_lookup_sizeof = 12\n"
    lookup = "\nhud_lookup:\n"
    incbins = ""

    for hud in huds:
        print("cutting {}".format(hud.control_name))

        values += "{} equ {}\n".format(hud.control_name.ljust(50), hud.control_id)

        cut_x = hud.cut_x * 2
        cut_y = hud.cut_y * 16
        image_off = hud_image.copy_block(cut_x, cut_y, 2, 16)
        cut_y = (hud.cut_y + 6) * 16
        image_on = hud_image.copy_block(cut_x, cut_y, 2, 16)

        item_off = "{}_off".format(hud.control_name)
        item_on = "{}_on".format(hud.control_name)
        file_off = "{}.raw".format(item_off)
        file_on = "{}.raw".format(item_on)

        lookup += "\tdc.w\t{},{}\n".format(hud.cut_x, hud.cut_y)
        lookup += "\tdc.l\t{}\n".format(item_off)
        lookup += "\tdc.l\t{}\n".format(item_on)

        incbins += "{}:\t".format(item_off)
        incbins += "\tincbin\t\"gfx/{}\"\n".format(file_off)
        incbins += "{}:\t".format(item_on)
        incbins += "\tincbin\t\"gfx/{}\"\n".format(file_on)

        with open(os.path.join(output_path, file_off), 'wb') as output:
            output.write(image_off)
        with open(os.path.join(output_path, file_on), 'wb') as output:
            output.write(image_on)
    
    data = (values+lookup).encode('ascii')
    with open(os.path.join(output_path, "hud_fast.asm"), 'wb') as output:
        output.write(data)

    data = incbins.encode('ascii')
    with open(os.path.join(output_path, "hud_chip.asm"), 'wb') as output:
        output.write(data)


def convert_task(task, input_path, output_path):
    print("processing: {} / {}".format(task.output, task.operation))

    source_file = os.path.join(input_path, task.source)
    destination_file = os.path.join(output_path, task.output)
    
    image = iffparser.parse_image(source_file)

    if image.header.bitplanes != task.bitplanes:
        raise Exception(
            '{} has incorrect number of bitplanes'.format(task.source))

    data = bytearray()
    if task.operation == "8x8":
        # Convert 8x8 font
        data = convert_font_8x8(image)
        destination_file += ".raw"
    elif task.operation == "cut":
        # Perform cut operation
        data = image.copy_block(task.x, task.y, task.width, task.height)
        destination_file += ".raw"
    elif task.operation == "copper_palette":
        palette = image.copper_palette()
        data = palette.encode('ascii')
        destination_file += ".asm"
    else:
        raise Exception(
            '{} operation not supported'.format(task.operation))

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(destination_file, 'wb') as output:
        output.write(data)

def convert_font_8x8(font):
    """Small font conversion.
    Generates raw version for 256 characters.
    """
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

    # Return new bitmap
    return raw_font


# Parse command line arguments
#parser = argparse.ArgumentParser()
#parser.add_argument('input', type=str, help='path to input IFF file')
#parser.add_argument('output', type=str, help='path to output RAW file')
#parser.add_argument('-q', '--quiet', action='store_true',
#                    help='suppress output')

#args = parser.parse_args()

# Attempt the conversion
#try:
#    convert_font_8x8(args.input, args.output)
#    if not args.quiet:
#        print('Successfully converted {} --> {}'.format(args.input, args.output))
#except Exception as exc:
#    print('Error converting {}: {}'.format(args.input, exc), file=sys.stderr)
#    exit(1)
