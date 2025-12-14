import math

from collections import defaultdict
from functools import lru_cache
from itertools import combinations


def get_proper_divisors(n: int) -> list[int]:
    divisors = set()
    for i in range(1, int(math.sqrt(n)) + 1):
        if n % i == 0:
            divisors.add(i)
            if i**2 != n:
                divisors.add(n // i)
    divisors.remove(n)
    return sorted(list(divisors))


def get_maximal_proper_divisors(n: int) -> list[int]:
    proper_divs = get_proper_divisors(n)
    max_pds = []
    for d1 in proper_divs:
        is_max = True
        for d2 in proper_divs:
            if d1 != d2 and d2 % d1 == 0:
                is_max = False
                break
        if is_max:
            max_pds.append(d1)
    return max_pds


# @lru_cache(None)
def get_periods_and_ops(D: int) -> list[tuple[int, int]]:
    ops = [
        [],
        [(1, 1)],
        [(1, 1)],
        [(2, 1)],
        [(1, 1)],
        [(2, 1), (3, 1), (1, -1)],
        [(1, 1)],
        [(4, 1)],
        [(3, 1)],
        [(2, 1), (5, 1), (1, -1)],
        [(1, 1)],
        [(4, 1), (6, 1), (2, -1)],
        [(1, 1)],
        [(2, 1), (7, 1), (1, -1)],
        [(3, 1), (5, 1), (1, -1)],
        [(8, 1)],
        [(1, 1)],
        [(6, 1), (9, 1), (3, -1)],
        [(1, 1)],
    ]
    return ops[D - 1]
    # # code to actually compute these values:
    # # can just use a lookup table to avoid repeated work, since assuming i64s,
    # # then we always have the inequality: D <= 20
    # # code:
    # max_pds = get_maximal_proper_divisors(D)
    # ops = []  # (length, sign) tuples

    # for i in range(1, len(max_pds) + 1):
    #     for c in combinations(max_pds, i):
    #         L = math.gcd(*c)
    #         sign = 1 if i % 2 else -1
    #         ops.append((L, sign))

    # # combine coeffs that are for the same length
    # coeffs = defaultdict(int)
    # for L, s in ops:
    #     coeffs[L] += s
    # final_ops = []
    # for L, s in coeffs.items():
    #     if c != 0:
    #         final_ops.append((L, s))
    # return final_ops


def sum_series(lo: int, hi: int) -> int:
    # S_n = n * (a_1 + a_n) / 2 where:
    # n is number of terms being added
    # a_1 is first term
    # a_n is final term
    # since all terms are one after the other, n = (a_n - a_1 + 1)
    return (hi - lo + 1) * (lo + hi) // 2


def solve_period_range(D: int, L: int, lo: int, hi: int) -> int:
    # get multiplier:
    mult = 0
    for i in range(20):
        if (i + 1) * L <= D:
            mult += 10 ** (i * L)
    if not mult:
        return 0

    # get bounds for range:
    lower = max(math.ceil(lo / mult), 10 ** (L - 1))
    upper = min(math.floor(hi / mult), 10 ** (L) - 1)

    return mult * sum_series(lower, upper)


def solve_range(lo: int, hi: int) -> int:
    total = 0

    # split into ranges of the same digit length:
    current = lo
    while current <= hi:
        current_str = str(current)
        D = len(current_str)
        limit = 10**D - 1  # 9999..9 (D times)
        current_range_end = min(hi, limit)

        # calculate sum for range from current -> current_range_end with D digits:
        ops = get_periods_and_ops(D)

        temp_sum = 0
        for length, sign in ops:
            val = solve_period_range(D, length, current, current_range_end)
            temp_sum += val * sign

        total += temp_sum
        current = 10**D
    return total


def part2(filename: str) -> int:
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
        print("Usage: python3 day02_p2_optimised.py <filename>")
    start_time = time.time()

    total = part2(sys.argv[1])

    end_time = time.time()
    print(f"Total: {total}")
    print(f"Duration: {(end_time - start_time) * (10**6)}uS")


if __name__ == "__main__":
    main()
