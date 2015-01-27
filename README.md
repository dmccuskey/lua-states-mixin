## lua-states-mixin ##

Add State Machine capability to your Lua objects

This module can add State Machine capability to any of your objects. It can be used either as a mixin class or by "monkey-patching" your object. It was designed to work with [lua-objects](https://github.com/dmccuskey/lua-objects) and has also been integrated in [dmc-objects](https://github.com/dmccuskey/dmc-objects) as a mixin.


### Features ###

* state methods

  getState(), setState(), gotoState()
  
  getPreviousState(), gotoPreviousState()
  
  pushStateStack(), popStateStack()
  
  resetStates(), setDebug()


### Examples ###

#### Mixin Class ####

This module can be used as a mixin project [dmc-objects](https://github.com/dmccuskey/dmc-objects) contains the `ObjectBase` sub-class which shows how to use this module as a mixin with multiple inheritance.

Here it is in a nutshell:

```lua
-- import the events mixin module (adjust path for your project)
local StatesMixModule = require 'dmc_lua.lua_states_mix'

-- create ref to mixin (optional)
local StatesMix = StatesMixModule.StatesMix

-- do multiple inheritance !
NetStream = newClass( { ObjectBase, StatesMix } )

-- Then call init method in your OO Framework construction phase

-- with dmc-objects
	self:superCall( StatesMix, '__init__', params )

-- with other frameworks
	StatesMix.__init__( self, ... )


-- When destroying, you can call __undoInit__

-- with dmc-objects
	self:superCall( StatesMix, '__undoInit__' )

-- with other frameworks
	StatesMix.__undoInit__( self )

```


#### Monkey Patching ####


```lua
--== Import module

local StatesMixModule = require 'dmc_lua.lua_states_mix'


--== Setup ref to mixin (optional)
local StatesMix = StatesMixModule.StatesMix


--== Patch an object ==--

-- create one for yourself (eg, with OOP library)

local obj = {}  -- empty or create one from your OOP library
obj = StatesMix.patch( obj ) -- returns object


-- or have patch() create one for you

local obj = StatesMix.patch()  -- returns a new object




```

