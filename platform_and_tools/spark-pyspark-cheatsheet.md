# Spark & PySpark Cheatsheet

> Quick reference for all key terms, concepts, and components of Apache Spark and PySpark.

---

## Architecture — Execution Model

```
Driver Program → SparkContext / SparkSession → DAG Scheduler → Task Scheduler → Cluster Manager → Executor (Worker) → Task → Partition
```

---

## Core Concepts

| Term | Description |
|------|-------------|
| **RDD** | Resilient Distributed Dataset. Immutable, partitioned collection. Low-level API. Fault-tolerant via lineage graph. |
| **DataFrame** | Distributed table with named columns and schema. Optimized via Catalyst. Preferred over RDDs in modern Spark. |
| **Dataset** | Typed DataFrame (Scala/Java only). Compile-time type safety + Catalyst optimization. Not available in PySpark. |
| **SparkSession** | Unified entry point since Spark 2.0. Replaces `SparkContext`, `SQLContext`, and `HiveContext`. |
| **Partition** | Unit of parallelism. Each partition processed by one task on one executor. Default = number of HDFS blocks. |
| **DAG** | Directed Acyclic Graph of transformations. Spark builds this lazily, then executes optimally on action call. |
| **Stage** | Group of tasks that can run in parallel without a shuffle. Separated by wide transformations (shuffle boundaries). |
| **Task** | Smallest unit of work. One task per partition per stage. Sent to executor by Task Scheduler. |
| **Job** | Triggered by an action. A job consists of one or more stages. |
| **Executor** | JVM process on a worker node. Runs tasks, stores cached data. Lives for the duration of the application. |
| **Driver** | JVM process that runs the main function. Hosts SparkSession, maintains SparkContext, coordinates executors. |

---

## Transformations vs Actions

### Transformations — Lazy (build the DAG only, no computation)

| Type | Description | Examples |
|------|-------------|---------|
| **Narrow** | No shuffle. Each input partition maps to one output partition. | `map`, `filter`, `union`, `select`, `withColumn`, `flatMap` |
| **Wide** | Causes shuffle. Input partitions may contribute to many output partitions. | `groupBy`, `join`, `distinct`, `repartition`, `orderBy`, `reduceByKey` |

### Actions — Eager (trigger DAG execution)

Return results to the driver or write to storage.

`collect()` · `count()` · `show()` · `take(n)` · `first()` · `foreach()` · `reduce()` · `write` · `saveAsTextFile()`

---

## Cluster Managers

| Manager | Description |
|---------|-------------|
| **Standalone** | Built-in Spark scheduler. Simple setup. Best for dedicated Spark clusters. |
| **YARN** | Hadoop resource manager. Most common in on-prem Hadoop ecosystems. |
| **Kubernetes** | Native K8s support (Spark 2.3+). Container-based. Preferred for cloud-native deployments. |
| **Mesos** | Fine-grained resource sharing. Largely replaced by K8s. Legacy use only. |

---

## Deploy Modes

| Mode | Description |
|------|-------------|
| **Client** | Driver runs on the submitting machine. Logs visible locally. Good for interactive / development use. Connection must stay alive. |
| **Cluster** | Driver runs on a worker node inside the cluster. Submitter can disconnect. Preferred for production batch jobs. |

---

## Catalyst Optimizer & Tungsten

| Component | Description |
|-----------|-------------|
| **Catalyst optimizer** | SQL/DataFrame query optimizer. 4 phases: Analysis → Logical optimization → Physical planning → Code generation. Rewrites plans for performance automatically. |
| **Tungsten engine** | Low-level execution engine. Off-heap memory management, cache-aware computation, whole-stage code generation. Bypasses JVM GC overhead. |

---

## Persistence / Caching

### Storage Levels

| Level | Description |
|-------|-------------|
| `MEMORY_ONLY` | Default. Stored as deserialized objects in JVM heap. Fast, may recompute if evicted. |
| `MEMORY_AND_DISK` | Spills to disk if memory is insufficient. |
| `DISK_ONLY` | Serialized and stored on disk only. |
| `MEMORY_ONLY_SER` | Serialized objects in memory. More space-efficient, slower to read. |
| `OFF_HEAP` | Stores in Tungsten off-heap memory. Reduces GC pressure. |
| `MEMORY_AND_DISK_SER` | Serialized in memory, spills serialized to disk. |

### When to Cache

- Cache when a DataFrame is **reused multiple times** in a job.
- Avoid caching DataFrames used only once — wastes memory.
- Always call `unpersist()` when done to free resources.

### API

```python
df.cache()                                      # shorthand for MEMORY_AND_DISK
df.persist(StorageLevel.MEMORY_ONLY)            # explicit storage level
df.unpersist()                                  # free memory
```

---

## Shuffle & Partitioning

### What is a Shuffle?

Data redistribution across executors. The most expensive Spark operation. Triggered by wide transformations. Involves disk I/O, serialization, and network transfer.

### Partitioning Control

| Method | Description |
|--------|-------------|
| `repartition(n)` | Full shuffle. Evenly distributes data into n partitions. |
| `coalesce(n)` | No shuffle. Reduces partitions only. More efficient than repartition for shrinking. |
| `repartitionByRange(n, col)` | Range-based partitioning. Good for sorted writes. |
| `partitionBy(col)` | Write-side partitioning to directory structure on disk. |

### Key Shuffle Configs

| Config | Description |
|--------|-------------|
| `spark.sql.shuffle.partitions` | Number of partitions after a shuffle (default: 200) |
| `spark.default.parallelism` | Default parallelism for RDD operations |
| AQE auto-optimize | Spark 3.0+ automatically adjusts partition count post-shuffle |

---

## PySpark — Common DataFrame Operations

```python
# Session setup
from pyspark.sql import SparkSession
import pyspark.sql.functions as F

spark = SparkSession.builder \
    .appName("app") \
    .config("spark.sql.shuffle.partitions", "200") \
    .getOrCreate()

# Read / write
df = spark.read.parquet("s3://bucket/path")
df = spark.read.csv("path", header=True, inferSchema=True)
df = spark.read.json("path")
df = spark.read.format("delta").load("path")

df.write.mode("overwrite").partitionBy("date").parquet("output/")
df.write.format("delta").mode("append").save("path")
df.write.saveAsTable("schema.table_name")

# Select / filter / rename
df.select("col1", "col2")
df.select(F.col("col1"), F.col("col2").alias("renamed"))
df.filter(df.age > 30)
df.where("age > 30 AND city = 'NY'")
df.withColumnRenamed("old_name", "new_name")
df.withColumn("new_col", F.col("col1") * 2)
df.drop("col")

# Aggregations
df.groupBy("dept").agg(
    F.count("*").alias("cnt"),
    F.avg("salary").alias("avg_salary"),
    F.sum("revenue").alias("total_revenue"),
    F.max("age").alias("max_age")
)
df.groupBy("dept").pivot("quarter").sum("revenue")

# Window functions
from pyspark.sql import Window

w = Window.partitionBy("dept").orderBy(F.desc("salary"))
df.withColumn("rank", F.rank().over(w))
df.withColumn("dense_rank", F.dense_rank().over(w))
df.withColumn("row_number", F.row_number().over(w))
df.withColumn("lag_val", F.lag("val", 1).over(w))
df.withColumn("lead_val", F.lead("val", 1).over(w))
df.withColumn("running_total", F.sum("revenue").over(
    w.rowsBetween(Window.unboundedPreceding, Window.currentRow)
))

# Joins
df1.join(df2, "id", "inner")
df1.join(df2, df1.id == df2.user_id, "left")
df1.join(df2, ["id", "dept"], "full")
df1.join(F.broadcast(df2), "id")          # broadcast join hint

# UDFs (avoid when possible — use built-in functions instead)
from pyspark.sql.types import StringType
upper_udf = F.udf(lambda x: x.upper() if x else None, StringType())
df.withColumn("upper_name", upper_udf(df.name))

# Pandas UDF (vectorized — much faster than regular UDF)
from pyspark.sql.functions import pandas_udf
import pandas as pd

@pandas_udf(StringType())
def upper_pandas_udf(s: pd.Series) -> pd.Series:
    return s.str.upper()

df.withColumn("upper_name", upper_pandas_udf(df.name))

# SQL interface
df.createOrReplaceTempView("users")                 # session-scoped
df.createOrReplaceGlobalTempView("users")           # cross-session
spark.sql("SELECT dept, COUNT(*) FROM users GROUP BY dept")
spark.catalog.listTables()
```

---

## Common Functions (`pyspark.sql.functions`)

### String

| Function | Description |
|----------|-------------|
| `upper(col)` / `lower(col)` | Change case |
| `trim(col)` / `ltrim` / `rtrim` | Remove whitespace |
| `substring(col, pos, len)` | Extract substring |
| `concat(c1, c2)` / `concat_ws(sep, ...)` | Concatenate columns |
| `regexp_replace(col, pattern, replacement)` | Regex substitution |
| `split(col, pattern)` | Split into array |
| `length(col)` | String length |
| `lpad(col, len, pad)` / `rpad` | Pad strings |
| `instr(col, substr)` | Find position of substring |

### Date / Time

| Function | Description |
|----------|-------------|
| `current_date()` / `current_timestamp()` | Current date/time |
| `to_date(col, format)` / `to_timestamp(col, format)` | Parse strings to date |
| `date_add(col, days)` / `date_sub(col, days)` | Add/subtract days |
| `datediff(end, start)` | Difference in days |
| `year(col)` / `month(col)` / `dayofweek(col)` | Extract date parts |
| `date_format(col, format)` | Format date as string |
| `unix_timestamp(col)` / `from_unixtime(col)` | Epoch conversion |
| `months_between(d1, d2)` | Fractional months between dates |

### Aggregate & Window

| Function | Description |
|----------|-------------|
| `count(col)` / `countDistinct(col)` | Count rows |
| `sum(col)` / `avg(col)` / `min(col)` / `max(col)` | Basic aggregations |
| `collect_list(col)` / `collect_set(col)` | Aggregate into array |
| `row_number()` / `rank()` / `dense_rank()` | Ranking functions |
| `lead(col, n)` / `lag(col, n)` | Access adjacent rows |
| `first(col)` / `last(col)` | First/last value in group |
| `stddev(col)` / `variance(col)` | Statistical functions |

### Conditional

| Function | Description |
|----------|-------------|
| `when(condition, value).otherwise(value)` | If-else logic |
| `coalesce(c1, c2, ...)` | First non-null value |
| `isnull(col)` / `isnotnull(col)` | Null checks |
| `nvl(col, default)` | Replace null with default |

### Array & Map

| Function | Description |
|----------|-------------|
| `array(c1, c2)` / `array_contains(col, val)` | Create/check arrays |
| `explode(col)` / `explode_outer(col)` | Flatten array to rows |
| `flatten(col)` / `array_distinct(col)` | Flatten nested / dedupe |
| `map_keys(col)` / `map_values(col)` | Extract map components |
| `size(col)` | Array or map length |
| `array_sort(col)` / `sort_array(col)` | Sort array elements |
| `posexplode(col)` | Explode with position index |

---

## Join Types

| Type | Description |
|------|-------------|
| `inner` | Rows matching in both sides. Default join type. |
| `left` / `right` | All rows from left/right + matched rows from other side. Nulls for non-matches. |
| `full` / `outer` | All rows from both sides. Nulls where no match. |
| `left_semi` | Rows in left that have a match in right (no right columns returned). |
| `left_anti` | Rows in left that have no match in right. |
| `cross` | Cartesian product. Avoid unless intentional — extremely expensive. |

---

## Broadcast Join & Skew Handling

### Broadcast Join

Send a small table to all executors, eliminating shuffle entirely.
- Auto-triggered when table size < `spark.sql.autoBroadcastJoinThreshold` (default 10MB).
- Force manually: `df1.join(F.broadcast(df2), "id")`.
- Disable: `spark.conf.set("spark.sql.autoBroadcastJoinThreshold", -1)`.

### Skew Handling

| Technique | Description |
|-----------|-------------|
| Salting | Add a random prefix to skewed keys, then join and remove prefix. |
| AQE skew join | Spark 3+ auto-splits skewed partitions at runtime. |
| `skewHint` | Explicit hint: `df.hint("skew", "key_col")` |
| Pre-repartition | Redistribute data before the join to balance partitions. |

---

## Adaptive Query Execution (AQE) — Spark 3+

Enable with: `spark.conf.set("spark.sql.adaptive.enabled", "true")`

| Feature | Description |
|---------|-------------|
| **Coalesce shuffle partitions** | Merges small post-shuffle partitions automatically. Avoids the fixed 200-partition problem. |
| **Switch join strategies** | Converts sort-merge join to broadcast join at runtime if one side turns out small after filtering. |
| **Skew join optimization** | Detects and splits skewed partitions into smaller sub-partitions. Replicated join side duplicated accordingly. |

---

## Structured Streaming

```python
# Read from Kafka
df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "host:9092") \
    .option("subscribe", "topic") \
    .load()

# Apply transformations
result = df.selectExpr("CAST(value AS STRING)") \
    .groupBy("value") \
    .count()

# Write stream
query = result.writeStream \
    .outputMode("update") \
    .format("console") \
    .trigger(processingTime="10 seconds") \
    .start()

query.awaitTermination()
```

### Output Modes

| Mode | Description |
|------|-------------|
| `append` | Only new rows written to sink (default). No aggregations. |
| `complete` | Full result table written each trigger. Requires aggregation. |
| `update` | Only changed rows written since last trigger. |

### Triggers

| Trigger | Description |
|---------|-------------|
| default | Process as fast as possible (micro-batch). |
| `processingTime="10 seconds"` | Fixed interval micro-batch. |
| `once` | Process all available data in one micro-batch then stop. |
| `availableNow` | Process all pending data in multiple batches then stop. |
| `continuous="1 second"` | Experimental continuous processing (low latency). |

### Watermarking

Handle late-arriving data:

```python
df.withWatermark("timestamp", "10 minutes") \
  .groupBy(F.window("timestamp", "5 minutes"), "user_id") \
  .count()
```

---

## Spark SQL & Delta Lake

### Spark SQL

```sql
-- CTEs
WITH ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn
  FROM employees
)
SELECT * FROM ranked WHERE rn = 1;

-- Create / manage views
CREATE OR REPLACE TEMP VIEW dept_summary AS
SELECT dept, COUNT(*) AS cnt, AVG(salary) AS avg_sal FROM employees GROUP BY dept;

-- DDL
CREATE TABLE IF NOT EXISTS schema.table USING DELTA LOCATION 's3://bucket/path';
ALTER TABLE schema.table ADD COLUMNS (new_col STRING);
```

### Delta Lake

```python
# Write
df.write.format("delta").mode("overwrite").save("/delta/table")

# Read
df = spark.read.format("delta").load("/delta/table")

# Time travel
df = spark.read.format("delta").option("versionAsOf", 5).load("/delta/table")
df = spark.read.format("delta").option("timestampAsOf", "2024-01-01").load("/delta/table")

# MERGE (upsert)
from delta.tables import DeltaTable
target = DeltaTable.forPath(spark, "/delta/table")
target.alias("t").merge(
    source.alias("s"),
    "t.id = s.id"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()

# Vacuum (remove old files)
target.vacuum(168)  # retain 168 hours (7 days)

# History
target.history().show()
```

---

## Key Spark Configs

### Memory & Executor

| Config | Description |
|--------|-------------|
| `spark.executor.memory` | Heap memory per executor (e.g. `4g`) |
| `spark.executor.cores` | CPU cores per executor (e.g. `4`) |
| `spark.driver.memory` | Driver heap memory (e.g. `2g`) |
| `spark.executor.instances` | Fixed number of executors (static allocation) |
| `spark.memory.fraction` | Fraction of heap for execution+storage (default `0.6`) |
| `spark.memory.storageFraction` | Storage fraction within `memory.fraction` (default `0.5`) |
| `spark.executor.memoryOverhead` | Off-heap overhead per executor (e.g. `512m`) |

### Performance Tuning

| Config | Description |
|--------|-------------|
| `spark.sql.shuffle.partitions` | Partitions after a shuffle (default `200`) |
| `spark.sql.adaptive.enabled` | Enable AQE (default `true` in Spark 3.2+) |
| `spark.sql.autoBroadcastJoinThreshold` | Max size for broadcast join (default `10MB`) |
| `spark.dynamicAllocation.enabled` | Scale executors up/down dynamically |
| `spark.serializer` | Use `KryoSerializer` for better performance |
| `spark.sql.files.maxPartitionBytes` | Max bytes per input partition (default `128MB`) |
| `spark.sql.adaptive.coalescePartitions.enabled` | AQE partition coalescing |
| `spark.sql.adaptive.skewJoin.enabled` | AQE skew join handling |
| `spark.rdd.compress` | Compress serialized RDD partitions |

---

## spark-submit

```bash
# Submit a PySpark job to YARN in cluster mode
spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --num-executors 10 \
  --executor-memory 4g \
  --executor-cores 4 \
  --driver-memory 2g \
  --conf spark.sql.shuffle.partitions=400 \
  --conf spark.sql.adaptive.enabled=true \
  --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
  --py-files dependencies.zip \
  my_job.py --arg1 value1

# Submit to Kubernetes
spark-submit \
  --master k8s://https://<k8s-apiserver>:443 \
  --deploy-mode cluster \
  --conf spark.kubernetes.container.image=spark:3.5.0 \
  --conf spark.executor.instances=5 \
  my_job.py

# Local mode (dev/test) — uses all available cores
spark-submit --master local[*] my_job.py
```

---

## Performance Best Practices

### Do

- Use **built-in functions** (`pyspark.sql.functions`) over Python UDFs — they run in JVM, no serialization overhead.
- Use **Pandas UDFs** (vectorized) when a UDF is unavoidable.
- Read **Parquet or ORC** (columnar) formats for analytics workloads.
- Apply **predicate pushdown and column pruning** — filter early, select only needed columns.
- **Broadcast small tables** in joins to eliminate shuffle.
- **Cache / persist** DataFrames that are reused multiple times.
- Enable **AQE** (Spark 3+) for automatic partition and join optimization.
- **Tune `shuffle.partitions`** — 200 is rarely the right number for your data size.
- Use `coalesce()` instead of `repartition()` when reducing partition count.
- **Partition output data** by high-cardinality filter columns (e.g. date).

### Avoid

- Python **UDFs** (serialize/deserialize overhead between JVM and Python).
- **Cartesian / cross joins** — exponential row explosion.
- **`collect()`** on large DataFrames — moves all data to the driver.
- **`repartition()`** when `coalesce()` suffices — unnecessary shuffle.
- Processing data with **highly skewed keys** without salting or AQE.
- Using **RDDs** where DataFrames/Datasets work — miss out on Catalyst and Tungsten.
- **Caching everything** — only cache what is reused; unpersist after use.
- Triggering **actions inside loops** — Spark builds a new DAG on each iteration.

---

## Spark Ecosystem

| Component | Description |
|-----------|-------------|
| **Spark SQL** | Full ANSI SQL on DataFrames. CTEs, subqueries, window functions, DDL. Hive metastore compatible. |
| **Structured Streaming** | Real-time stream processing on DataFrames. Kafka, Kinesis, file sources. Micro-batch or continuous mode. |
| **MLlib** | Distributed ML library. Pipelines, classification, regression, clustering, collaborative filtering, feature engineering. |
| **GraphX** | Graph computation API (Scala/Java). PageRank, connected components, triangle counting. |
| **Delta Lake** | ACID transactions on data lakes. Time travel, schema enforcement, upserts (MERGE), unified batch + streaming. |
| **Apache Iceberg** | Open table format. Snapshot isolation, schema evolution, partition evolution, time travel. |

---

## Quick Reference — Default Ports

| Service | Default Port |
|---------|-------------|
| Spark Web UI (Driver) | `4040` |
| Spark Master UI | `8080` |
| Spark Worker UI | `8081` |
| Spark History Server | `18080` |
| Spark REST API | `6066` |

---

*· Apache Spark reference · spark.apache.org*
