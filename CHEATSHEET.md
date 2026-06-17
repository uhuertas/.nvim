# CHEATSHEET

## Search and replace (with confirmation)
`:%s/old/new/gc`

## Save and reuse a qflist

- Search whatever you need and save it to a qflist, then save the buffer to a file using `:w`
- Open the file and edit the lines to a suitable format with:
  `:%s/|\([0-9]\+\) col \([0-9]\+\)|/:\1:\2:`

Then you have two options:

- Open nvim with the qflist loaded
  `nvim -q <file>`

- Load the buffer as qflist
  `:cgetexpr getline(1,'$')`

## Search and replace (multi-file)

- Search using Telescope and save the results into quickfixlist
- `:cdo s/old-word/new-word/ge | update`
