import time
import numpy as np
import secrets
from tqdm import tqdm
from bitslice import Bitslice

from mms_ok import XEM7310

def pack_dram_inst(is_dram: bool, is_read: bool, dram_addr: int, dram_wr_data: str):
    inst = Bitslice(value=0, size=256)

    if is_read:
        inst[128 - 1:0] = 0
    else:
        inst[128 - 1:0] = int(dram_wr_data, 16)
    inst[154 - 1:128] = dram_addr
    inst[154] = int(is_read)
    inst[155] = int(is_dram)

    return format(inst.value, f"0{256//4}X")

def main(num_addr, sequential=True):
    bitstream_path = r"../../bitstream/my_ddr_test.bit"

    """ DATA GEN """
    data_dict = {}
    for addr in range(num_addr):
        data_dict[addr] = secrets.token_hex(nbytes=(128//8)).upper()
    
    with XEM7310(bitstream_path=bitstream_path) as fpga:
        fpga.reset()

        time.sleep(2)

        """ DRAM WRITE """
        for addr, data in tqdm(data_dict.items(), desc="DRAM WRITE", unit="addr"):
            inst = pack_dram_inst(
                is_dram=True,
                is_read=False,
                dram_addr=addr,
                dram_wr_data=data
            )
            fpga.WriteToBlockPipeIn(ep_addr=0x80, data=inst)
        
        """ DRAM READ """
        len_addr = len(str(num_addr))

        read_addr = list(range(num_addr))
        if not sequential:
            np.random.shuffle(read_addr)
        
        dram_correct = 0
        for addr in read_addr:
            inst = pack_dram_inst(
                is_dram=True,
                is_read=True,
                dram_addr=addr,
                dram_wr_data=None
            )
            fpga.WriteToBlockPipeIn(ep_addr=0x80, data=inst)

            read_data = fpga.ReadFromBlockPipeOut(ep_addr=0xA0, data=128//8)

            if data_dict[addr] == read_data:
                dram_correct += 1
            else:
                print(f"DRAM ADDR [{addr:{len_addr}}] FAILED")
                print(f"Read: {read_data} | Answer: {data_dict[addr]}\n")

            
        print(f"DRAM TEST PASSED [{dram_correct}/{num_addr}]")

        print()
        print("=== TEST SUMMARY ===")
        print(f"DRAM ADDR TEST PASSED [{dram_correct}/{num_addr}]")
        print()

if __name__ == "__main__":
    main(num_addr=1000, sequential=False)
