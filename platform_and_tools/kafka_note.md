
# Kafka Cheatsheet


> Quick reference for all key terms, concepts, and components of Apache Kafka.

---
## Architecture — Data Flow

```

Producer → Broker Cluster → Topic / Partition → Consumer Group → Consumer

                                    ↑

                        ZooKeeper / KRaft (metadata)

```

---
## Core Concepts

| Term                  | Description                                                                                                       |
| --------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Topic**             | Named append-only log stream. Messages are immutable once written. Split into partitions.                         |
| **Partition**         | Ordered, immutable sequence of records. Unit of parallelism. Each has a `partition_id`. Spread across brokers.    |
| **Offset**            | Monotonically increasing integer per partition. Consumer tracks its position. Committed to `__consumer_offsets`.  |
| **Segment**           | Partition split into log segments on disk. Controlled by `log.segment.bytes`. Old segments deleted/compacted.     |
| **Broker**            | A single Kafka server. Stores partitions, serves reads/writes. Identified by `broker.id`. Many brokers = cluster. |
| **Leader / Follower** | Each partition has 1 leader (handles all reads+writes) and N-1 followers (replicas). Elected by controller.       |
| **ISR**               | *In-Sync Replicas.* Set of replicas fully caught up to leader. Acknowledged writes guaranteed to be in ISR.       |
| **Controller**        | Special broker that manages partition leadership elections & cluster metadata. One per cluster at a time.         |
  
---

## Message Anatomy

| Field         | Description                                                                                              |
| ------------- | -------------------------------------------------------------------------------------------------------- |
| **Key**       | Optional bytes. Determines partition routing. Used for ordering guarantees and log compaction.           |
| **Value**     | Main payload bytes. Serialized with Avro / JSON / Protobuf. Schema Registry used for schema management.  |
| **Headers**   | Key-value metadata pairs. Used for tracing, routing, versioning. Not part of compaction key logic.       |
| **Timestamp** | `CreateTime` (producer-set) or `LogAppendTime` (broker-set). Controlled by `log.message.timestamp.type`. |

---
## Producer

### Partitioning Strategy

| Strategy           | Behaviour                                                      |
| ------------------ | -------------------------------------------------------------- |
| Key hash           | Same key always → same partition. Guarantees ordering per key. |
| Round-robin        | Used when key is null. Distributes evenly across partitions.   |
| Custom partitioner | Implement `Partitioner` interface for custom routing logic.    |

### Acknowledgements (`acks`)

| Setting    | Behaviour                                  |
| ---------- | ------------------------------------------ |
| `acks=0`   | Fire & forget — no confirmation.           |
| `acks=1`   | Leader acknowledges only.                  |
| `acks=all` | All ISR replicas must acknowledge. Safest. |

### Key Producer Configs

  

| Config               | Description                         |
| -------------------- | ----------------------------------- |
| `batch.size`         | Bytes per batch before sending      |
| `linger.ms`          | Wait time before sending a batch    |
| `retries`            | Number of retry attempts on failure |
| `enable.idempotence` | Enables exactly-once producing      |
| `compression.type`   | `gzip` / `snappy` / `lz4` / `zstd`  |
| `max.block.ms`       | Max time `send()` will block        |
| `buffer.memory`      | Total bytes of memory for buffering |

---

## Consumer

### Consumer Group

- Multiple consumers sharing a `group.id`.
- Each partition assigned to **exactly one** consumer per group.
- More consumers than partitions → idle consumers.
- Different groups each get a full copy of all messages.
### Rebalance Triggers

- Consumer joins or leaves the group
- Topic partition count changes
- Session timeout hit (`session.timeout.ms` exceeded)

### Partition Assignment Strategies

| Strategy                    | Description                                    |
| --------------------------- | ---------------------------------------------- |
| `RangeAssignor`             | Assigns contiguous ranges per topic (default)  |
| `RoundRobinAssignor`        | Distributes partitions evenly across consumers |
| `StickyAssignor`            | Minimizes partition movement on rebalance      |
| `CooperativeStickyAssignor` | Incremental rebalance — avoids stop-the-world  |

### Key Consumer Configs

| Config                    | Description                                 |
| ------------------------- | ------------------------------------------- |
| `auto.offset.reset`       | `earliest` / `latest` / `none`              |
| `enable.auto.commit`      | Auto-commit offsets periodically            |
| `auto.commit.interval.ms` | Frequency of auto-commit                    |
| `max.poll.records`        | Max records returned per poll               |
| `session.timeout.ms`      | Heartbeat window before declared dead       |
| `fetch.min.bytes`         | Min data broker must have before responding |
| `fetch.max.wait.ms`       | Max wait if `fetch.min.bytes` not met       |

---

## Delivery Semantics

| Semantic | How | Trade-off |
|----------|-----|-----------|
| **At-most-once** | `acks=0` or `acks=1`, no retries | May lose messages. Highest throughput. |
| **At-least-once** | Retries enabled, manual offset commit | Duplicates possible. Consumer must be idempotent. Most common. |
| **Exactly-once (EOS)** | `enable.idempotence=true` + Transactions API | No loss, no duplicates. Higher latency. Required for Kafka Streams. |

---

## Replication & Retention

### Replication Configs

| Config | Description |
|--------|-------------|
| `replication.factor` | Number of copies per partition (≥3 in production) |
| `min.insync.replicas` | Minimum ISR for a write to succeed (set to 2) |
| `unclean.leader.election.enable` | `false` = safer, `true` = higher availability |

### Retention Policies

| Config | Description |
|--------|-------------|
| `log.retention.hours` | Time-based retention (default: 168h / 7 days) |
| `log.retention.bytes` | Size-based retention per partition |
| `log.segment.bytes` | Max size per log segment before rolling |
| `cleanup.policy` | `delete` / `compact` / `delete,compact` |
| Log compaction | Retains only the latest value per key — useful for changelogs |


---
## ZooKeeper vs KRaft

| | ZooKeeper Mode | KRaft Mode |
|--|----------------|------------|
| **Status** | Legacy (deprecated) | GA since Kafka 3.3, default in Kafka 4.x |
| **Metadata store** | Separate ZooKeeper cluster | Kafka manages its own via Raft consensus |
| **Controller election** | ZooKeeper-driven | Built-in Raft-based quorum |
| **Ops overhead** | High (two systems to run) | Low (single system) |
| **Failover speed** | Slower | Much faster |

---

## Kafka Ecosystem

| Component | Description |
|-----------|-------------|
| **Kafka Streams** | Java library for stateful stream processing. Windowing, joins, aggregations. No separate cluster needed. |
| **Kafka Connect** | Source & sink connectors. Move data between Kafka and DBs, S3, Elasticsearch, etc. Declarative config. |
| **Schema Registry** | Centralizes Avro / JSON / Protobuf schemas. Enforces compatibility. Stores schemas by subject. |
| **ksqlDB** | SQL interface over Kafka. Push/pull queries. Persistent queries run as Kafka Streams apps under the hood. |
| **MirrorMaker 2** | Cross-cluster replication tool. Used for geo-replication and disaster recovery. |

---

## Essential CLI Commands

```bash

# Create a topic

kafka-topics --bootstrap-server :9092 --create --topic events \

  --partitions 6 --replication-factor 3

  

# List all topics

kafka-topics --bootstrap-server :9092 --list

  

# Describe a topic

kafka-topics --bootstrap-server :9092 --describe --topic events

  

# Delete a topic

kafka-topics --bootstrap-server :9092 --delete --topic events

  

# Produce messages (with key parsing)

kafka-console-producer --bootstrap-server :9092 --topic events \

  --property parse.key=true --property key.separator=:

  

# Consume messages from beginning

kafka-console-consumer --bootstrap-server :9092 --topic events \

  --from-beginning --group my-group

  

# Describe consumer group (check lag)

kafka-consumer-groups --bootstrap-server :9092 --describe --group my-group

  

# List all consumer groups

kafka-consumer-groups --bootstrap-server :9092 --list

  

# Reset offsets to earliest

kafka-consumer-groups --bootstrap-server :9092 --group my-group \

  --topic events --reset-offsets --to-earliest --execute

  

# Reset offsets to specific offset

kafka-consumer-groups --bootstrap-server :9092 --group my-group \

  --topic events --reset-offsets --to-offset 100 --execute

  

# Alter partition count

kafka-topics --bootstrap-server :9092 --alter --topic events --partitions 12

  

# Describe broker configs

kafka-configs --bootstrap-server :9092 --describe --entity-type brokers --entity-name 1

```

  
---

## Key Metrics to Monitor

### Broker Metrics

| Metric                           | What it signals                             |
| -------------------------------- | ------------------------------------------- |
| `UnderReplicatedPartitions`      | Partitions not fully replicated — data risk |
| `ActiveControllerCount`          | Must always be exactly 1                    |
| `NetworkProcessorAvgIdlePercent` | Low % = network bottleneck                  |
| `BytesInPerSec / BytesOutPerSec` | Throughput per broker                       |
| `RequestHandlerAvgIdlePercent`   | Low % = CPU bottleneck                      |

### Consumer Metrics

| Metric | What it signals |
|--------|-----------------|
| `records-lag-max` | How far behind the consumer is |
| `fetch-rate` | Number of fetch requests per second |
| `commit-rate` | Offset commit frequency |
| `rebalance-rate` | High = instability in consumer group |

### Producer Metrics

| Metric | What it signals |
|--------|-----------------|
| `record-error-rate` | Unrecoverable send failures |
| `request-latency-avg` | End-to-end produce latency |
| `record-retry-rate` | Transient failures being retried |
| `batch-size-avg` | Batching efficiency |

---

## Common Patterns

### Event Sourcing

Topic acts as an append-only event log. Replay from `offset=0` to rebuild state. Use a compacted topic for current-state snapshots.

### CQRS (Command Query Responsibility Segregation)

Commands produce to one topic. Read-side consumers project state into queryable stores (Redis, Postgres, etc.). Kafka bridges write and read models.

### Saga / Choreography

Each microservice publishes events. Others react accordingly. No central orchestrator. Kafka is the coordination backbone.

### Dead Letter Queue (DLQ)

Failed messages routed to a `topic.DLT` topic by Kafka Connect or Kafka Streams. Inspect, fix, and replay without data loss.

### Fan-out

Single topic consumed by multiple independent consumer groups. Each group gets its own full copy of all messages.

---

## Transactions API (Exactly-Once)


```java

// Producer setup

props.put("enable.idempotence", "true");

props.put("transactional.id", "my-transactional-id");

  

producer.initTransactions();

  

try {

    producer.beginTransaction();

    producer.send(new ProducerRecord<>("topic", key, value));

    producer.commitTransaction();

} catch (ProducerFencedException e) {

    producer.close();

} catch (KafkaException e) {

    producer.abortTransaction();

}

```

  
---

## Quick Reference — Default Ports


| Service | Default Port |
|---------|-------------|
| Kafka Broker | `9092` (plaintext) / `9093` (SSL) |
| ZooKeeper | `2181` |
| Schema Registry | `8081` |
| Kafka Connect REST | `8083` |
| ksqlDB | `8088` |
| JMX (metrics) | `9999` |

---

*· Apache Kafka reference · kafka.apache.org*