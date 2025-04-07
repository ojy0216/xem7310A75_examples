from secrets import token_hex
from time import perf_counter_ns, sleep

from mms_ok import XEM7310
from rich.console import Console
from rich.panel import Panel
from rich.progress import (
    BarColumn,
    Progress,
    SpinnerColumn,
    TaskProgressColumn,
    TextColumn,
    TimeRemainingColumn,
    TransferSpeedColumn,
)
from rich.table import Table

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


def write_test(fpga, num_transfer, progress=None, task_id=None):
    data = [token_hex(nbytes=(128 // 8)) for _ in range(num_transfer)]
    total_bytes = 0

    start = perf_counter_ns()
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TaskProgressColumn(),
        TimeRemainingColumn(),
        TextColumn("{task.fields[speed]}"),
        console=console,
    ) as progress:
        task = progress.add_task("Writing...", total=num_transfer, speed="")
        for i in range(num_transfer):
            transfer_byte = fpga.WriteToPipeIn(0x80, data[i], reorder_str=True)
            total_bytes += transfer_byte
            progress.advance(task)
            # Update transfer rate in progress description
            current_duration = perf_counter_ns() - start
            current_rate = (total_bytes / current_duration) * 1e9
            progress.update(task, speed=f"{format_bytes(current_rate)}/s")
    end = perf_counter_ns()

    duration = end - start
    transfer_rate = total_bytes / duration * 1e9

    print(f"Total bytes: {format_bytes(total_bytes)}")
    print(f"Duration: {duration} ns")
    print(f"Transfer rate: {format_bytes(transfer_rate)}/s")
    print()

    return transfer_rate


def bulk_write_test(fpga, num_bytes):
    data = token_hex(nbytes=num_bytes)
    start = perf_counter_ns()

    with console.status("[bold green]Performing bulk write...") as status:
        transfer_byte = fpga.WriteToPipeIn(0x80, data, reorder_str=True)

    end = perf_counter_ns()
    duration = end - start
    transfer_rate = transfer_byte / duration * 1e9

    print(f"Total bytes: {format_bytes(transfer_byte)}")
    print(f"Duration: {duration} ns")
    print(f"Transfer rate: {format_bytes(transfer_rate)}/s")
    print()

    return transfer_rate


def read_test(fpga, num_transfer, progress=None, task_id=None):
    total_bytes = 0
    start = perf_counter_ns()

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TaskProgressColumn(),
        TimeRemainingColumn(),
        TextColumn("{task.fields[speed]}"),
        console=console,
    ) as progress:
        task = progress.add_task("Reading...", total=num_transfer, speed="")
        for _ in range(num_transfer):
            read_data = fpga.ReadFromPipeOut(0xA0, 128 // 8, reorder_str=True)
            total_bytes += read_data.transfer_byte
            progress.advance(task)
            # Update transfer rate in progress description
            current_duration = perf_counter_ns() - start
            current_rate = (total_bytes / current_duration) * 1e9
            progress.update(task, speed=f"{format_bytes(current_rate)}/s")

    end = perf_counter_ns()
    duration = end - start
    transfer_rate = total_bytes / duration * 1e9

    print(f"Total bytes: {format_bytes(total_bytes)}")
    print(f"Duration: {duration} ns")
    print(f"Transfer rate: {format_bytes(transfer_rate)}/s")
    print()

    return transfer_rate


def bulk_read_test(fpga, num_bytes):
    start = perf_counter_ns()
    with console.status("[bold green]Performing bulk read...") as status:
        read_data = fpga.ReadFromPipeOut(0xA0, num_bytes, reorder_str=True)

    end = perf_counter_ns()
    duration = end - start
    transfer_rate = read_data.transfer_byte / duration * 1e9

    print(f"Total bytes: {format_bytes(read_data.transfer_byte)}")
    print(f"Duration: {duration} ns")
    print(f"Transfer rate: {format_bytes(transfer_rate)}/s")
    print()

    return transfer_rate


def main():
    bitstream_path = r"../../bitstream/pipe_speedtest.bit"

    num_tests = 1
    num_transfer = 10_000
    num_bytes = 10 * 1024 * 1024

    write_rates = []
    bulk_write_rates = []
    read_rates = []
    bulk_read_rates = []

    with XEM7310(bitstream_path=bitstream_path) as fpga:
        fpga.reset()

        # Write tests
        for i in range(num_tests):
            console.print(Panel(f"[bold green]Write Test {i+1} of {num_tests}"))
            write_rates.append(write_test(fpga, num_transfer=num_transfer))
            sleep(1)

        # Bulk write tests
        for i in range(num_tests):
            console.print(Panel(f"[bold green]Bulk Write Test {i+1} of {num_tests}"))
            bulk_write_rates.append(bulk_write_test(fpga, num_bytes=num_bytes))
            sleep(1)

        # Read tests
        for i in range(num_tests):
            console.print(Panel(f"[bold green]Read Test {i+1} of {num_tests}"))
            read_rates.append(read_test(fpga, num_transfer=num_transfer))
            sleep(1)

        # Bulk read tests
        for i in range(num_tests):
            console.print(Panel(f"[bold green]Bulk Read Test {i+1} of {num_tests}"))
            bulk_read_rates.append(bulk_read_test(fpga, num_bytes=num_bytes))
            sleep(1)

        # Create results table
        table = Table(title="Test Results Summary")
        table.add_column("Test Type", style="cyan")
        table.add_column("Min Speed", justify="right", style="green")
        table.add_column("Max Speed", justify="right", style="green")
        table.add_column("Average Speed", justify="right", style="green")

        # Add rows for each test type
        table.add_row(
            "Write Test",
            format_bytes(min(write_rates)),
            format_bytes(max(write_rates)),
            format_bytes(sum(write_rates) / len(write_rates)),
        )
        table.add_row(
            "Bulk Write Test",
            format_bytes(min(bulk_write_rates)),
            format_bytes(max(bulk_write_rates)),
            format_bytes(sum(bulk_write_rates) / len(bulk_write_rates)),
        )
        table.add_row(
            "Read Test",
            format_bytes(min(read_rates)),
            format_bytes(max(read_rates)),
            format_bytes(sum(read_rates) / len(read_rates)),
        )
        table.add_row(
            "Bulk Read Test",
            format_bytes(min(bulk_read_rates)),
            format_bytes(max(bulk_read_rates)),
            format_bytes(sum(bulk_read_rates) / len(bulk_read_rates)),
        )

        console.print("\n")
        console.print(table)

    """ Just for plotting """
    # import numpy as np

    # np.save(f"bulk_write_rates_{format_bytes(num_bytes)}.npy", np.array(bulk_write_rates))
    # np.save(f"bulk_read_rates_{format_bytes(num_bytes)}.npy", np.array(bulk_read_rates))


if __name__ == "__main__":
    main()
