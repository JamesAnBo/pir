addon.name      = 'PIR';
addon.author    = 'Aesk';
addon.version   = '1.0.0';
addon.desc      = 'The Price Is Right';
addon.link      = 'https://github.com/JamesAnBo/';

require('common');
local chat = require('chat');

local keyset={}
local pir = T{
	rolls = T{},
	collect = false,
	toMatch = 500,
	noWin = false,
	type = 'high',
	chat = 'none',
	time = '00',
};

local function isNum(str)
	if (str == nil) then
		return;
	end

	return not (str == "" or str:find("%D"))
end

local function popRolls()
	local rolls = T{}
	for k,v in pairs(pir.rolls) do
		table.insert(rolls,v)
	end
	return rolls
end

local function findHighest()
	local t = T{}
	for k,v in pairs(pir.rolls) do
		table.insert(t,v)
	end
	return math.max(table.unpack(t))
end

local function findLowest()
	local t = T{}
	for k,v in pairs(pir.rolls) do
		table.insert(t,v)
	end
	return math.min(table.unpack(t))
end

local function findClosest()
    local smallestSoFar, smallestIndex
	local t = T{}
	for k,v in pairs(pir.rolls) do
		table.insert(t,v)
	end
    for i, y in ipairs(t) do
        if not smallestSoFar or (math.abs(pir.toMatch-y) < smallestSoFar) then
            smallestSoFar = math.abs(pir.toMatch-y)
            smallestIndex = i
        end
    end
    return t[smallestIndex]
end

local function findUnder()
	local t = T{}
	for k,v in pairs(pir.rolls) do
		if v <= pir.toMatch then
			table.insert(t,v)
		end
	end
	if (#t > 0) then
		return math.max(table.unpack(t))
	else
		pir.noWin = true
	end
end

local function findOver()
	local t = T{}
	for k,v in pairs(pir.rolls) do
		if v >= pir.toMatch then
			table.insert(t,v)
		end
	end
	if (#t > 0) then
		return math.min(table.unpack(t))
	else
		pir.noWin = true
	end
end

local function matchWinner(num)
	for k,v in pairs(pir.rolls) do
		if num == v then
			PPrint('Winner: '..k..' with '..v)
		end
	end
end

local function getData(e)
	local t = T{}
	local rStr = struct.unpack('s', e.data, 0x15 + 1);
	for i in string.gmatch(rStr, "%S+") do
	   table.insert(t,i)
	end
	for k,v in pairs(pir.rolls) do
		if k == t[1] then
			PPrint(t[1]..' already rolled.')
			return;
		end
	end
	pir.rolls[t[1]] = tonumber(t[3])
end

local function list()
	PPrint('Type: '..pir.type)
	PPrint('Target roll: '..pir.toMatch)
	PPrint('Rolls:')
	for k, v in pairs(pir.rolls) do
		PPrint(k..': '..v)
	end
end

local function reset()
	pir.rolls = T{};
	pir.chat = 'none';
	pir.time = '00';
end

local function print_help(isError)
    if (isError) then
        print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/' .. addon.name)));
    else
        print(chat.header(addon.name):append(chat.message('Available commands:')));
    end

    local cmds = T{
		{ '/pir type <high|low|close|under|over>', 'Sets the win condition.' },
		{ '/pir target <#>', 'Sets the target roll # for close, under, and over.' },
		{ '/pir ready <none|party|linkshell> <in-game minute>', 'Warns to prepare for rolling at given minute and begins collecting rolls.' },
		{ '/pir done', 'Prints winner' },
		{ '/pir list', 'Prints current type, target, and rollers.' },
		{ '/pir collect', 'Toggles collecting rolls on/off.' },
		{ '/pir clear', 'Clears roll list and stops collecting rolls.' },
        { '/pir help', 'Displays help information.' },
    };

    cmds:ieach(function (v)
        print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])));
    end);
end


ashita.events.register('packet_in', 'packet_in_cb', function (e)
	if (pir.collect == false) then
		return;
	elseif (e.id == 0x09) and (e.size == 0x34)then
		getData(e)
	end
end);

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or args[1] ~= '/pir') then
        return;
    end

    e.blocked = true;
	
	local cmd = args[2];
	
    if (#args == 2) then
		if (cmd:any('help')) then
			print_help(false);
			return;
		elseif (cmd:any('list')) then
			list()
		elseif (cmd:any('collect','col')) then
			pir.collect = not pir.collect;
			PPrint('Collecting is now '..tostring(pir.collect))
		elseif (cmd:any('clear','reset','cl')) then
			reset()
			pir.collect = false;
			PPrint('Clearing saved rolls and stoping collection.')
		elseif (cmd:any('done','win')) then
			pir.collect = false;
			local roll
			if (pir.type == 'high') then
				PPrint('Highest:')
				roll = findHighest()
			elseif (pir.type == 'low') then
				PPrint('Lowest:')
				roll = findLowest()
			elseif (pir.type == 'close') then
				PPrint('Closest to '..pir.toMatch..':')
				roll = findClosest()
			elseif (pir.type == 'under') then
				PPrint('Closest under '..pir.toMatch..':')
				roll = findUnder()
			elseif (pir.type == 'over') then
				PPrint('Closest over '..pir.toMatch..':')
				roll = findOver()
			end
			if (pir.noWin) then
				PPrint('No winner.')
				pir.noWin = false;
				return;
			else
				matchWinner(roll)
			end
		else
			print_help(true);
		end
	elseif (#args >= 3) then
		if (cmd:any('type','ty')) then
			if (args[3]:any('high')) then
				pir.type = 'high'
			elseif (args[3]:any('low')) then
				pir.type = 'low'
			elseif (args[3]:any('close')) then
				pir.type = 'close'
			elseif (args[3]:any('under')) then
				pir.type = 'under'
			elseif (args[3]:any('over')) then
				pir.type = 'over'
			end
			PPrint('Type set to '..pir.type)
		elseif (cmd:any('target','tg')) then
			pir.toMatch = tonumber(args[3])
			PPrint('Target roll set to '..pir.toMatch)

		elseif (cmd:any('ready','rdy')) then
			
			if (#args == 4) then
				pir.chat = args[3]
				pir.time = args[4]
			elseif (#args == 3) and (isNum(args[3])) then
				pir.time = args[3]
			else
				PPrint('/pir ready <none|party|linkshell> <in-game minute>')
				reset()
				return;
			end
			if (tonumber(pir.time) > 60) then
				PPrint('minutes can\'t be greater then 60')
				reset()
				return;
			end
			if (pir.type == 'high') then
				PPrint('[Type: '..pir.type..'] [Chat: '..pir.chat..'] [@ :'..pir.time..']');
				if (pir.chat ~= 'none') then
					if (pir.chat:any('party','pt','p')) then
						AshitaCore:GetChatManager():QueueCommand(1, '/p Highest roll wins. /random @ :'..pir.time);
					elseif (pir.chat:any('linkshell','ls','l')) then
						AshitaCore:GetChatManager():QueueCommand(1, '/l Highest roll wins. /random @ :'..pir.time);
					end
				else
					PPrint('Unknown chat (\'party\' or \'linkshell\'')
					reset()
					return;
				end
			elseif (pir.type == 'low') then
				PPrint('[Type: '..pir.type..'] [Chat: '..pir.chat..'] [@ :'..pir.time..']');
				if (pir.chat ~= 'none') then
					if (pir.chat:any('party','pt','p')) then
						AshitaCore:GetChatManager():QueueCommand(1, '/p Lowest roll wins. /random @ :'..pir.time);
					elseif (pir.chat:any('linkshell','ls','l')) then
						AshitaCore:GetChatManager():QueueCommand(1, '/l Lowest roll wins. /random @ :'..pir.time);
					end
				else
					PPrint('Unknown chat (\'party\' or \'linkshell\'')
					reset()
					return;
				end
			elseif (pir.type == 'close') then
				PPrint('[Type: '..pir.type..'] [Chat: '..pir.chat..'] [Target: '..pir.toMatch..'] [@ :'..pir.time..']');
				if (pir.chat ~= 'none') then
					if (pir.chat:any('party','pt','p')) then
						AshitaCore:GetChatManager():QueueCommand(1, '/p Closest roll to '..pir.toMatch..' wins. /random @ :'..pir.time);
					elseif (pir.chat:any('linkshell','ls','l')) then
						AshitaCore:GetChatManager():QueueCommand(1, '/t Closest roll to '..pir.toMatch..' wins. /random @ :'..pir.time);
					end
				else
					PPrint('Unknown chat (\'party\' or \'linkshell\'')
					reset()
					return;
				end
				
			elseif (pir.type == 'under') then
				PPrint('[Type: '..pir.type..'] [Chat: '..pir.chat..'] [Target: '..pir.toMatch..'] [@ :'..pir.time..']');
				if (pir.chat ~= 'none') then
					if (pir.chat:any('party','pt','p')) then
						AshitaCore:GetChatManager():QueueCommand(1, '/p Highest roll under or equal to '..pir.toMatch..' wins. /random @ :'..pir.time);
					elseif (pir.chat:any('linkshell','ls','l')) then
						AshitaCore:GetChatManager():QueueCommand(1, '/l Highest roll under or equal to '..pir.toMatch..' wins. /random @ :'..pir.time);
					end
				else
					PPrint('Unknown chat (\'party\' or \'linkshell\'')
					reset()
					return;
				end
				
			elseif (pir.type == 'over') then
				PPrint('[Type: '..pir.type..'] [Chat: '..pir.chat..'] [Target: '..pir.toMatch..'] [@ :'..pir.time..']');
				if (pir.chat ~= 'none') then
					if (pir.chat:any('party','pt','p')) then
						AshitaCore:GetChatManager():QueueCommand(1, '/p Lowest roll over or equal to'..pir.toMatch..' wins. /random @ :'..pir.time);
					elseif (pir.chat:any('linkshell','ls','l')) then
						AshitaCore:GetChatManager():QueueCommand(1, '/l Lowest roll over or equal to'..pir.toMatch..' wins. /random @ :'..pir.time);
					end
				else
					PPrint('Unknown chat (Use \'party\' or \'linkshell\'')
					reset()
					return;
				end
				
			end
			reset()
			if pir.collect == false then
				pir.collect = true;
			end
		else
			print_help(true);
		end
	else
		print_help(true);
	end
end);

function PPrint(txt)
	print(chat.header(addon.name):append(chat.message(txt)));
end

