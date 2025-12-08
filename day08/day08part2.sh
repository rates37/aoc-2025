#!/bin/bash

# Steps:
# Process distances -> save to file
# -> sort rows based on distance 
# -> Fully run Kruskals to form single connected component
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


  # Kruskals:
  if (find(i) == find(j)) next
  connections++
  union(i, j)

  # When MST completes, print product of x-coordinates and exit
  if (connections == n - 1) {
    print px[i] * px[j]
    exit
  }
}
'
