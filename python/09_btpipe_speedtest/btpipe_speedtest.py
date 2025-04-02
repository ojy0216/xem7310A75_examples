from time import sleep, perf_counter_ns
from secrets import token_hex
from mms_ok import XEM7310

def format_bytes(bytes):
    if bytes < 1024:
        return f"{bytes} B"
    elif bytes < 1024 * 1024:
        return f"{bytes / 1024:.2f} KB"
    elif bytes < 1024 * 1024 * 1024:
        return f"{bytes / 1024 / 1024:.2f} MB"

def write_test(fpga, num_transfer):
    print("=== Write Test ===")

    data = [token_hex(nbytes=(128//8)) for _ in range(num_transfer)]

    total_bytes = 0

    start = perf_counter_ns()
    for i in range(num_transfer):
        transfer_byte = fpga.WriteToBlockPipeIn(0x80, data[i], reorder_str=True)
        total_bytes += transfer_byte
    end = perf_counter_ns()

    duration = end - start
    print(f"Total bytes: {format_bytes(total_bytes)}")
    print(f"Duration: {duration} ns")
    print(f"Transfer rate: {format_bytes(total_bytes / duration * 1e9)}/s")
    print()

def large_write_test(fpga, num_bytes):
    print("=== Large Write Test ===")

    data = token_hex(nbytes=num_bytes)

    start = perf_counter_ns()

    transfer_byte = fpga.WriteToBlockPipeIn(0x80, data, reorder_str=True)

    end = perf_counter_ns()

    duration = end - start
    print(f"Total bytes: {format_bytes(transfer_byte)}")
    print(f"Duration: {duration} ns")
    print(f"Transfer rate: {format_bytes(transfer_byte / duration * 1e9)}/s")
    print()

def read_test(fpga, num_transfer):
    print("=== Read Test ===")

    total_bytes = 0

    start = perf_counter_ns()

    for _ in range(num_transfer):
        read_data = fpga.ReadFromBlockPipeOut(0xA0, 128//8, reorder_str=True)
        total_bytes += read_data.transfer_byte

    end = perf_counter_ns()

    duration = end - start
    print(f"Total bytes: {format_bytes(total_bytes)}")
    print(f"Duration: {duration} ns")
    print(f"Transfer rate: {format_bytes(total_bytes / duration * 1e9)}/s")
    print()

def large_read_test(fpga, num_bytes):
    print("=== Large Read Test ===")

    start = perf_counter_ns()

    read_data = fpga.ReadFromBlockPipeOut(0xA0, num_bytes, reorder_str=True)

    end = perf_counter_ns()

    duration = end - start
    print(f"Total bytes: {format_bytes(read_data.transfer_byte)}")
    print(f"Duration: {duration} ns")
    print(f"Transfer rate: {format_bytes(read_data.transfer_byte / duration * 1e9)}/s")
    print()

def main():
    bitstream_path = r"../../bitstream/btpipe_speedtest.bit"

    with XEM7310(bitstream_path=bitstream_path) as fpga:
        fpga.reset()

        write_test(fpga, num_transfer=10_000)
        sleep(1)
        large_write_test(fpga, num_bytes=10 * 1024 * 1024)
        sleep(1)
        read_test(fpga, num_transfer=10)
        sleep(1)
        large_read_test(fpga, num_bytes=10 * 1024 * 1024)
    
if __name__ == "__main__":
    main()
