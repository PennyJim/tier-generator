[![shield](https://img.shields.io/badge/Crowdin-Translate-brightgreen)](https://crowdin.com/project/factorio-mods-localization)

# Tier Generator
calculates the `tier`, or the complexity of an item.

Considers what machine is required to craft, the ingredients, the technology, and its science packs.

## Explicit compatibility
- [Ultracube](https://mods.factorio.com/mod/Ultracube)
- [Pyanodons](https://mods.factorio.com/mod/pypostprocessing) [Alternative Energy](https://mods.factorio.com/mod/pyalternativeenergy) or [Hard Mode](https://mods.factorio.com/mod/pyhardmode)
- [Nullius](https://mods.factorio.com/mod/nullius)
- [Space Exploration](https://mods.factorio.com/mod/space-exploration)
	- Does not properly handle off-planet resources yet
- [More Science Packs](https://mods.factorio.com/mod/MoreSciencePacks-for1_1)
- [Science Packs Galore](https://mods.factorio.com/mod/SciencePackGalore) ([Forked](https://mods.factorio.com/mod/SciencePackGaloreForked))


## Todo List:
- [ ] Implement the Base Items config pane
- [ ] Implement the Ignored Recipes config pane
- [x] Refactor to use a GUI library?
- [ ] See if the Base Items pane can support numbers, so the exact tier can be set
- [x] Make the empty space below the tier-display that style of background like the trains schedule
- [x] Make recipe ignoring happen inside the calculation core again. It was put in preprocessing to enable 'no recipes' to be a usable base case. That is no longer needed