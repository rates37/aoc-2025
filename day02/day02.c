#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// precompute powers of 10
uint64_t powerOf10[] = {1,
                        10,
                        100,
                        1000,
                        10000,
                        100000,
                        1000000,
                        10000000,
                        100000000,
                        1000000000,
                        10000000000,
                        100000000000,
                        1000000000000,
                        10000000000000,
                        100000000000000,
                        1000000000000000,
                        10000000000000000,
                        100000000000000000,
                        1000000000000000000};

uint64_t sum_doubled_in_range(uint64_t lo, uint64_t hi) {
    uint64_t count = 0;

    // max digit length to consider:
    int maxd = 1;
    while (powerOf10[2 * maxd] <= hi)
        maxd++;

    // loop over all half lengths:
    for (int d = 1; d <= maxd; d++) {
        uint64_t base = powerOf10[d];

        // find smallest lhs that can make a invalid number greater than lo
        uint64_t a = lo / (base + 1);
        if (a < powerOf10[d - 1]) a = powerOf10[d - 1];
        // find upper bound for number:
        uint64_t b = hi / (base + 1);
        if (b >= base) b = base - 1;

        if (a > b) continue;

        for (uint64_t l = a; l <= b; l++) {
            uint64_t ll = l * base + l;
            if (ll >= lo && ll <= hi) {
                count += ll;
            }
        }
    }

    return count;
}

int is_repeated(uint64_t n) {
    uint64_t temp = n;
    // get length of number:
    int d = 0;
    while (temp > 0) {
        temp /= 10;
        d++;
    }

    for (int l = 1; l < d; l++) {
        if (d % l != 0) continue;

        uint64_t digs = n / powerOf10[d - l];
        uint64_t repeatedDigs = digs;
        for (int i = 1; i < d / l; i++) {
            repeatedDigs *= powerOf10[l];
            repeatedDigs += digs;
        }
        if (repeatedDigs == n) return 1;
    }
    return 0;
}

uint64_t sum_n_ed_in_range(uint64_t lo, uint64_t hi) {
    uint64_t count = 0;

    // loop over all half lengths:
    for (int d = 1; d < 19; d++) { // 19 length of precomputed 10^N array
        if (powerOf10[d - 1] > hi) break;
        if (powerOf10[d] - 1 < lo) continue;

        // loop length n:
        for (int k = 2; k <= d; k++) {
            if (d % k != 0) continue;

            int dd = d / k;

            uint64_t base = powerOf10[dd];
            uint64_t block_min = powerOf10[dd - 1];
            uint64_t block_max = powerOf10[dd] - 1;

            if (powerOf10[d - 1] <= lo && lo <= powerOf10[d] - 1) {
                uint64_t first_block = lo / powerOf10[(k - 1) * dd];
                if (first_block > block_min) {
                    block_min = first_block;
                }
            }

            for (uint64_t x = block_min; x <= block_max; x++) {
                if (is_repeated(x)) continue;

                uint64_t kl = x;
                for (int i = 1; i < k; i++) {
                    if (kl > UINT64_MAX / base) {
                        perror("oops.");
                        exit(1);
                    }
                    kl *= base;
                    kl += x;
                }

                if (kl > hi) break;
                if (kl >= lo) {
                    count += kl;
                    // printf("%" PRIu64 ",", kl);
                }
            }
        }
    }
    //   printf("\n");
    return count;
}

int main(int argc, char *argv[]) {

    if (argc != 2) {
        perror("Provide filename as only command line argument.");
    }

    // open the file:
    FILE *f = fopen(argv[1], "r");
    if (!f) {
        perror("Unable to open file");
    }
    uint64_t total1 = 0;
    uint64_t total2 = 0;
    while (!feof(f)) {
        // read in first range:
        uint64_t lo;
        uint64_t hi;
        fscanf(f, "%" SCNu64, &lo);
        fgetc(f); // skip hyphen
        fscanf(f, "%" SCNu64, &hi);
        // optionally consume comma (needs to be optional since file doesn't end in comma)
        if (!feof(f)) fgetc(f);

        // find doubled numbers in range
        total1 += sum_doubled_in_range(lo, hi);
        // find n-repeated numbers in range
        total2 += sum_n_ed_in_range(lo, hi);
    }

    printf("Part 1: %" PRIu64 "\n", total1);
    printf("Part 2: %" PRIu64 "\n", total2);

    return 0;
}
