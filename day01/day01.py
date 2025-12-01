import sys


def part1(f: str) -> int:
    actions = list(map(lambda x: (x[0], int(x[1:])), open(f).readlines()))
    count = 0
    pos = 50
    for a in actions:
        d, n = a
        d = 1 if d == 'L' else -1
        pos += n*d
        pos %= 100
        if pos == 0:
            count += 1
    return count


def part2(f: str) -> int:
    actions = list(map(lambda x: (x[0], int(x[1:])), open(f).readlines()))
    count = 0
    pos = 50
    for a in actions:
        d, n = a
        d = 1 if d == 'L' else -1
        count += n//100
        n %= 100
        for _ in range(n):
            pos = (pos+d) % 100
            if pos == 0:
                count += 1
    return count


if __name__ == "__main__":
    print(part1(sys.argv[1]))

    print(part2(sys.argv[1]))
