# Developing

## Upgrading dkml-workflows

```bash
opam upgrade dkml-workflows

# Updating the duniverse lock file does not yet work ... you can skip this part
touch your_example.opam
make duniverse

# So we only do the monorepo pull. You will need to update the .locked file yourself.
touch your_example.opam.locked
make duniverse
```
