# Persistence, jobs and events

Patterns for the platform modules that most often leak. Each one pulls a
hard problem down so callers see only a small interface. Use the repo's own
names for these modules; the shapes below are what matter.

## Persistence

- A module's persistence code owns its schema and queries and gets
  connections and transactions from the platform database module.
- It returns the module's frozen domain types, so every change goes through
  the module's rules, all data is loaded before the session closes, and
  column names stay private.
- The module's rules layer owns the transaction, so one commit covers the
  write, the job enqueue and the event publish:

```python
def send(conversation, author, text, client_id):
    with db.transaction():
        conversations.require_member(conversation, author)
        msg = store.insert_once(conversation, author, client_id, text)
        events.publish(MessageSent(message_id=msg.id))
    return msg
```

## Background jobs

- The queue module's interface is two things: declare a handler (with its
  pool, retries and timeout) and enqueue it with IDs. Behind it sit the
  broker, serialization, retries, backoff, dead letters and scheduling.
- Payloads carry IDs. The owning module's table holds the state, so a retry
  reloads fresh data.
- Handlers are idempotent (upserts).
- Enqueue inside the caller's transaction: a database-backed queue gets
  this for free; an external broker gets it through an outbox.
- Jobs are claimed with leases (a lock-until timestamp), so a crashed
  worker's job comes back on its own.
- Job mechanics (lock owner, attempts) belong to the queue; domain status
  (pending, done, failed) belongs to the owning module's table.
- Worker pools are one enum owned by the queue module, matching what the
  worker processes listen on; each module picks its pool as a private
  constant.
- Retry policy is per job: idempotent jobs retry, jobs with outside effects
  (running user code) run once.
- A table another system reads directly (a service in another language) is
  public interface: minimal, documented, versioned.

## Events

- The events module's interface is two things: publish an event inside the
  caller's transaction, and subscribe a handler to an event type on a pool.
- One private outbox holds all events, owned by the events module. A
  dispatcher fans out, each subscriber running as its own job on its own
  pool, for independent scaling and failure isolation.
- Delivery is at-least-once, so handlers are idempotent and order-safe
  (updates that keep the latest value, such as `greatest()`).
- Event types live in a shared contracts module, frozen shapes only, so
  publisher and subscribers both depend downward and the graph stays a DAG.
- An event is a published contract, versioned like any public interface.
- High-frequency ephemeral streams (token-by-token output) go over a
  non-durable channel (database notifications, a pub/sub broker).
- Each module registers its own subscribers when its public entry file
  loads.
- An event inverts a dependency so the publisher stays unaware of its
  subscribers. Use one once a second consumer exists; a single consumer
  gets a direct call.

## Capabilities

- A capability owns the *how* of its job and everything that knowledge
  touches: search owns indexing too (chunking, embedding model, schema).
  Each source owns the *what* and *when* and calls the capability with a
  ref, the content and its scope.
- Deletes and edits propagate to the capability, so its entries always
  match the source data.

## Modules vs deployments

A module is a knowledge boundary; a deployed service is a runtime boundary
(scale, security, failure). One build can run as both the web server and
the workers. Start as one deployable and split worker pools when load or
security demands. Extracting a module to its own service later keeps its
interface; the implementation becomes a client.
