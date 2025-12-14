def sum_series(lo: int, hi: int) -> int:
    return (hi - lo + 1) * (lo + hi) // 2


def solve_range(lo: int, hi: int) -> int:
    total = 0
    current = lo

    while current <= hi:
        currentStr = str(current)
        D = len(currentStr)
        limit = 10**D - 1
        current_range_end = min(hi, limit)

        if D % 2:
            current = current_range_end + 1
            continue

        # only even length numbers need to be considered:
        L = D // 2
        M = 10**L + 1

        lower = max((current + M - 1) // M, 10 ** (L - 1))
        upper = min(current_range_end // M, 10**L - 1)
        if upper >= lower:
            total += M * sum_series(lower, upper)
        current = current_range_end + 1
    return total


def part1(filename: str) -> int:
    with open(filename, "r") as f:
        data = f.read().strip()

    parts = data.replace("\n", ",").split(",")
    total = 0
    for p in parts:
        lo, hi = p.split("-")
        total += solve_range(int(lo), int(hi))
    return total


def main():
    import sys
    import time

    if len(sys.argv) != 2:
        print("Usage: python3 day02_p1_optimised.py <filename>")
    start_time = time.time()

    total = part1(sys.argv[1])

    end_time = time.time()
    print(f"Total: {total}")
    print(f"Duration: {(end_time - start_time) * (10**6)}uS")


if __name__ == "__main__":
    main()
