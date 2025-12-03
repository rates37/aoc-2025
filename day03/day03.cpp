#include <cstdint>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

int get_bank_joltage(const std::string &s) {
    char m1 = s[0];
    int pos = 0;
    for (int i = 1; i < (int)s.length() - 1; i++) {
        if (s[i] > m1) {
            m1 = s[i];
            pos = i;
        }
    }
    char m2 = s[pos + 1];
    for (int i = pos + 1; i < (int)s.length(); i++) {
        if (s[i] > m2) {
            m2 = s[i];
        }
    }
    return (m1 - '0') * 10 + (m2 - '0');
}

uint64_t get_bank_joltage_n(const std::string &s, int n) {
    std::vector<char> selected(n);
    int pos = -1;

    for (int j = 0; j < n; j++) {
        char m = s[pos + 1];
        int mPos = pos + 1;

        for (int i = pos + 1; i < (int)s.length() - (n - j - 1); i++) {
            if (s[i] > m) {
                m = s[i];
                mPos = i;
            }
        }
        selected[j] = m;
        pos = mPos;
    }

    // combine output:
    uint64_t total = 0;
    for (char c : selected) {
        total *= 10;
        total += (c - '0');
    }
    return total;
}

int main(int argc, char *argv[]) {

    if (argc != 2) {
        perror("Provide filename as only command line argument.");
        exit(1);
    }

    // open the file:
    std::ifstream f(argv[1]);
    if (!f.is_open()) {
        perror("Unable to open file");
        exit(1);
    }
    std::string bank;
    uint64_t totalPart1 = 0;
    uint64_t totalPart2 = 0;
    while (std::getline(f, bank)) {
        totalPart1 += get_bank_joltage(bank);
        // std::cout << bank << ": " << get_bank_joltage_n(bank, 12) <<
        // std::endl;
        totalPart2 += get_bank_joltage_n(bank, 12);
    }
    std::cout << "Part 1: " << totalPart1 << std::endl;
    std::cout << "Part 1: " << totalPart2 << std::endl;

    return 0;
}