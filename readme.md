# export_tikz
A `MATLAB` library for exporting low-latency figures for embedding within `LaTeX` documents using `TikZ`.


## Background and Features
This package exists in a similar vein as packages like 
[`matlab2tikz`](https://github.com/matlab2tikz/matlab2tikz)
which convert `MATLAB` figures into `TikZ` images for embedding within `LaTeX` projects.
Whereas `matlab2tikz` converts the *entire* figure to `pgf` commands, this tool 
takes a different approach. 
Rather, the `MATLAB` figure (excluding all text items) is rendered and saved as a `pdf`. 
Then, a `tex` 'overlay' file is generated with the appropriate TikZ commands to reinsert
the textual data as text nodes rendered with LaTeX typesetting.

This ensures that the textual information (titles, ticks, labels, annotations, etc.) 
is rendered consistently with the rest of your document while retaining the exact rendering
displayed by the MATLAB figure. 
Additionally, it avoids some of the complications and errors that arise when rendering 
`MATLAB` plots entirely through `pgf` commands (e.g., the `TeX capacity exceeded` error) and cuts down on document compile times.
It also enables exotic third-party plotting functionality to be rendered as they appear 
in `MATLAB` (excluding, perhaps, some exotic text nodes not detected by this utility).


## Installation
### Prerequisites
This library was written under `MATLAB R2019b` and is not guaranteed to work 
under previous versions.

### Installing
Simply place both the `save_overtikz.m` file and `+overtikz` folder in your
[`MATLAB` user work folder](https://www.mathworks.com/help/matlab/ref/userpath.html).


### Updating
Simply replace the `save_overtikz.m` file and `+overtikz` folder in your
[`MATLAB` user work folder](https://www.mathworks.com/help/matlab/ref/userpath.html)
with the more current versions.

## Usage
In `MATLAB`, the current figure can be exported by simply calling

```
save_overtikz(yourName)
```

where `yourName` is the `base name` for the output files.


## Development and contributing
This library is in active development. If a bug is found, please report it as an issue.
Feature requests are welcome, but there is no guarantee I will be able to implement them.


## Support Me
`export_overtikz` is open-source software for exporting low-latency MATLAB figures
for embedding within LaTeX documents.
If you like the work I've contributed to this project, you can support me by buying me a coffee!


[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/counselor.chip)

## License
Copyright (c) 2022-present Counselor Chip.
`export_overtikz` is free and open-source software licensed under the [MIT License](/LICENSE).

