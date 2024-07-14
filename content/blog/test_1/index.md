---
title:        Test 1
description:  Some formatting tests.
date:         2024-07-14
headerimage:  test_1/headerimage.webp
topic:        _
tags:         [ sql, appnote, ]
draft:        false
---

# Setup

![](img1.webp)
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f

alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
## Setup
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
### Setup
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
#### Setup
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f
alsdfa df dfasd fd fd fsdfa sdf sdfa sdfads f dfa sdfa f dsf as df asdf asd f

- We create two unique points each in b1 and b2, and two overlapping points in b1 and b2.
- We create two of each case to ensure our logic isn't accidentally working on only a single row.
- We add a note field so that we can follow the steps as we modify the data.

```sql
CREATE TABLE boats (
    id TEXT,
    ts TIMESTAMP,
    x FLOAT,
    y FLOAT,
    note TEXT
);

INSERT INTO boats (id, ts, x, y, note) VALUES
    ('b1', '2024-07-01', 10.0, 20.0, 'unique in b1'),
    ('b1', '2024-07-02', 30.0, 40.0, 'unique in b1'),
    ('b2', '2024-07-03', 50.0, 60.0, 'unique in b2'),
    ('b2', '2024-07-04', 70.0, 80.0, 'unique in b2'),
    ('b1', '2024-07-05', 91.0, 92.0, 'first common point'),
    ('b2', '2024-07-05', 93.0, 94.0, 'first common point'),
    ('b1', '2024-07-06', 95.0, 96.0, 'second common point'),
    ('b2', '2024-07-06', 97.0, 98.0, 'second common point');

select * from boats order by ts, id;
┌─────────┬─────────────────────┬───────┬───────┬─────────────────────┐
│   id    │         ts          │   x   │   y   │        note         │
├─────────┼─────────────────────┼───────┼───────┼─────────────────────┤
│ b1      │ 2024-07-01 00:00:00 │  10.0 │  20.0 │ unique in b1        │
│ b1      │ 2024-07-02 00:00:00 │  30.0 │  40.0 │ unique in b1        │
│ b2      │ 2024-07-03 00:00:00 │  50.0 │  60.0 │ unique in b2        │
│ b2      │ 2024-07-04 00:00:00 │  70.0 │  80.0 │ unique in b2        │
│ b1      │ 2024-07-05 00:00:00 │  91.0 │  92.0 │ first common point  │
│ b2      │ 2024-07-05 00:00:00 │  93.0 │  94.0 │ first common point  │
│ b1      │ 2024-07-06 00:00:00 │  95.0 │  96.0 │ second common point │
│ b2      │ 2024-07-06 00:00:00 │  97.0 │  98.0 │ second common point │
└─────────┴─────────────────────┴───────┴───────┴─────────────────────┘
```

# Basic Query

This inner self join is at the heart of the logic.  It returns the rows where b1 and b2 have a common timestamp, along with the averaged x and y values.

```sql
SELECT b1.ts,
       (b1.x + b2.x) / 2 AS avg_x,
       (b1.y + b2.y) / 2 AS avg_y
FROM boats b1
JOIN boats b2 ON b1.ts = b2.ts
WHERE b1.id = 'b1' AND b2.id = 'b2';
┌─────────────────────┬───────┬───────┐
│         ts          │ avg_x │ avg_y │
├─────────────────────┼───────┼───────┤
│ 2024-07-05 00:00:00 │  92.0 │  93.0 │
│ 2024-07-06 00:00:00 │  96.0 │  97.0 │
└─────────────────────┴───────┴───────┘
```

# Step 1: Coalesce the common time points between b1 and b2

Using the join logic above, we update the b1 rows with the averaged x and y values.  Later we will delete the leftover b2 rows.

```sql
BEGIN;

WITH averages AS (
    SELECT b1.ts,
           (b1.x + b2.x) / 2 AS avg_x,
           (b1.y + b2.y) / 2 AS avg_y
    FROM boats b1
    JOIN boats b2 ON b1.ts = b2.ts
    WHERE b1.id = 'b1' AND b2.id = 'b2'
)
UPDATE boats
SET x = avg_x, y = avg_y, note = 'averaged b1,b2'
FROM averages
WHERE boats.id = 'b1' AND boats.ts = averages.ts;
```

Note that we have updated the two overlapping rows with the proper averaged values.

```sql
┌─────────┬─────────────────────┬───────┬───────┬─────────────────────┐
│   id    │         ts          │   x   │   y   │        note         │
├─────────┼─────────────────────┼───────┼───────┼─────────────────────┤
│ b1      │ 2024-07-01 00:00:00 │  10.0 │  20.0 │ unique in b1        │
│ b1      │ 2024-07-02 00:00:00 │  30.0 │  40.0 │ unique in b1        │
│ b2      │ 2024-07-03 00:00:00 │  50.0 │  60.0 │ unique in b2        │
│ b2      │ 2024-07-04 00:00:00 │  70.0 │  80.0 │ unique in b2        │
│ b1      │ 2024-07-05 00:00:00 │  92.0 │  93.0 │ averaged b1,b2      │
│ b2      │ 2024-07-05 00:00:00 │  93.0 │  94.0 │ first common point  │
│ b1      │ 2024-07-06 00:00:00 │  96.0 │  97.0 │ averaged b1,b2      │
│ b2      │ 2024-07-06 00:00:00 │  97.0 │  98.0 │ second common point │
└─────────┴─────────────────────┴───────┴───────┴─────────────────────┘
```

Step 2: handle the unique points in b2.
We do this by renaming b2 to b1 for all the rows where there is not a common timestamp with b1.

```sql
UPDATE boats
SET id='b1', note='renamed from b2'
WHERE id = 'b2'
AND ts NOT IN (SELECT ts FROM boats WHERE id = 'b1');

┌─────────┬─────────────────────┬───────┬───────┬─────────────────────┐
│   id    │         ts          │   x   │   y   │        note         │
├─────────┼─────────────────────┼───────┼───────┼─────────────────────┤
│ b1      │ 2024-07-01 00:00:00 │  10.0 │  20.0 │ unique in b1        │
│ b1      │ 2024-07-02 00:00:00 │  30.0 │  40.0 │ unique in b1        │
│ b1      │ 2024-07-03 00:00:00 │  50.0 │  60.0 │ renamed from b2     │
│ b1      │ 2024-07-04 00:00:00 │  70.0 │  80.0 │ renamed from b2     │
│ b1      │ 2024-07-05 00:00:00 │  92.0 │  93.0 │ averaged b1,b2      │
│ b2      │ 2024-07-05 00:00:00 │  93.0 │  94.0 │ first common point  │
│ b1      │ 2024-07-06 00:00:00 │  96.0 │  97.0 │ averaged b1,b2      │
│ b2      │ 2024-07-06 00:00:00 │  97.0 │  98.0 │ second common point │
└─────────┴─────────────────────┴───────┴───────┴─────────────────────┘
```

Step 3: Delete the leftover b2 common rows.
```sql
DELETE FROM boats WHERE id = 'b2';
COMMIT;
```
Final Results
We can see that all cases have been handled properly, with the note column indicating which step modified each row.
all rows now belong to b1
unique b1 rows are unchanged
unique b2 rows are now b1 rows
b1/b2 rows with a common timestamp have been averaged.

```sql
select * from boats order by ts, id;
┌─────────┬─────────────────────┬───────┬───────┬─────────────────┐
│   id    │         ts          │   x   │   y   │      note       │
│ varchar │      timestamp      │ float │ float │     varchar     │
├─────────┼─────────────────────┼───────┼───────┼─────────────────┤
│ b1      │ 2024-07-01 00:00:00 │  10.0 │  20.0 │ unique in b1    │
│ b1      │ 2024-07-02 00:00:00 │  30.0 │  40.0 │ unique in b1    │
│ b1      │ 2024-07-03 00:00:00 │  50.0 │  60.0 │ renamed from b2 │
│ b1      │ 2024-07-04 00:00:00 │  70.0 │  80.0 │ renamed from b2 │
│ b1      │ 2024-07-05 00:00:00 │  92.0 │  93.0 │ averaged b1,b2  │
│ b1      │ 2024-07-06 00:00:00 │  96.0 │  97.0 │ averaged b1,b2  │
└─────────┴─────────────────────┴───────┴───────┴─────────────────┘
```
