# lua-states-mixin

Turn any Lua object into a state machine: each state is a method of the object, and the current state decides where the object can go next.

Add it to an object in one call, or mix it into a class. It was written for the DMC Solar2D (formerly Corona SDK) libraries, where it runs the connection states of the network libraries, but it's plain Lua 5.1 and runs anywhere:

```lua
local StatesMixModule = require 'lua_states_mix'

local door = StatesMixModule.patch()
function door:closed( next_state ) self:setState( next_state ) end
function door:open( next_state ) self:setState( next_state ) end

door:setState( 'closed' )
door:gotoState( 'open' )
print( door:getState() )  --> open
```

## Features

- States are plain methods; the current one accepts or refuses each move
- A stack of past states, to go back to the previous one
- Patch an existing object, or use the mixin as a parent class (lua-objects, or a plain metatable)
- Pure Lua 5.1, one file, no dependencies; MIT licensed

## Quick Start

The following steps will get you up and running in about 5 minutes with Lua 5.1 on macOS or Linux. You will make a door that opens, closes and locks, and refuses to lock while open.

Prerequisites: Lua 5.1 (`lua -v` shows `Lua 5.1.x`) and git.

### 1. Get the Code

In an empty folder:

```sh
git clone https://github.com/dmccuskey/lua-states-mixin.git
```

The module is `lua-states-mixin/dmc_lua/lua_states_mix.lua`.

### 2. Use It

Create `main.lua` in the same folder:

```lua
package.path = './lua-states-mixin/dmc_lua/?.lua;' .. package.path
local StatesMixModule = require 'lua_states_mix'

local door = StatesMixModule.patch()

-- each state is a method named after it: it gets the requested state
-- and decides whether to go there, by calling setState()

function door:closed( next_state )
	if next_state == 'open' or next_state == 'locked' then
		self:setState( next_state )
	else
		print( "can't go from closed to " .. next_state )
	end
end

function door:open( next_state )
	if next_state == 'closed' then
		self:setState( next_state )
	else
		print( "can't go from open to " .. next_state )
	end
end

function door:locked( next_state )
	if next_state == 'closed' then
		self:setState( next_state )
	else
		print( "can't go from locked to " .. next_state )
	end
end

door:setState( 'closed' )    -- the starting state
door:gotoState( 'open' )
print( door:getState() )
door:gotoState( 'locked' )
door:gotoState( 'closed' )
door:gotoState( 'locked' )
print( door:getState(), door:getPreviousState() )
door:gotoPreviousState()
print( door:getState() )
```

Run it:

```sh
lua main.lua
```

```text
open
can't go from open to locked
locked	closed
closed
```

If it shows `module 'lua_states_mix' not found`, run it from the folder that holds `lua-states-mixin/`.

To update, pull the repository again (`git -C lua-states-mixin pull`).

## How States Work

A state is a method of the object, named after the state. `setState( name )` makes that method the current state without calling it: use it for the starting state, and inside state methods to complete a move.

`gotoState( name, ... )` asks the current state to move: it calls the current state's method as `obj:<current>( name, ... )`. That method decides. To accept, it calls `setState( name )`, directly or through a helper that does the work of the move first; to refuse, it does nothing or raises an error. The DMC libraries use the second pattern, with a `do_<state>()` method per state that sets up the state and ends with `setState()`.

A stack keeps the states the object has left. When the current state accepts a move from `gotoState()`, its `setState()` pushes the state being left onto the stack; a refused move, by doing nothing or by an error, leaves the stack as it was. `getPreviousState()` returns the top of the stack, and `gotoPreviousState( ... )` asks the current state to move there, as `gotoState()` does; if the move is accepted, `setState()` pops it. A `setState()` called on its own, outside a move, doesn't change the stack. The stack has no limit unless you set one with `setStateStackLimit( n )` (or `stack_limit` in `resetStates()`'s params): then it keeps the `n` newest names and drops the oldest.

## Reference

### The Module

| member | is |
|---|---|
| `patch( [obj] )` | Adds the state properties and methods to `obj` (or a new table) and returns it. |
| `StatesMix` | The mixin: a table of the methods, to use as a parent class (below). It also holds `patch`. |
| `__version` | The module's version, `'1.4.0'`. |

### Methods

On a patched object, or an instance of a class that mixes in `StatesMix`:

| method | does |
|---|---|
| `setState( name )` | Makes the method `name` the current state and, inside a move, updates the stack. Errors if `name` isn't a string or the object has no method by that name. |
| `getState()` | Returns the current state's name, `''` before the first `setState()`. |
| `gotoState( name, ... )` | Calls the current state's method with `( name, ... )`; if it accepts, the state it leaves goes onto the stack. Errors if no state is set. |
| `getPreviousState()` | Returns the top of the stack. Errors if it's empty. |
| `gotoPreviousState( ... )` | Calls the current state's method with `( top, ... )`, where `top` is the top of the stack; if it accepts, the top is popped. Errors if the stack is empty. |
| `pushStateStack( name )` | Pushes a name onto the stack, so `gotoPreviousState()` goes there next. |
| `popStateStack()` | Removes and returns the top of the stack. Errors if it's empty. |
| `resetStates( [params] )` | Clears the current state and the stack. `params.debug_on` sets the debug flag (default `false`), `params.stack_limit` the stack limit (default none). |
| `setStateStackLimit( n )` | Keeps at most `n` names on the stack (a whole number from 1), dropping the oldest, now and on each push; `nil` removes the limit. |
| `setDebug( bool )` | With `true`, prints each move as `Lua States (debug) :: ...`. |

### As a Mixin

`StatesMix` holds the methods; its `__init__( self, params )` calls `resetStates( params )`, and `__undoInit__( self )` removes the state properties. With lua-objects (lua-class), mix it in with multiple inheritance:

```lua
local NetStream = newClass( { ObjectBase, StatesMix } )

function NetStream:__init__( ... )
	self:superCall( ObjectBase, '__init__', ... )
	self:superCall( StatesMix, '__init__', ... )
end
```

Without a class library, inherit from `StatesMix` with a metatable and call `__init__` for each object:

```lua
local StatesMix = StatesMixModule.StatesMix

local obj = setmetatable( {}, { __index=StatesMix } )
StatesMix.__init__( obj )
```

## In Solar2D

[dmc-states-mixin](https://github.com/dmccuskey/dmc-states-mixin) is the Solar2D package of this module. The DMC Solar2D libraries load it as `lib.dmc_lua.lua_states_mix` from their `dmc_corona/lib/dmc_lua/` folder, part of [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library); [dmc-websockets](https://github.com/dmccuskey/dmc-websockets) and [dmc-netstream](https://github.com/dmccuskey/dmc-netstream) run their connections with it.

## Known Issues

- If a state method raises an error during a move and the object then calls `setState()` directly, before any other move or `resetStates()`, that `setState()` still pushes the state the failed move started from.

Version 1.4.0 fixed those of 1.3.1: a refused or failed move left the stack wrong (`gotoState()` pushed before asking, `gotoPreviousState()` popped before asking); the module leaked the globals `_patch`, `outStr` and `errStr`; `StatesMix.patch( obj )`, from the old README, didn't exist; `__undoInit__()` reset the states rather than removing them; the version wasn't exported; the stack had no limit (now optional, `setStateStackLimit()`).

## Development

Only `dmc_lua/lua_states_mix.lua` is written here. [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library) copies it into its `dmc_lua/` with its Snakemake build (the `Snakefile` here registers it), and the DMC Solar2D libraries copy it from there into `dmc_corona/lib/dmc_lua/`.

The tests are in `spec/lua_states_spec.lua`, for [busted](https://lunarmodules.github.io/busted/) under Lua 5.1. From the repository's root folder:

```sh
busted spec
```

It ends with:

```text
34 successes / 0 failures / 0 errors / 0 pending : 0.003027 seconds
```

(The debug test prints a few `Lua States (debug)` lines.) The tests cover every method through `patch()`; of the mixin, only `__init__()` and `__undoInit__()`.

## License

lua-states-mixin is released under the [MIT License](LICENSE).
