#!/usr/bin/env python
import os
import numpy as np
import matplotlib.pyplot as plt
import cv2
import json

MAX_MEM_SIZE = 4.9e6//8


class Image_generator:
    def __init__(self, input_file):
        self.name = input_file
        self.image = self.to_gray(self.load_data())
        self.width, self.height = self.image.shape

    def load_data(self):
        path = os.getcwd()
        if os.path.exists('python'):
            path += '/python'

        file_name = path + '/' + self.name
        if os.path.isfile(file_name):
            return cv2.imread(file_name)
        else:
            return None

    @staticmethod
    def display_image(img):
        print(img.shape)
        plt.imshow(img)
        plt.show()

    @staticmethod
    def to_gray(img):
        return cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)

    def check_size(self):
        print(f'File size is {self.image.shape}')
        if np.prod(self.image.shape) > MAX_MEM_SIZE:
            print('Input image is too large for this memory ERROR')
            exit(1)
        else:
            print('Input OK')

    def gen_package(self):
        path = os.getcwd()
        hdl_path = os.getcwd()

        if os.path.exists('python'):
            path += '/python'

        if os.path.exists('hdl'):
            hdl_path += '/hdl'

        file_name = path + '/' + 'image_generator_pkg.txt'
        hdl_name = hdl_path + '/' + 'image_generator_pkg.vhd'

        with open(hdl_name, 'w') as h:
            with open(file_name, 'r') as f:
                line = f.read()
                line = line.replace('#width#', str(self.width))
                line = line.replace('#height#', str(self.height))
                line = line.replace('#gray#', 'False')
                line = line.replace('#name#', '"' + self.name.split('.')[0]+'.coe' +'"')

                h.write(line)

    def gen_memory(self):
        path = os.getcwd()
        if os.path.exists('memory'):
            path += '/memory'
        f_name = path + '/' + self.name.split('.')[0] + '.coe'

        with open(f_name, 'w') as f:
            for idx, value in enumerate(self.image.flatten()):
                write_data = f'@{idx:04X} {value:02X}\n'
                f.write(write_data)

    def run(self):
        self.check_size()
        self.gen_package()
        self.gen_memory()
        print('Done')


if __name__ == '__main__':
    INPUT_FILE = 'cat.jpg'
    ig = Image_generator(INPUT_FILE)
    ig.run()