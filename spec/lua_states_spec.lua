--[[
Testing for lua_states
--]]

package.path = './dmc_lua/?.lua;' .. package.path



--====================================================================--
--== Test: Lua States
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== Imports

local StatesMix = require 'lua_states_mix'



--====================================================================--
--== Testing Setup
--====================================================================--


describe( "Module Test: lua_states_mix.lua", function()

	local object

	setup( function()
	end)

	teardown( function()
	end)

	before_each( function()

		--== States Setup ==--

		object = {}
		StatesMix.patch( object )

		--== State Constants

		object.STATE_INIT = 'state_init'
		object.STATE_ONE = 'state_one'
		object.STATE_TWO = 'state_two'
		object.STATE_THREE = 'state_three'
		object.STATE_MISSING = 'missing_method'

		--== State Machine

		function object:state_init( next_state, params )
			if next_state == self.STATE_ONE then
				self:do_state_one( params )
			elseif next_state == self.STATE_TWO then
				self:do_state_two( params )
			else
				error("incorrect transition")
			end
		end

		function object:do_state_one( params )
			self:setState( self.STATE_ONE )
		end
		function object:state_one( next_state, params )
			if next_state == self.STATE_TWO then
				self:do_state_two( params )
			elseif next_state == self.STATE_THREE then
				self:do_state_three( params )
			else
				error("incorrect transition")
			end
		end

		function object:do_state_two( params )
			self:setState( self.STATE_TWO )
		end
		function object:state_two( next_state, params )
			if next_state == self.STATE_ONE then
				self:do_state_one( params )
			elseif next_state == self.STATE_THREE then
				self:do_state_three( params )
			else
				error("incorrect transition")
			end
		end

		function object:do_state_three( params )
			self:setState( self.STATE_THREE )
		end
		function object:state_three( next_state, params )
			if next_state == self.STATE_ONE then
				self:do_state_one( params )
			elseif next_state == self.STATE_TWO then
				self:do_state_two( params )
			else
				error("incorrect transition")
			end
		end

	end)

	after_each( function()
		object = nil
	end)


	describe("Method: setState()/getState()", function()

		it( "set first state", function()
			object:setState( object.STATE_INIT )
			assert.are.equal( object:getState(), object.STATE_INIT )

			object:setState( object.STATE_ONE )
			assert.are.equal( object:getState(), object.STATE_ONE )

			object:setState( object.STATE_ONE )
			assert.are.equal( object:getState(), object.STATE_ONE )
			assert.are.equal( object:_stateStackSize(), 0 ) -- private method
		end)

		it( "initial state is ''", function()
			assert.are.equal( object:getState(), '' )
		end)

		it( "must have a state name", function()
			assert.has.errors( function() object:setState( nil ) end )
		end)
		it( "must have method for state name", function()
			assert.has.errors( function() object:setState( object.STATE_MISSING ) end )
		end)

	end)


	describe("Method: gotoState()", function()

		it( "transitions from one state to next", function()
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )
			object:gotoState( object.STATE_TWO )

			assert.are.equal( object:getState(), object.STATE_TWO )
			assert.are.equal( object:_stateStackSize(), 2 ) -- private method
		end)

		it( "transitions from one state to next", function()
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_TWO )
			object:gotoState( object.STATE_ONE )

			assert.are.equal( object:getState(), object.STATE_ONE )
			assert.are.equal( object:_stateStackSize(), 2 ) -- private method
		end)

		it( "incorrect transition", function()
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )

			--[[
			note: we wouldn't get this error if the above
			state diagram was changed
			--]]
			assert.has.errors( function() object:gotoState( object.STATE_INIT ) end )
		end)

		it( "has no initial state set", function()
			assert.has.errors( function() object:gotoState( object.STATE_ONE ) end )
		end)
		it( "must have a state name", function()
			object:setState( object.STATE_INIT )
			assert.has.errors( function() object:gotoState( nil ) end )
		end)
		it( "must have method for state name", function()
			object:setState( object.STATE_INIT )
			assert.has.errors( function() object:gotoState( object.STATE_MISSING ) end )
		end)

	end)


	describe("Method: getPreviousState()/gotoPreviousState()", function()

		it( "transitions from one state to next", function()
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )
			object:gotoState( object.STATE_TWO )

			assert.are.equal( object:getState(), object.STATE_TWO )
			assert.are.equal( object:_stateStackSize(), 2 ) -- private method
		end)

		it( "transitions from one state to next", function()
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )
			object:gotoState( object.STATE_TWO )

			assert.are.equal( object:getPreviousState(), object.STATE_ONE )
			assert.are.equal( object:_stateStackSize(), 2 ) -- private method

			object:gotoPreviousState()

			assert.are.equal( object:getState(), object.STATE_ONE )
			assert.are.equal( object:_stateStackSize(), 1 ) -- private method
		end)

		it( "incorrect transition", function()
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )

			assert.are.equal( object:getState(), object.STATE_ONE )
			assert.are.equal( object:getPreviousState(), object.STATE_INIT )

			--[[
			note: we wouldn't get this error if the above
			state diagram was changed
			--]]
			assert.has.errors( function() object:gotoPreviousState() end )

			assert.are.equal( object:getState(), object.STATE_ONE )
		end)

		it( "has no previous state", function()
			object:setState( object.STATE_INIT )
			assert.has.errors( function() object:getPreviousState() end )
			assert.has.errors( function() object:gotoPreviousState() end )
		end)

	end)


	describe("Method: pushState()/popState()", function()

		it( "transitions from one state to next", function()
			object:setState( object.STATE_INIT )

			object:gotoState( object.STATE_ONE )
			object:pushStateStack( object.STATE_TWO )
			object:pushStateStack( object.STATE_THREE )

			assert.are.equal( object:getState(), object.STATE_ONE )
			assert.are.equal( object:getPreviousState(), object.STATE_THREE )
			assert.are.equal( object:_stateStackSize(), 3 ) -- private method

			object:gotoPreviousState()

			assert.are.equal( object:getState(), object.STATE_THREE )
			assert.are.equal( object:getPreviousState(), object.STATE_TWO )
			assert.are.equal( object:_stateStackSize(), 2 ) -- private method
		end)

	end)


	describe("Method: resetStates()", function()

		it( "resets all state information", function()
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )
			object:gotoState( object.STATE_TWO )

			object:resetStates()

			assert.are.equal( object:getState(), '' )
			assert.are.equal( object:_stateStackSize(), 0 ) -- private method
		end)

	end)


	describe("Method: setDebug()", function()

		it( "shows state output", function()
			object:setDebug( true )

			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )
			object:gotoState( object.STATE_TWO )
			object:gotoPreviousState()

			object:resetStates()

			object:setDebug( false )

			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )
			object:gotoState( object.STATE_TWO )
			object:gotoPreviousState()

			object:resetStates()
		end)

	end)


	describe("Refused and failed moves", function()

		it( "a refused gotoState() leaves the stack as it was", function()
			function object:state_one( next_state )
				-- refuses every move, without an error
			end
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )

			object:gotoState( object.STATE_TWO )

			assert.are.equal( object:getState(), object.STATE_ONE )
			assert.are.equal( object:getPreviousState(), object.STATE_INIT )
			assert.are.equal( object:_stateStackSize(), 1 ) -- private method
		end)

		it( "a failed gotoState() leaves the stack as it was", function()
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )

			assert.has.errors( function() object:gotoState( object.STATE_INIT ) end )

			assert.are.equal( object:getState(), object.STATE_ONE )
			assert.are.equal( object:getPreviousState(), object.STATE_INIT )
			assert.are.equal( object:_stateStackSize(), 1 ) -- private method

			-- the next move works, and pushes only its own state
			object:gotoState( object.STATE_TWO )
			assert.are.equal( object:getPreviousState(), object.STATE_ONE )
			assert.are.equal( object:_stateStackSize(), 2 ) -- private method
		end)

		it( "a refused gotoPreviousState() keeps the previous state", function()
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )

			assert.has.errors( function() object:gotoPreviousState() end )

			assert.are.equal( object:getState(), object.STATE_ONE )
			assert.are.equal( object:getPreviousState(), object.STATE_INIT )
			assert.are.equal( object:_stateStackSize(), 1 ) -- private method
		end)

		it( "a move made inside a move stacks in order", function()
			function object:do_state_two( params )
				self:setState( self.STATE_TWO )
				self:gotoState( self.STATE_THREE )
			end
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_TWO )

			assert.are.equal( object:getState(), object.STATE_THREE )
			assert.are.equal( object:popStateStack(), object.STATE_TWO )
			assert.are.equal( object:popStateStack(), object.STATE_INIT )
		end)

		it( "setState() alone doesn't change the stack", function()
			object:setState( object.STATE_INIT )
			object:setState( object.STATE_ONE )

			assert.are.equal( object:_stateStackSize(), 0 ) -- private method
		end)

	end)


	describe("Method: setStateStackLimit()", function()

		it( "has no limit by default", function()
			object:setState( object.STATE_INIT )
			for i=1,50 do
				object:gotoState( object.STATE_ONE )
				object:gotoState( object.STATE_TWO )
			end
			assert.are.equal( object:_stateStackSize(), 100 ) -- private method
		end)

		it( "drops the oldest names past the limit", function()
			object:setStateStackLimit( 2 )
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )
			object:gotoState( object.STATE_TWO )
			object:gotoState( object.STATE_THREE )

			assert.are.equal( object:_stateStackSize(), 2 ) -- private method
			assert.are.equal( object:popStateStack(), object.STATE_TWO )
			assert.are.equal( object:popStateStack(), object.STATE_ONE )
		end)

		it( "limits pushStateStack() too", function()
			object:setStateStackLimit( 1 )
			object:pushStateStack( object.STATE_ONE )
			object:pushStateStack( object.STATE_TWO )

			assert.are.equal( object:_stateStackSize(), 1 ) -- private method
			assert.are.equal( object:getPreviousState(), object.STATE_TWO )
		end)

		it( "trims a stack already past a new limit", function()
			object:pushStateStack( object.STATE_ONE )
			object:pushStateStack( object.STATE_TWO )
			object:pushStateStack( object.STATE_THREE )

			object:setStateStackLimit( 1 )

			assert.are.equal( object:_stateStackSize(), 1 ) -- private method
			assert.are.equal( object:getPreviousState(), object.STATE_THREE )
		end)

		it( "nil removes the limit", function()
			object:setStateStackLimit( 1 )
			object:setStateStackLimit( nil )
			object:pushStateStack( object.STATE_ONE )
			object:pushStateStack( object.STATE_TWO )

			assert.are.equal( object:_stateStackSize(), 2 ) -- private method
		end)

		it( "must be nil or a whole number from 1", function()
			assert.has.errors( function() object:setStateStackLimit( 0 ) end )
			assert.has.errors( function() object:setStateStackLimit( 1.5 ) end )
			assert.has.errors( function() object:setStateStackLimit( '2' ) end )
		end)

		it( "is set by resetStates(), which clears it by default", function()
			object:resetStates( { stack_limit=1 } )
			object:pushStateStack( object.STATE_ONE )
			object:pushStateStack( object.STATE_TWO )
			assert.are.equal( object:_stateStackSize(), 1 ) -- private method

			object:resetStates()
			object:pushStateStack( object.STATE_ONE )
			object:pushStateStack( object.STATE_TWO )
			assert.are.equal( object:_stateStackSize(), 2 ) -- private method
		end)

		it( "is set by the mixin's __init__()", function()
			local Mix = StatesMix.StatesMix
			local obj = setmetatable( {}, { __index=Mix } )
			Mix.__init__( obj, { stack_limit=1 } )
			obj:pushStateStack( 'a' )
			obj:pushStateStack( 'b' )

			assert.are.equal( obj:_stateStackSize(), 1 ) -- private method
		end)

	end)


	describe("Module", function()

		it( "exports its version", function()
			assert.are.equal( type( StatesMix.__version ), 'string' )
		end)

		it( "has patch() on the mixin too", function()
			assert.are.equal( StatesMix.StatesMix.patch, StatesMix.patch )
		end)

		it( "sets no globals", function()
			assert.is_nil( rawget( _G, '_patch' ) )
			assert.is_nil( rawget( _G, 'outStr' ) )
			assert.is_nil( rawget( _G, 'errStr' ) )
		end)

		it( "__undoInit__() removes the state properties", function()
			local Mix = StatesMix.StatesMix
			object:setState( object.STATE_INIT )
			object:gotoState( object.STATE_ONE )

			Mix.__undoInit__( object )

			assert.is_nil( object.__state_stack )
			assert.is_nil( object.__curr_state_func )
			assert.is_nil( object.__curr_state_name )
			assert.is_nil( object.__stack_limit )
			assert.is_nil( object.__debug_on )
		end)

	end)


end)
