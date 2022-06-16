#!/usr/bin/env python
from serial import Serial, EIGHTBITS, PARITY_NONE, STOPBITS_ONE
from sys import argv
import numpy as np
from PIL import Image, ImageOps


def to_image(values: np.ndarray) -> Image.Image:
    return Image.fromarray(np.uint8(values))

TOTAL_BYTES = 320*240

assert len(argv) == 2

s = Serial(
    port=argv[1],
    baudrate=115200,
    bytesize=EIGHTBITS,
    parity=PARITY_NONE,
    stopbits=STOPBITS_ONE,
    xonxoff=False,
    rtscts=False
)

print(s)

img = np.zeros((240, 320, 3))

fp = open('output.bin', 'wb')

for i in range(0, TOTAL_BYTES):
    data = s.read(1)
    fp.write(data)
    data = int.from_bytes(data, byteorder='big')
    img[i // 320][i % 320][2] = data % 4 * 64
    data = (data - data % 4) // 4
    
    img[i // 320][i % 320][1] = data % 8 * 32
    data = (data - data % 8) // 8

    img[i // 320][i % 320][0] = data * 32
    # print(f'red: {img[i // 320][i % 320][0]}, green: {img[i // 320][i % 320][1]}, blue: {img[i // 320][i % 320][2]}')
fp.close()

image = to_image(img).resize((640, 480))
image.save('image.jpg')

