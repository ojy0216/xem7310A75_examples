import secrets
import time

import numpy as np
from bitslice import Bitslice
from mms_ok import XEM7310
from rich.console import Console
from rich.progress import (
    BarColumn,
    Progress,
    SpinnerColumn,
    TaskProgressColumn,
    TextColumn,
    TimeRemainingColumn,
    TransferSpeedColumn,
    track,
)
from rich.table import Table
from tqdm import tqdm

console = Console()


def format_bytes(bytes):
    if bytes < 1024:
        return f"{bytes} B"
    elif bytes < 1024 * 1024:
        return f"{bytes / 1024:.2f} KiB"
    elif bytes < 1024 * 1024 * 1024:
        return f"{bytes / 1024 / 1024:.2f} MiB"
    else:
        return f"{bytes / 1024 / 1024 / 1024:.2f} GiB"


def pack_dram_inst(is_dram: bool, is_read: bool, dram_addr: int, dram_wr_data: str):
    inst = Bitslice(value=0, size=256)

    if is_read:
        inst[128 - 1 : 0] = 0
    else:
        inst[128 - 1 : 0] = int(dram_wr_data, 16)
    inst[154 - 1 : 128] = dram_addr
    inst[154] = int(is_read)
    inst[155] = int(is_dram)

    return format(inst.value, f"0{256//4}X")


def main(num_addr, sequential=True):
    bitstream_path = r"../../bitstream/my_ddr_test.bit"

    """ DATA GEN """
    data_dict = {}
    for addr in range(num_addr):
        data_dict[addr] = secrets.token_hex(nbytes=(128 // 8)).upper()

    with XEM7310(bitstream_path=bitstream_path) as fpga:
        fpga.reset()

        time.sleep(2)

        """ DRAM WRITE """
        start_time = time.perf_counter_ns()
        total_bytes = 0

        target_bytes = (256 // 8) * num_addr

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
            TimeRemainingColumn(),
            TransferSpeedColumn(),
            console=console,
        ) as progress:
            task = progress.add_task(
                "[bold blue]DRAM WRITE", total=target_bytes, stats=""
            )

            for addr, data in data_dict.items():
                inst = pack_dram_inst(
                    is_dram=True, is_read=False, dram_addr=addr, dram_wr_data=data
                )
                write_bytes = fpga.WriteToBlockPipeIn(ep_addr=0x80, data=inst)

                # Update progress and calculate transfer rate
                total_bytes += write_bytes
                progress.update(task, completed=total_bytes)

        write_duration = time.perf_counter_ns() - start_time
        write_rate = (total_bytes / write_duration) * 1e9

        """ DRAM READ """
        len_addr = len(str(num_addr))

        read_addr = list(range(num_addr))
        if not sequential:
            np.random.shuffle(read_addr)

        dram_correct = 0
        start_time = time.perf_counter_ns()
        total_bytes = 0

        target_bytes = (128 // 8) * num_addr

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
            TimeRemainingColumn(),
            TransferSpeedColumn(),
            console=console,
        ) as progress:
            task = progress.add_task(
                "[bold red]DRAM READ ", total=target_bytes, stats=""
            )

            for addr in read_addr:
                inst = pack_dram_inst(
                    is_dram=True, is_read=True, dram_addr=addr, dram_wr_data=None
                )
                fpga.WriteToBlockPipeIn(ep_addr=0x80, data=inst)

                read_data = fpga.ReadFromBlockPipeOut(ep_addr=0xA0, data=128 // 8)

                if data_dict[addr] == read_data:
                    dram_correct += 1
                else:
                    print(f"DRAM ADDR [{addr:{len_addr}}] FAILED")
                    print(f"Read: {read_data} | Answer: {data_dict[addr]}\n")

                # Update progress and calculate transfer rate
                total_bytes += read_data.transfer_byte
                progress.update(task, completed=total_bytes)

        read_duration = time.perf_counter_ns() - start_time
        read_rate = (total_bytes / read_duration) * 1e9

        # Create a test summary table using Rich
        table = Table(title="DRAM Test Summary")
        table.add_column("Metric", style="cyan")
        table.add_column("Value", justify="right", style="green")

        # Add rows for each metric
        table.add_row("Total Addresses", f"{num_addr:,}")
        table.add_row("Sequential Access", "Yes" if sequential else "No")
        table.add_row("Write Transfer Rate", f"{format_bytes(write_rate)}/s")
        table.add_row("Read Transfer Rate", f"{format_bytes(read_rate)}/s")
        table.add_row("Write Duration", f"{write_duration/1e9:.2f} s")
        table.add_row("Read Duration", f"{read_duration/1e9:.2f} s")
        table.add_row("Total Bytes Written", f"{format_bytes((256 // 8) * num_addr)}")
        table.add_row("Total Bytes Read", f"{format_bytes((128 // 8) * num_addr)}")
        table.add_row("Correct Reads", f"{dram_correct:,}/{num_addr:,}")
        table.add_row("Success Rate", f"{(dram_correct/num_addr)*100:.2f}%")

        # Print the table
        console.print("\n")
        console.print(table)


if __name__ == "__main__":
    main(num_addr=10000, sequential=False)
