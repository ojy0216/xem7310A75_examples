import numpy as np
from mms_ok import XEM7310


def main():
    bitstream_path = r"../../bitstream/wire_example.bit"

    with XEM7310(bitstream_path=bitstream_path) as fpga:
        data0 = np.random.randint(0, 2**8)
        data1 = np.random.randint(0, 2**8)

        OP_AND = 0
        OP_OR = 1

        op_select = OP_OR

        op_result = (data0 | data1) if op_select == OP_OR else (data0 & data1)

        print(f"=== SW Result ===")
        print(f"data0     : {np.binary_repr(data0, width=8)}")
        print(f"data1     : {np.binary_repr(data1, width=8)}")
        print(f"op        : {'OR' if op_select == OP_OR else 'AND'}")
        print(f"op_result : {np.binary_repr(op_result, width=8)}")

        fpga.SetWireInValue(0x00, data0)
        fpga.SetWireInValue(0x01, data1)
        fpga.SetWireInValue(0x02, op_select)

        or_result = fpga.GetWireOutValue(0x20)
        and_result = fpga.GetWireOutValue(0x21)

        print(f"=== HW Result ===")
        print(f"OR  result: {np.binary_repr(or_result, width=8)}")
        print(f"AND result: {np.binary_repr(and_result, width=8)}")
        print()


if __name__ == "__main__":
    main()
