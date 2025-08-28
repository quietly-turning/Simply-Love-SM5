function force_to_range(min, number, max)
	return math.min(max, math.max(min, number))
end
function wrapped_index(start, offset, set_size)
	return ((start - 1 + offset) % set_size) + 1
end

-------------------------------

function table.rotate_right(t, r)
	local new_t= {}
	for n= 1, #t do
		local index= ((n - r - 1) % #t) + 1
		new_t[n]= t[index]
	end
	return new_t
end

function table.rotate_left(t, r)
	local new_t= {}
	for n= 1, #t do
		local index= ((n + r - 1) % #t) + 1
		new_t[n]= t[index]
	end
	return new_t
end

local sick_wheel= {}
sick_wheel_mt= { __index= sick_wheel }

local function check_metatable(item_metatable)
	assert(item_metatable.__index.create_actors, "The metatable must have a create_actors function.  This should return a Def.ActorFrame containing whatever actors will be needed for display.")
	assert(item_metatable.__index.transform, "The metatable must have a transform function.  The transform function must take 3 arguments:  position in list (1 to num_items), number of items in list, boolean indicating whether item has focus.")
	assert(item_metatable.__index.set, "The metatable must have a set function.  The set function must take an instance of info, which it should use to set its actors to display the info.")
end

function sick_wheel:create_actors(name, num_items, item_metatable, mx, my)
	self.name= name
	self.info_pos= 1
	self.info_map= {}
	self.num_items= num_items
	assert(item_metatable, "A metatable for items to be put in the wheel must be provided.")
	check_metatable(item_metatable)
	self.focus_pos= math.floor(num_items / 2)
	mx= mx or SCREEN_CENTER_X
	my= my or SCREEN_TOP
	self.items= {}
	local args= {
		Name= self.name,
		InitCommand= function(subself)
			subself:xy(mx, my)
			self.container= subself
		end
	}
	for n= 1, num_items do
		local item= setmetatable({}, item_metatable)
		local actor_frame= item:create_actors("item" .. n)
		self.items[#self.items+1]= item
		args[#args+1]= actor_frame
	end
	return Def.ActorFrame(args)
end

function sick_wheel:maybe_wrap_index(ipos, n, info)
	if self.disable_wrapping then
		return ipos - 1 + n
	else
		return wrapped_index(ipos, n, #info)
	end
end

local function calc_start(self, info, pos)
	pos= math.floor(pos) - self.focus_pos
	if self.disable_wrapping then
		pos= force_to_range(1, pos, #info - #self.items + 1)
		if pos < 1 then pos= 1 end
	end
	return pos
end

local function call_item_set(self, item_index, info_index)
	self.info_map[item_index]= info_index
	self.items[item_index]:set(self.info_set[info_index])
end

local function internal_scroll(self, start_pos)
	local shift_amount= start_pos - self.info_pos
	if math.abs(shift_amount) < #self.items then
		self.items= table.rotate_left(self.items, shift_amount)
		self.info_map= table.rotate_left(self.info_map, shift_amount)
		self.info_pos= start_pos
		if shift_amount < 0 then
			local absa= math.abs(shift_amount)
			for n= 1, absa+1 do
				if self.items[n] then
					local info_index= self:maybe_wrap_index(self.info_pos, n, self.info_set)
					call_item_set(self, n, info_index)
				end
			end
		elseif shift_amount > 0 then
			for n= #self.items - shift_amount, #self.items do
				if self.items[n] then
					local info_index= self:maybe_wrap_index(self.info_pos, n, self.info_set)
					call_item_set(self, n, info_index)
				end
			end
		end
	else
		self.info_pos= start_pos
		for i= 1, #self.items do
			local info_index= self:maybe_wrap_index(self.info_pos, i, self.info_set)
			call_item_set(self, i, info_index)
		end
	end
	for i, v in ipairs(self.items) do
		v:transform(i, #self.items, i == self.focus_pos)
	end
end

function sick_wheel:set_info_set(info, pos)
	local start_pos= calc_start(self, info, pos)
	self.info_set= info
	self.info_pos= start_pos
	for n= 1, #self.items do
		local index= self:maybe_wrap_index(start_pos, n, info)
		call_item_set(self, n, index)
	end
	internal_scroll(self, start_pos)
end

function sick_wheel:set_element_info(element, info)
	self.info_set[element]= info
	for i= 1, #self.items do
		if self.info_map[i] == element then
			call_item_set(self, i, element)
		end
	end
end

function sick_wheel:scroll_to_pos(pos)
	local start_pos= calc_start(self, self.info_set, pos)
	internal_scroll(self, start_pos)
end

function sick_wheel:scroll_by_amount(a)
	internal_scroll(self, self.info_pos + a)
end

function sick_wheel:get_index_at_focus_pos()
	local index= self:maybe_wrap_index(self.info_pos, self.focus_pos,self.info_set)
	return index
end

function sick_wheel:get_info_at_focus_pos()
	local index= self:get_index_at_focus_pos()
	return self.info_set[index]
end

function sick_wheel:get_actor_item_at_focus_pos()
	return self.items[self.focus_pos]
end

function sick_wheel:get_items_by_info_index(index)
	local ret= {}
	for i= 1, #self.items do
		if self.info_map[i] == index then
			ret[#ret+1]= self.items[i]
		end
	end
	return ret
end

function sick_wheel:find_item_by_info(info)
	local ret= {}
	for i, v in ipairs(self.items) do
		if v.info == info then
			ret[#ret+1]= v
		end
	end
	return ret
end
