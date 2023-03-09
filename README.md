# COGNAC

:tumbler_glass: **C**oil **O**peratin**g** Poi**n**t D**a**ta S**c**raper :tumbler_glass: 

Get operating point data for coils from the
[coilcraft](https://www.coilcraft.com/) REST API.

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

If you get a 

```
error code: 1015 ... sleeping for 30s
```

message **don't worry** this error is caught and handled, after 30 seconds of
waiting the loop continues. This is due to rate limiting by coilcraft :fu:,
which is also the reason we can't parallelize. After a handful requests we'd
get a `1015` and would need to wait anyway.

## Dependencies

`lua` 5.4 and the following [rocks](https://luarocks.org/):

- `lua-cjson`
- `lua-curl`
- `socket`
