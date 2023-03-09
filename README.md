# COGNAC

:tumbler_glass: **C**oil **O**peratin**g** Poi**n**t D**a**ta S**c**raper :tumbler_glass: 

Get operating point data for coils from the coilcraft REST API.

## Usage

1. Adjust the `PartNumber` in `coil.lua`
1. Run the script
1. ???
1. Profit

```lua
local part = 'XXX'
```

```shell
$ lua coil.lua
```

### Rate Limiting

Be ware of rate limiting by coilcraft :fu:. That's the reason we can't
parallelize. After a handful requests we'd get a `1015`.

## Dependencies

`lua` 5.4 and the following [rocks](https://luarocks.org/):

- `lua-cjson`
- `lua-curl`
- `socket`
