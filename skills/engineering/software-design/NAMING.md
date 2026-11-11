# Naming

A name is the first interface a reader meets, and the only one at a call
site. An honest name says what the thing is or does, covers every case it
handles, and means the same thing everywhere in the repo.

## Choosing a public name

Run this for every public name a plan pins or a change adds: types,
functions, exceptions, fields that cross a module interface.

1. **Concepts.** List what a caller who sees only the call site must learn
   from the name.
2. **Words.** Take each concept's word from the repo's glossary
   (`GLOSSARY.md`, or the file the repo already uses) when it has one, else the word the domain
   uses. A glossary term that fits only by stretching is a
   [weak term](#weak-term--judgement).
3. **Collisions.** `git grep -iw <word>` and the glossary for each word.
   Done when every hit means the same concept as the new name.
4. **Assemble** it in the [shape](#shapes) for its kind, then read the call
   site aloud: `upload.send(case)` should read as a sentence.

Done when every new public name has passed every flag below.

## Shapes

- **Variables and fields**: a noun for what the value is
  (`pending_cases`). Carry the unit or state the type cannot
  (`timeout_s`, `size_bytes`, `raw_path` vs `resolved_path`). Booleans are
  affirmative claims: `is_stored`, `has_data_file`, `can_retry`.
- **Functions**: a query is named for what it returns (`open_cases()`); a
  command is a verb for its effect (`archive(case)`). One verb per
  operation across the repo: if `fetch` loads over the network, every
  network load is `fetch`.
- **Types**: one domain concept, as a noun (`DataFileUpload`). An
  interface is named for its role, each implementation for how it fills
  it (`Bucket` → `S3Bucket`, `InMemoryBucket`).
- **Exceptions**: what went wrong, from the caller's side, with the
  language's suffix (`Error` in Python, `Exception` in C#/Java). One per
  failure a caller handles differently.
- **Modules and files**: the one piece of knowledge they hold (`rank.py`).

## Flags

Same format and mechanical/judgement split as [RED-FLAGS.md](RED-FLAGS.md).

### Vague name · mechanical

- **Looks like**: `data`, `info`, `result`, `object`, `manager`, `handle`,
  `process`, `settle`, `tmp` for anything with a meaningful scope. A name
  that admits a wrong meaning.
- **Detect**: read each new name alone and ask what it could be mistaken
  for.
- **Fix**: rename to the precise concept, in the repo's vocabulary.
- **Fine when**: the scope is a few lines (a loop index, a lambda argument).

### Hard to pick a name · judgement

- **Looks like**: names with `And`/`Or`, `Utils`, `Helper`, `Processor`,
  `Common`, or a name that needs a long qualifier. A record whose mode
  depends on which fields are set.
- **Detect**: those words in new names; a name that took several tries; a
  docstring that lists several jobs.
- **Fix**: the thing does more than one job or is not one concept. Split
  it, or move its parts to their owners, until a precise name fits.
- **Fine when**: it is one concept with an established long name in the
  domain.

### Collision · judgement

- **Looks like**: a new name whose word already means something else in
  the repo: in the glossary, the docs, or another module. `Delivery` for an
  upload helper, where delivery already means what a producer sends.
- **Detect**: `git grep -iw` each word of each new public name, plus the
  glossary.
- **Fix**: pick another word for the new concept.
- **Fine when**: every existing use means the same concept.

### Glossary drift · mechanical

- **Looks like**: a concept the glossary names, called something else in
  code (`StoredObject` where the glossary says data-file object).
- **Detect**: for each new type and public function, look up its concept
  in the glossary.
- **Fix**: rename to the glossary term.
- **Fine when**: the language forces a different form (casing, a suffix).

### Weak term · judgement

- **Looks like**: a glossary term that fits the code only by stretching,
  or that the domain itself uses for something else.
- **Detect**: a glossary term that needs a qualifier or caveat at every
  use.
- **Fix**: propose the glossary edit first (`mattpocock-skills:domain-modeling`),
  then rename the code to the new term.
- **Fine when**: the domain experts use the term that way.

### Dishonest name · mechanical

- **Looks like**: a name whose promise the signature or body breaks:
  `get_x` with side effects or no return value; `is_x`/`has_x` returning
  a non-bool; a singular name returning a collection; `set_x` returning a
  value; an exception narrower than its raise sites
  (`UnavailableError` also raised on an unknown outcome).
- **Detect**: compare each new or changed name to its signature and body.
  For an exception, list every raise site.
- **Fix**: rename until the name covers everything the thing does.
- **Fine when**: never.

### Stale name · judgement

- **Looks like**: a name chosen for the first version of the code, kept
  after the diff changed what the thing does.
- **Detect**: for each function or type whose body the diff changes,
  reread the name against the new behaviour.
- **Fix**: rename in the same change, across every caller.
- **Fine when**: the change is purely internal and the name still holds.
