# Tier Generator
calculates the `tier`, or the complexity of an item.

Considers what machine is required to craft, the ingredients, the technology, and its science packs.

## Explicit compatibility
- [More Science Packs](https://mods.factorio.com/mod/MoreSciencePacks-for1_1)
- [Science Packs Galore](https://mods.factorio.com/mod/SciencePackGalore) ([Forked](https://mods.factorio.com/mod/SciencePackGaloreForked))
- [Ultracube](https://mods.factorio.com/mod/Ultracube)
- [Pyanodons Alternative Energy](https://mods.factorio.com/mod/pyalternativeenergy)
	- Guano currently considers the provider and requester tank as valid machines to make it. Meaning the dependency graph follows the provider tank rather than biopyanoport
- [Nullius](https://mods.factorio.com/mod/nullius)


## Todo List:
- [ ] Implement the Base Items config pane
- [ ] Implement the Ignored Recipes config pane
- [ ] Refactor to use a GUI library?
- [ ] See if the Base Items pane can support numbers, so the exact tier can be set
- [ ] Make the empty space below the tier-display that style of background like the trains schedule
- [x] Make recipe ignoring happen inside the calculation core again. It was put in preprocessing to enable 'no recipes' to be a usable base case. That is no longer needed