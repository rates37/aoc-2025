const fs = require("node:fs");
const { exit } = require("node:process");
const args = process.argv.slice(2);

/**
 * @param {object} counter - The counter to add to.
 * @param {Number} key - the key to increment / add
 * @param {Number} value - the number of increase counter[key] by
 */
function counterAdd(counter, key, value) { // using this object like a defaultdict(int) in Python
    if (counter[key]) {
        counter[key] += value;
    } else {
        counter[key] = value;
    }
}

/**
 * @param {string} data - The contents of the input file.
 */
function solve(data) {
    const lines = data.split("\n");
    let tachyonPos = { [lines[0].indexOf("S")]: 1 };

    let splitCount = 0;
    // iterate over the rest of the map:
    for (let i = 1; i < lines.length; i++) {
        let nextTachyonPos = {};

        for (const tIdx in tachyonPos) {
            const pos = Number(tIdx);
            if (lines[i][pos] == ".") {
                // do nothing
                counterAdd(nextTachyonPos, pos, tachyonPos[tIdx]);
                // nextTachyonPos.add(tIdx);
            } else if (lines[i][pos] == "^") {
                splitCount++;

                // split before and after:
                const after = pos - 1;
                const before = pos + 1;
                if (after >= 0 && after < lines.length) {
                    counterAdd(nextTachyonPos, after, tachyonPos[tIdx]);
                }
                if (before >= 0 && before < lines.length) {
                    counterAdd(nextTachyonPos, before, tachyonPos[tIdx]);
                }
            }
        }
        tachyonPos = nextTachyonPos;
    }
    console.log(`Part 1: ${splitCount}`);
    console.log(
        `Part 2: ${Object.values(tachyonPos).reduce((a, v) => a + v, 0)}`
    );
}

if (args.length != 1) {
    console.log("Enter input filename as only command line argument.");
    exit(1);
}
fs.readFile(args[0], "utf8", (err, data) => {
    if (err) {
        console.error("Error reading file:", err);
        return;
    }
    solve(data);
});
