from mms_ok import XEM7310


def single_transfer(fpga, reorder_str: bool = True):
    data = "000102030405060708090A0B0C0D0E0F"
    print(f"Data: {data} [{type(data)}]")

    write_transfer_byte = fpga.WriteToPipeIn(0x80, data, reorder_str=reorder_str)
    print(f"Write transfer byte: {write_transfer_byte} Bytes")

    read_data = fpga.ReadFromPipeOut(0xA0, 128 // 8, reorder_str=reorder_str)
    print(f"Read data: {read_data} [{type(read_data)}]")
    print(f"Read transfer byte: {read_data.transfer_byte} Bytes")


def multiple_transfer(fpga, num_transfer: int, reorder_str: bool = True):
    from secrets import token_hex

    data = {i: token_hex(128 // 8).upper() for i in range(num_transfer)}

    for i in range(num_transfer):
        print(f"[Transfer {i}] Data: {data[i]} [{type(data[i])}]")

        write_transfer_byte = fpga.WriteToPipeIn(0x80, data[i], reorder_str=reorder_str)
        print(f"[Transfer {i}] Write transfer byte: {write_transfer_byte} Bytes")

    read_data_list = []

    for i in range(num_transfer):
        read_data = fpga.ReadFromPipeOut(0xA0, 128 // 8, reorder_str=reorder_str)
        print(f"[Transfer {i}] Read data: {read_data} [{type(read_data)}]")
        print(f"[Transfer {i}] Read transfer byte: {read_data.transfer_byte} Bytes")

        read_data_list.append(read_data.hex_data)

    correct = 0
    for i in range(num_transfer):
        if data[i] == read_data_list[i]:
            correct += 1

    print()
    print("===== Test Result =====")
    print(f"Correct: {correct} / {num_transfer}")
    print()


def main():
    bitstream_path = r"../../bitstream/fifo_example.bit"

    with XEM7310(bitstream_path=bitstream_path) as fpga:
        fpga.reset()

        # single_transfer(fpga)
        multiple_transfer(fpga, num_transfer=100)


if __name__ == "__main__":
    main()
