#!/bin/bash
# Steps:
# Process distances -> save to file
# -> sort rows based on distance 
# -> Run 1000 iterations of Kruskal's
# -> bubble sort counts for 3 iterations to get 3 largest groups
awk -F, ' # awk -F, uses comma as delimiter
{
  x[NR]=$1; y[NR]=$2; z[NR]=$3;
}
END{
  for(i=1;i<=NR;i++) {
    for(j=1;j<i;j++) {
      dx = x[i]-x[j]
      dy = y[i]-y[j]
      dz = z[i]-z[j]
      dist = dx*dx + dy*dy + dz*dz
      print dist, i, j
    }
  }
}
' "$1" | sort -n | awk -v pts="$1" '
# union find functions:
function find(x) { if (UF[x] != x) UF[x] = find(UF[x]); return UF[x] }
function union(x,y) { rx = find(x); ry = find(y); if (rx != ry) UF[ry] = rx } # could optimise with path compression but this is already such a meme

BEGIN {
  # Load points from file
  FS = ","
  while ((getline line < pts) > 0) {
    split(line, tmpArray, ",")
    px[++n] = tmpArray[1]; py[n] = tmpArray[2]; pz[n] = tmpArray[3]
    UF[n] = n
  }
  close(pts)
}

{
  # Parse sorted edge line: "dist i j"
  split($0, e, /[[:space:]]+/)
  i = e[2]; j = e[3]

  counts++
  if (find(i) != find(j)) {
    union(i, j)
  }

  if (counts == 1000) {
    # Compute component sizes
    for (k = 1; k <= n; k++) {
      root = find(k)
      size[root]++
    }

    # Copy to sizes[] array
    count = 0
    for (r in size) sizes[++count] = size[r]

    # bubble sort style find 3 largest elements:
    for (a = 1; a <= 3; a++)
      for (b = a + 1; b <= count; b++)
            if (sizes[b] > sizes[a]) {  # <-- LARGEST first
              t = sizes[a]; sizes[a] = sizes[b]; sizes[b] = t
            }

    # Product of top 3
    print sizes[1] * sizes[2] * sizes[3]
    exit
  }
}
'
