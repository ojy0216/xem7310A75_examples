import numpy as np
from mms_ok import XEM7310


def main():
    bitstream_path = r"../../bitstream/trigger_example.bit"

    with XEM7310(bitstream_path=bitstream_path) as fpga:
        fpga.reset()

        data = np.random.randint(0, 2**13, size=8, dtype=np.uint16)
        print(f"Data: {data}")
        ans = np.sum(data)
        print(f"Answer: {ans}")

        fpga.WriteToPipeIn(0x80, data)

        fpga.ActivateTriggerIn(0x40, 0)
        print("Triggered!")

        fpga.CheckTriggered(0x60, 0x1, timeout=1)

        read_data = fpga.ReadFromPipeOut(0xA0, 16).to_ndarray(np.uint16)
        print(f"Read data: {read_data[-2]} | Answer: {ans}")


if __name__ == "__main__":
    main()
