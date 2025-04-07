import numpy as np
from mms_ok import XEM7310


def text_transfer(fpga, reorder_str: bool = True):
    from secrets import token_hex

    data = token_hex(16)
    print(f"Data: {data} [{type(data)}]")

    transfer_byte = fpga.WriteToPipeIn(0x80, data, reorder_str=reorder_str)
    print(f"Transfer byte: {transfer_byte} bytes")

    read_data = fpga.ReadFromPipeOut(0xA0, 128 // 8, reorder_str=reorder_str)
    print(f"Read data: {read_data} [{type(read_data)}]")


def array_transfer(fpga):
    data = np.array([i for i in range(1, 16 + 1)], dtype=np.uint8)
    print(f"Data: {data} [{type(data)}]")

    transfer_byte = fpga.WriteToPipeIn(0x80, data)
    print(f"Transfer byte: {transfer_byte} bytes")

    read_data = fpga.ReadFromPipeOut(0xA0, 16)
    print(f"Read data: {read_data} [{type(read_data)}]")
    print(
        f"Read data: {read_data.to_ndarray(np.uint8)} [{type(read_data.to_ndarray(np.uint8))}]"
    )


def main():
    bitstream_path = r"../../bitstream/pipe_example.bit"

    with XEM7310(bitstream_path=bitstream_path) as fpga:
        fpga.reset()

        text_transfer(fpga, reorder_str=True)
        # array_transfer(fpga)


if __name__ == "__main__":
    main()
