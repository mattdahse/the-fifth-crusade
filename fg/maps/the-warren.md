# The Warren

<!-- id: warren -->
<!-- image: images/the-warren.webp -->
<!-- grid: on -->
<!-- gridtype: square -->
<!-- gridsize: 40 -->
<!-- scale: one square - five feet -->

**Below the nest.** The galleries the fiendish ants have dug under the Sarkorian manor in a year:
a web of passages and small chambers, crowded with workers, running west to the queen's chamber
and east toward Drezen. Reached from [the cellar](the-cellar.md) by the passage that leaves the
nest going down; it comes in at the **top-right** of this plate.

## The plate

A 1536 × 1024 generation, trimmed 12 px top and bottom and reflect-padded 32 px each side to
**1600 × 1000**: **40 × 25 squares at 40 px, 200 × 125 ft**.

**The grid is 40 px, not 50, on purpose.** The galleries are painted about 40 px wide, and at
50 px a square they came out four feet across and `passable.py` found no token could move through
the web. At 40 px every gallery is one square: one ant wide, which is what a bored tunnel is. The left 32 px are mirrored padding
and sit inside the outer wall, so nothing stands on them.

**What the art shows** (pixel ranges in brackets):

- **The queen's chamber**, the left third (x 30–530, y 60–930): a broad oval cavern, an egg mound
  in its middle (about 360,480), a natural **earth column** at about 180,475, and a spill of
  **scree** down its upper-left wall. Its mouth opens east into the galleries at about 540,450.
- **The two timber props**, upper (posts at 205,250 and 425,250) and lower (posts at 205,725 and
  425,725): squared pit-props with a crossbeam, set by the Labyrinth's men. **The posts are
  occluders**, small solid squares; the crossbeam is overhead and blocks nothing.
- **The nursery**, top centre (x 760–1050, y 20–260): grubs in rows, and eggs.
- **The larder**, bottom centre (x 690–960, y 660–960): bones, rags and husks. Where the workers
  carry everything that does not belong.
- **The entry**, top right, off the right edge at about y 60–110: the passage up to the nest.
- **The road east**, bottom right, off the right edge at about y 790–890, shored with timber.

## Shortcuts

<!-- shortcut: book:84_the_galleries @ 1100,450 | G1. The Galleries -->
<!-- shortcut: book:85_the_nursery @ 905,150 | G2. The Nursery -->
<!-- shortcut: book:86_the_larder @ 825,815 | G3. The Larder -->
<!-- shortcut: book:87_the_road_east @ 1475,840 | G4. The Road East -->
<!-- shortcut: book:88_the_queens_chamber @ 300,600 | G5. The Queen's Chamber -->
<!-- shortcut: book:89_bringing_down_the_roof @ 320,250 | G6. Bringing Down the Roof -->

## Occluders

Traced from the plate with OpenCV, not by `trace-occluders.py`: that tool follows only a region's
outer edge, and this map is mostly rock *islands* between galleries, which have to block sight
too. The method: red-minus-blue (the warm channel, as for the cellar), Gaussian blur 4, threshold
36, a 9 px open and close to drop specks, a **29 px** dilation so the wall line sits well into the
rock, then `findContours` with `RETR_CCOMP` (outer boundary and holes alike), rings under 1,800 px²
dropped, simplified at 7 px. Seventeen rings: the outer wall and the rock islands.

**The dilation is large on purpose, and it was tuned against `passable.py`.** At 7 px the walls
followed the paint exactly and the checker split the web into eleven pieces no token could cross;
at 25 it was still three. At 29 every token reaches every other. The cost is that the walls sit a
little inside the painted rock, and the timber props are no longer solid: rule at the table that
nobody walks through a post.

<!-- occluder: 0,887 1,979 19,968 30,929 16,895 0,887 -->
<!-- occluder: 0,118 0,251 22,247 17,218 31,206 60,265 32,299 0,279 0,755 28,729 32,686 36,730 61,764 63,803 99,837 93,875 58,884 34,927 46,970 66,988 100,994 146,971 158,942 148,903 155,886 190,911 301,917 406,864 441,901 560,938 611,999 656,999 676,970 670,944 626,919 637,892 658,925 731,981 800,999 904,990 938,968 988,906 993,933 970,966 982,999 1044,998 1062,970 1057,922 1121,901 1170,928 1216,937 1327,928 1376,908 1410,909 1431,922 1599,918 1599,782 1498,775 1467,786 1401,777 1310,796 1251,771 1267,734 1335,712 1361,684 1453,673 1495,634 1524,588 1532,540 1522,502 1489,480 1463,416 1415,383 1452,367 1468,346 1471,325 1451,294 1416,288 1386,302 1361,369 1311,384 1296,400 1276,387 1275,369 1319,313 1364,287 1376,209 1402,184 1468,166 1543,122 1599,122 1598,28 1537,28 1405,105 1387,67 1353,55 1315,6 1235,0 1188,35 1167,78 1172,117 1154,121 1144,106 1146,47 1131,27 1096,18 1067,45 1070,67 1095,94 1092,125 1105,146 1086,182 1073,177 1075,145 1049,58 977,0 853,0 802,21 753,71 732,160 698,148 656,80 615,68 617,57 656,62 680,49 685,22 668,0 584,14 558,53 556,75 536,67 532,26 511,0 430,0 400,42 403,78 422,109 461,125 508,115 618,138 611,160 567,157 534,174 513,214 448,143 394,120 340,75 259,69 267,37 322,14 328,0 226,0 195,48 140,23 94,37 77,66 78,99 39,143 41,182 32,195 21,166 25,143 0,118 -->
<!-- occluder: 466,816 500,786 525,740 559,736 594,784 638,805 646,848 637,871 633,833 618,810 567,785 521,799 492,847 475,845 466,816 -->
<!-- occluder: 1161,690 1183,695 1195,715 1162,777 1170,846 1149,836 1123,792 1095,780 1130,773 1154,754 1161,690 -->
<!-- occluder: 1087,613 1115,643 1105,656 1078,651 1045,661 1024,694 1022,723 1047,764 1096,779 1038,785 1013,800 1008,718 958,671 961,644 1087,613 -->
<!-- occluder: 1204,601 1259,592 1272,634 1295,659 1258,673 1236,643 1189,623 1204,601 -->
<!-- occluder: 776,620 689,658 648,728 628,724 627,705 684,625 680,587 740,588 776,620 -->
<!-- occluder: 644,517 666,575 633,550 589,566 573,610 602,646 571,670 542,670 589,520 644,517 -->
<!-- occluder: 951,490 977,516 1057,539 960,564 946,544 951,490 -->
<!-- occluder: 1169,487 1171,546 1147,572 1074,541 1136,509 1157,484 1169,487 -->
<!-- occluder: 1338,455 1354,434 1384,432 1408,444 1420,465 1375,462 1340,477 1338,455 -->
<!-- occluder: 797,399 795,442 812,464 760,484 732,523 715,525 709,492 754,463 778,406 797,399 -->
<!-- occluder: 961,343 1007,364 956,392 938,432 948,473 922,437 891,425 930,404 943,380 944,346 961,343 -->
<!-- occluder: 1126,285 1137,284 1153,341 1208,375 1225,427 1267,462 1252,514 1231,531 1223,450 1174,418 1171,389 1146,346 1097,325 1126,285 -->
<!-- occluder: 1064,245 1036,290 1007,293 972,276 1028,234 1064,245 -->
<!-- occluder: 571,232 662,201 710,226 749,232 772,270 849,309 873,354 821,330 758,329 724,354 703,414 646,438 595,437 593,407 634,387 652,362 689,369 713,361 744,321 747,291 714,233 651,216 594,252 585,290 600,327 582,342 559,288 571,232 -->
<!-- occluder: 1344,135 1317,177 1308,234 1283,201 1249,185 1196,188 1151,219 1133,218 1148,186 1210,155 1268,159 1326,119 1344,135 -->
