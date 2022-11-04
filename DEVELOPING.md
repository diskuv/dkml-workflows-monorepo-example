# Developing

## Upgrading dkml-workflows

```bash
opam upgrade dkml-workflows

# Updating the duniverse lock file does not yet work ... you can skip this part
touch your_example.opam
make duniverse

# So we only do the monorepo pull. You will need to update the .locked file yourself!
# See the ".locked" sample commands later in this doc.
touch your_example.opam.locked
make duniverse

# Regenerate the DKML workflow scaffolding
opam exec -- generate-setup-dkml-scaffold && dune build '@gen-dkml' --auto-promote
```

### .locked sample commands

Assuming you have `../dkml-workflows` checked out:

```bash
sed "s/dkml-workflows.git#.*\"/dkml-workflows.git#$(git -C ../dkml-workflows rev-parse HEAD)\"/" your_example.opam.locked > your_example.opam.locked.new
mv your_example.opam.locked.new your_example.opam.locked
```
