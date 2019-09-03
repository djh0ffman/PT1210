#!/usr/bin/env python3

# Image Conversion Script
# Hoffman / PT-1210

"""Main conversion script for gfx elements."""

import argparse
import os
import sys
import iffparser
import yaml

OP_EXTENSIONS = {
    '8x8': 'raw',
    'cut': 'raw',
    'copper_palette': 'asm'
}

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

def process_task_list(yaml_task_list, input_path, output_path, quiet=False):
    if not quiet:
        print("Processing task list: {}".format(yaml_task_list))
    doc = open(yaml_task_list, 'r')
    tasks = yaml.load(doc, Loader=yaml.Loader)
    for task in tasks:
        convert_task(task, input_path, output_path, quiet)

def process_cut_list(yaml_cut_list, hud_iff, output_path, quiet=False):
    if not quiet:
        print("Processing cut list: {}".format(yaml_cut_list))
    doc = open(yaml_cut_list, 'r')
    huds = yaml.load(doc, Loader=yaml.Loader)
    hud_image = iffparser.parse_image(hud_iff)
    values = "\nhud_lookup_sizeof = 12\n"
    lookup = "\nhud_lookup:\n"
    incbins = ""

    os.makedirs(output_path, exist_ok=True)

    for hud in huds:
        if not quiet:
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


def convert_task(task, input_path, output_path, quiet=False):
    source_file = os.path.join(input_path, task.source)
    destination_file = os.path.join(output_path, task.output + os.extsep + OP_EXTENSIONS[task.operation])

    if not quiet:
        print("[{}] {} --> {}".format(task.operation, source_file, destination_file))

    image = iffparser.parse_image(source_file)

    if image.header.bitplanes != task.bitplanes:
        raise Exception(
            '{} has incorrect number of bitplanes'.format(task.source))

    data = bytearray()
    if task.operation == "8x8":
        # Convert 8x8 font
        data = convert_font_8x8(image)
    elif task.operation == "cut":
        # Perform cut operation
        data = image.copy_block(task.x, task.y, task.width, task.height)
    elif task.operation == "copper_palette":
        palette = image.copper_palette()
        data = palette.encode('ascii')
    else:
        raise Exception(
            '{} operation not supported'.format(task.operation))

    os.makedirs(output_path, exist_ok=True)
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
parser = argparse.ArgumentParser()
parser.add_argument('-q', '--quiet', action='store_true', help='suppress output')
subparsers = parser.add_subparsers(dest='command', help='command')
subparsers.required = True
subparsers.dest = 'command'

hud_cut_parser = subparsers.add_parser('hudcut', help='process a HUD cut list')
hud_cut_parser.add_argument('cut_list', type=str, help='path to YAML cut list file')
hud_cut_parser.add_argument('hud_image', type=str, help='path to HUD .iff file')
hud_cut_parser.add_argument('output_dir', type=str, help='output directory')

task_parser = subparsers.add_parser('task', help='process a graphics conversion task list')
task_parser.add_argument('task_list', type=str, help='path to YAML task list file')
task_parser.add_argument('input_dir', type=str, help='input directory')
task_parser.add_argument('output_dir', type=str, help='output directory')

args = parser.parse_args()

try:
    # HUD cut command
    if args.command == 'hudcut':
        process_cut_list(args.cut_list, args.hud_image, args.output_dir, args.quiet)

    # Task list command
    elif args.command == 'task':
        process_task_list(args.task_list, args.input_dir, args.output_dir, args.quiet)

    if not args.quiet:
        print('Operation successful.')

except Exception as exc:
    print('Error while processing: {}'.format(exc), file=sys.stderr)
    exit(1)
