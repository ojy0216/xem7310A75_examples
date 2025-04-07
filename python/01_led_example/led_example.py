import time

import numpy as np
from mms_ok import XEM7310


def main():
    bitstream_path = r"../../bitstream/led_example.bit"

    with XEM7310(bitstream_path=bitstream_path) as fpga:
        for i in range(2**8):
            print(f"Setting LED : {np.binary_repr(i, width=8)}")
            fpga.SetLED(i)
            time.sleep(0.5)


if __name__ == "__main__":
    main()
