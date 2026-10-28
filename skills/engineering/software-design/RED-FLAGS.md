# Red flags

The red flags from *A Philosophy of Software Design*, plus inconsistency
from its chapter on consistency. Each one is a symptom
of complexity: change amplification, cognitive load or unknown unknowns.
Each entry says what it looks like, how to detect it, the fix, and when it
is fine.

**Mechanical** flags have one obvious fix that changes no design decision;
apply it. **Judgement** flags move an interface or a responsibility; fix
them when the right shape is clear, otherwise surface them with the
trade-off. In `build` they are always surfaced, never fixed.

## Interfaces

### Shallow module · judgement

- **Looks like**: an interface about as complex as its implementation.
  Many small classes or functions that each hide little; callers do the
  real work by combining them.
- **Detect**: list what the module's entry file exports. For each export,
  name the decision it hides from callers. An empty answer is a hit.
- **Fix**: merge into the caller or a neighbour so one interface hides
  more. Prefer fewer, more powerful functions.
- **Fine when**: it is an adapter at the edge translating a vendor or
  transport, where the translation is the hidden decision.

### Overexposure · mechanical

- **Looks like**: callers must learn rarely-used options to make the
  common call. A parameter every caller passes the same value for.
  Required config the module could pick itself.
- **Detect**: for each parameter of a new or changed public function, grep
  its call sites. Same value everywhere, or a default that every caller
  restates, is a hit.
- **Fix**: drop the parameter and decide inside the module, or give it a
  default and remove the restated values.
- **Fine when**: the parameter is a safety input (`scope`, `ctx`, acting
  user), which stays required even when every caller passes the same thing.

### Pass-through method · mechanical

- **Looks like**: a function whose body is one call to another function
  with the same or nearly the same signature. A pass-through variable,
  threaded through layers that never read it.
- **Detect**: in changed code, a function body that is a single forwarding
  call; a parameter that a function only hands on.
- **Fix**: callers use the inner function directly, or the outer one takes
  on real work. Pass-through variables move into a context object the
  layers already share.
- **Fine when**: it is a dispatcher choosing between implementations, or an
  interface with several real implementations.

### Special-general mixture · judgement

- **Looks like**: a general mechanism with branches for one caller's case.
  Boolean flags that switch behaviour, `if kind == "invoice"` inside a
  storage or queue module, imports from a higher layer.
- **Detect**: in lower-layer or capability modules, grep for caller domain
  terms, boolean parameters and upward imports.
- **Fix**: keep the general mechanism down and push the special case up
  into the caller, or split it into its own module on top.
- **Fine when**: the "special" case is actually part of the module's own
  knowledge.

## Knowledge

### Information leakage · judgement

- **Looks like**: one design decision (a file format, a protocol, a key
  layout, a magic constant, a call order) known in two or more modules, so
  changing it changes all of them.
- **Detect**: grep distinctive literals, keys and format strings across
  modules. Check co-change: files that keep changing in the same commits
  share knowledge, whatever the import graph says:

  ```sh
  git log --format= --name-only -n 300 | awk NF | sort | uniq -c | sort -rn | head
  git log --format= --name-only --full-diff -n 300 -- <file> | awk NF | sort | uniq -c | sort -rn | head
  ```

  The first shows hot files; the second shows what changes alongside one of
  them. Pairs across modules that keep showing up are a hit.
- **Fix**: give the decision one owner and have the others call it, or
  merge the modules.
- **Fine when**: the shared thing is a published contract generated from
  one source (schema → OpenAPI → client types).

### Temporal decomposition · judgement

- **Looks like**: code split by when things happen (read, parse, process,
  write) where two stages know the same thing, like the format read in one
  and written in another.
- **Detect**: for modules named after steps, ask what each one knows. A
  piece of knowledge in more than one stage is a hit.
- **Fix**: split by knowledge: one module owns the format and does both
  reading and writing.
- **Fine when**: each stage hides distinct knowledge. Ordering alone is
  not the problem; shared knowledge is.

### Repetition · mechanical

- **Looks like**: the same non-trivial code in several places.
- **Detect**: grep a distinctive line of each new block across the repo.
- **Fix**: move it to the module that owns the knowledge and call it.
  When copies have drifted apart, decide which one is right first.
- **Fine when**: the copies only look alike and will change for different
  reasons.

### Conjoined methods · judgement

- **Looks like**: two functions or modules you can only understand
  together. One sets state the other reads, or they must be called in a
  fixed order.
- **Detect**: reading one sends you to the other's body to understand it;
  shared mutable state; a "call A before B" rule.
- **Fix**: merge them, or redraw the interface so each stands alone.
- **Fine when**: the relationship is fully stated by the interface (a
  builder, an explicit open/close pair).

## Naming and documentation

### Vague name · mechanical

- **Looks like**: `data`, `info`, `result`, `manager`, `handle`, `tmp`,
  `obj` for anything with a meaningful scope. A name that admits a wrong
  meaning.
- **Detect**: read each new name alone and ask what it could be mistaken
  for.
- **Fix**: rename to something precise and consistent with the rest of the
  module.
- **Fine when**: the scope is a few lines (a loop index, a lambda argument).

### Hard to pick a name · judgement

- **Looks like**: names with `And`/`Or`, `Utils`, `Helper`, `Processor`,
  `Common`, or a name that needs a long qualifier.
- **Detect**: those words in new names; a name that took several tries.
- **Fix**: the thing does more than one job or is not one concept. Split
  it, or move its parts to their owners, until a precise name fits.
- **Fine when**: it is one concept with an established long name in the
  domain.

### Hard to describe · judgement

- **Looks like**: a function or module whose one-sentence description
  needs "and", caveats, or the internals.
- **Detect**: write one sentence for each new public function or module,
  saying what it does for its caller.
- **Fix**: as for hard to name: split or reshape until one sentence holds.
- **Fine when**: never; a short accurate description is always possible
  for a clean abstraction.

### Comment repeats code · mechanical

- **Looks like**: a comment that says what the next line already says.
- **Detect**: delete the comment and ask whether the reader lost anything.
- **Fix**: delete it, or replace it with what the code cannot show (why,
  units, invariants).
- **Fine when**: never.

### Implementation in interface docs · mechanical

- **Looks like**: a public function's docstring describing how it works
  inside: tables, retries, helper calls.
- **Detect**: read each public docstring as a caller. Anything a caller
  does not need is a hit.
- **Fix**: keep what callers need in the docstring; the rest moves next to
  the implementation or goes.
- **Fine when**: the behaviour is something callers can observe, like
  performance or ordering guarantees.

## Readability

### Nonobvious code · judgement

- **Looks like**: behaviour you cannot predict from a quick read. Hidden
  side effects, generic containers (`tuple`, `Pair`, `dict`) for meaningful
  data, control flow through callbacks or events, a declared type that
  differs from the real one.
- **Detect**: read each changed function once, predict what it does, then
  check. A miss is a hit.
- **Fix**: named types for meaningful data, side effects visible in names
  and signatures, straight-line control flow where it fits.
- **Fine when**: the obscurity sits behind a deep interface no caller
  reads into.

### Inconsistency · judgement

- **Looks like**: a second way of doing something the codebase already
  does one way: the same concept under a new name (`member` vs `user`,
  `fetch_` vs `get_`), a new error, retry, config or test style beside the
  existing one, a pattern applied differently from its other uses. Or the
  reverse: different things made to look alike, so a reader assumes
  behaviour that is not there.
- **Detect**: for each new name, pattern and convention, grep how the
  codebase already does the same thing. A second way is a hit.
- **Fix**: follow the existing way. A new convention replaces the old one
  only when it is clearly better and every existing use migrates with it.
- **Fine when**: the two things really differ, and the difference is
  visible in their names.
