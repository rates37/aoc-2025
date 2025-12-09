package day09;

import java.io.IOException;
import java.lang.System;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class day09 {
    public static void main(String[] args) throws IOException {
        String filename = args[0];
        System.out.println("Reading from file: " + filename);
        List<String> lines = Files.readAllLines(Paths.get(filename));
        List<long[]> points = new ArrayList<>();
        for (String line : lines) {
            String[] splitLine = line.split(",");
            points.add(new long[] { Long.valueOf(splitLine[0]), Long.valueOf(splitLine[1]) });
        }

        System.out.println("Part 1: " + part1(points));
        System.out.println("Part 2: " + part2(points));
    }

    static private long part1(List<long[]> points) {
        long bestArea = 0;
        for (int i = 0; i < points.size(); i++) {
            for (int j = 0; j < i; j++) {
                long area = (1 + Math.abs(points.get(i)[0] - points.get(j)[0]))
                          * (1 + Math.abs(points.get(i)[1] - points.get(j)[1]));
                if (area > bestArea) {
                    bestArea = area;
                }
            }
        }
        return bestArea;
    }

    static private long part2(List<long[]> points) {
        List<long[][]> segments = build_segments(points);
        long bestArea = 0;

        for (int i = 0; i < points.size(); i++) {
            long[] p1 = points.get(i);
            long x1 = p1[0];
            long y1 = p1[1];

            for (int j = 0; j < i; j++) {
                long[] p2 = points.get(j);
                long x2 = p2[0];
                long y2 = p2[1];

                // assuming all points are unique
                long w = Math.abs(x2 - x1) + 1;
                long h = Math.abs(y2 - y1) + 1;
                long area = w * h;

                if (area > bestArea && is_rect_in_poly(p1, p2, segments)) {
                    bestArea = area;
                }
            }
        }

        return bestArea;
    }

    static private List<long[][]> build_segments(List<long[]> points) {
        List<long[][]> segments = new ArrayList<>();
        for (int i = 0; i < points.size(); i++) {
            segments.add(new long[][] { points.get(i), points.get((i + 1) % points.size()) });
        }
        return segments;
    }

    static private boolean is_rect_in_poly(long[] p1, long[] p2, List<long[][]> segments) {
        long x1 = p1[0];
        long y1 = p1[1];
        long x2 = p2[0];
        long y2 = p2[1];

        long minX = Math.min(x1, x2);
        long minY = Math.min(y1, y2);
        long maxX = Math.max(x1, x2);
        long maxY = Math.max(y1, y2);

        // check if any segments cut the rectangle:
        for (long[][] s : segments) {
            long sx1 = s[0][0];
            long sy1 = s[0][1];
            long sx2 = s[1][0];
            long sy2 = s[1][1];

            if (sx1 == sx2) { // if vertical segment
                if (sx1 > minX && sx1 < maxX) {
                    long syMin = Math.min(sy1, sy2);
                    long syMax = Math.max(sy1, sy2);
                    if (Math.max(minY, syMin) < Math.min(maxY, syMax)) {
                        return false;
                    }
                }
            } else {
                // horizontal segment
                if (sy1 > minY && sy1 < maxY) {
                    long sxMin = Math.min(sx1, sx2);
                    long sxMax = Math.max(sx1, sx2);
                    if (Math.max(minX, sxMin) < Math.min(maxX, sxMax)) {
                        return false;
                    }
                }
            }
        }

        // do raycasting approach:
        // if crosses even number of edges, outside polygon
        // if crosses odd number of edges, inside polygon
        double cx = (minX + maxX) / 2.0;
        double cy = (minY + maxY) / 2.0;

        int intersectionCount = 0;

        for (long[][] s : segments) {
            long sx1 = s[0][0];
            long sy1 = s[0][1];
            long sx2 = s[1][0];
            long sy2 = s[1][1];

            if (sx1 == sx2) {
                double ex = sx1;
                if (ex > cx) {
                    double syMin = Math.min(sy1, sy2);
                    double syMax = Math.max(sy1, sy2);
                    if (cy > syMin && cy < syMax) {
                        intersectionCount++;
                    }
                }
            }
        }

        return intersectionCount % 2 == 1;
    }
}
