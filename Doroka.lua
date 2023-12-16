script_author('Nero')
script_name('Doroka Tools')
script_version('1.0 beta')

function addChat(text)
	local color_chat = 'aa3197'
	local text = tostring(text):gsub('{mc}', '{' .. color_chat .. '}'):gsub('{%-1}', '{FFFFFF}')
	sampAddChatMessage(string.format('« %s » {FFFFFF}%s', thisScript().name, text), tonumber('0x' .. color_chat))
end

local enable_autoupdate = true -- Set to false to disable auto-update + disable sending initial telemetry (server, moonloader version, script version, samp nickname, virtual volume serial number)
local autoupdate_loaded = false
local Update = nil

if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, [[
        return {
            check = function(a, b, c)
                local d = require('moonloader').download_status
                local e = os.tmpname()
                local f = os.clock()

                if doesFileExist(e) then
                    os.remove(e)
                end

                downloadUrlToFile(a, e, function(g, h, i, j)
                    if h == d.STATUSEX_ENDDOWNLOAD then
                        if doesFileExist(e) then
                            local k = io.open(e, 'r')
                            if k then
                                local l = decodeJson(k:read('*a'))
                                updatelink = l.updateurl
                                updateversion = l.latest
                                k:close()
                                os.remove(e)

                                if updateversion ~= thisScript().version then
                                    lua_thread.create(function(b)
                                        local d = require('moonloader').download_status
                                        local m = -1

                                        addChat('Обнаружено обновление. Пытаюсь обновиться c ' .. thisScript().version .. ' на ' .. updateversion, m)
                                        wait(250)

                                        downloadUrlToFile(updatelink, thisScript().path, function(n, o, p, q)
                                            if o == d.STATUS_DOWNLOADINGDATA then
                                                print(string.format('Загружено %d из %d.', p, q))
                                            elseif o == d.STATUS_ENDDOWNLOADDATA then
                                                addChat('Загрузка обновления завершена.')
                                                addChat('Обновление завершено!', m)
                                                goupdatestatus = true
                                                lua_thread.create(function()
                                                    wait(500)
                                                    thisScript():reload()
                                                end)
                                            end

                                            if o == d.STATUSEX_ENDDOWNLOAD then
                                                if goupdatestatus == nil then
                                                    addChat('Обновление прошло неудачно. Запускаю устаревшую версию..', m)
                                                    update = false
                                                end
                                            end
                                        end)
                                    end, b)
                                else
                                    update = false
                                    addChat('Версия: ' .. thisScript().version .. '. Обновление не требуется.')

                                    if l.telemetry then
                                        local r = require("ffi")
                                        r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"
                                        local s = r.new("unsigned long[1]", 0)
                                        r.C.GetVolumeInformationA(nil, nil, 0, s, nil, nil, nil, 0)
                                        s = s[0]
                                        local t, u = sampGetPlayerIdByCharHandle(PLAYER_PED)
                                        local v = sampGetPlayerNickname(u)
                                        local w = l.telemetry.."?id=" .. s .. "&n=" .. v .. "&i=" .. sampGetCurrentServerAddress() .. "&v=" .. getMoonloaderVersion() .. "&sv=" .. thisScript().version .. "&uptime=" .. tostring(os.clock())
                                        lua_thread.create(function(c)
                                            wait(250)
                                            downloadUrlToFile(c)
                                        end, w)
                                    end
                                end
                            end
                        else
                            update = false
                        end
                    end
                end)

                while update ~= false and os.clock() - f < 10 do
                    wait(100)
                end
            end
        }
    ]])

    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        
        if autoupdate_loaded then
            Update.json_url = "https://raw.githubusercontent.com/ImNotSoftik/samp/main/ver.json?" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = ""
        end
    end
end

require("moonloader")
require("sampfuncs")
local samp_check, sampev			= pcall(require, 'samp.events')
local mimgui_check, imgui			= pcall(require, 'mimgui')
local faCheck, fa 					= pcall(require, "fAwesome6")
local encoding						= require('encoding')
encoding.default					= 'CP1251'

local u8 = encoding.UTF8

function loadLib(lib_data)
    local dlstatus = require('moonloader').download_status
    local loadPath = ''
    if lib_data.folder ~= '' then
        if not doesDirectoryExist(getWorkingDirectory()..'\\lib\\'..lib_data.folder) then
            createDirectory(getWorkingDirectory()..'\\lib\\'..lib_data.folder)
            print('Folder '..getWorkingDirectory()..'\\lib\\'..lib_data.folder..' created!')
        end
        loadPath = getWorkingDirectory()..'\\lib\\'..lib_data.folder..'\\'
    else
        loadPath = getWorkingDirectory()..'\\lib\\'
    end
    local files = table.getn(lib_data.files)
    local exists = 0
    for i = 1, table.getn(lib_data.files) do
        if doesFileExist(loadPath..lib_data.files[i].name) then
            exists = exists + 1
        end
    end
    if exists ~= files then
		addChat("Отсутствует библиотка {8f2610}" .. lib_data.name .. "{ffffff} запускаю автоматическую подгрузку!")
        for i = 1, table.getn(lib_data.files) do
            if doesFileExist(loadPath..lib_data.files[i].name) then
                print('error, file "'..loadPath..lib_data.files[i].name..'" already exists!')
            else
                downloadUrlToFile(lib_data.files[i].link, loadPath..lib_data.files[i].name, function (id, status, p1, p2)
                    if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                        print("скачиваю файл: " .. tostring(lib_data.files[i].name))
                    end
                end)
            end
        end
    end
end

local libs = {
    sampevv = {
        name = 'SAMP.lua', folder = 'samp',
        files = {
            {name = 'events.lua', link = "https://raw.githubusercontent.com/THE-FYP/SAMP.Lua/master/samp/events.lua"},
            {name = 'raknet.lua', link = "https://raw.githubusercontent.com/THE-FYP/SAMP.Lua/master/samp/raknet.lua"},
            {name = 'utils.lua', link = "https://raw.githubusercontent.com/THE-FYP/SAMP.Lua/master/samp/events/utils.lua"},
            {name = 'handlers.lua', link = "https://raw.githubusercontent.com/THE-FYP/SAMP.Lua/master/samp/events/handlers.lua"},
            {name = 'extra_types.lua', link = "https://raw.githubusercontent.com/THE-FYP/SAMP.Lua/master/samp/events/extra_types.lua"},
            {name = 'bitstream_io.lua', link = "https://raw.githubusercontent.com/THE-FYP/SAMP.Lua/master/samp/events/bitstream_io.lua"},
            {name = 'core.lua', link = "https://raw.githubusercontent.com/THE-FYP/SAMP.Lua/master/samp/events/core.lua"},
        },
    },
    mimgui = {
        name = 'mimgui', folder = 'mimgui',
        files = {
            {name = 'cdefs.lua', link = "https://raw.githubusercontent.com/ImNotSoftik/samp/main/cdefs.lua"},
            {name = 'cimguidx9.dll', link = "https://github.com/ImNotSoftik/samp/raw/main/cimguidx9.dll"},
            {name = 'dx9.lua', link = "https://raw.githubusercontent.com/ImNotSoftik/samp/main/dx9.lua"},
            {name = 'imgui.lua', link = "https://raw.githubusercontent.com/ImNotSoftik/samp/main/imgui.lua"},
            {name = 'init.lua', link = "https://raw.githubusercontent.com/ImNotSoftik/samp/main/init.lua"},
        },
    }	
}

do -- Xcfg Modified
    Xcfg = {
        _version    = 2.1,
        _author     = "Double Tap Inside",
        _modified   = "JustFedot",
        _email      = "double.tap.inside@gmail.com",
        _help = [[
            Module xcfg             = Xcfg()
            Создает и возвращает новый экземпляр модуля Xcfg.
    
            nil                     = xcfg.mkpath(Str filename)
            Создает необходимые директории для указанного пути файла.
    
            Table loaded / nil      = xcfg.load(Str filename, [Bool save = false])
            Загружает конфигурационный файл. Если 'save' установлено в true, автоматически сохраняет файл после загрузки.
    
            Bool result             = xcfg.save(Str filename, Table new)
            Сохраняет данные в конфигурационный файл.
    
            Bool result             = xcfg.insert(Str filename, (Value value or Int index), [Value value])
            Вставляет значение в конфигурационный файл. Если указан индекс, вставляет по индексу.
    
            Bool result             = xcfg.remove(Str filename, [Int index])
            Удаляет значение из конфигурационного файла. Если указан индекс, удаляет значение по индексу.
    
            Bool result             = xcfg.set(Str filename, (Int index or Str key), Value value)
            Устанавливает или обновляет значение в конфигурационном файле по ключу или индексу.
    
            Bool result             = xcfg.update(Table old, (Table new or StrFilename new), [Bool overwrite = true])
            Обновляет старую таблицу новыми значениями из другой таблицы или файла. 'overwrite' определяет, перезаписывать ли существующие значения.
    
            Bool result             = xcfg.write(Str filename, Str str)
            Пишет строку в файл, перезаписывая его содержимое.
    
            Bool result             = xcfg.append(Str filename, Str str)
            Добавляет строку в конец файла.
    
            Table                   = xcfg.setupImcfg(Table cfg)
            Создает и возвращает таблицу с элементами управления imgui на основе конфигурационной таблицы 'cfg'. Поддерживает различные типы данных, включая вложенные таблицы.
        ]]
    }
	function Xcfg.__init()
		local self = {}
		
		-- draw values
		local function draw_string(str)
			return string.format("%q", str)
		end
		
		local function is_var(key_or_index)
			if type(key_or_index) == "string" and key_or_index:match("^[_%a][_%a%d]*$") then
				return true
			
			else
				return false
			end
		end
		
		local function draw_table_key(key)
			if is_var(key) then
				return key
				
			else
				return "["..draw_key(key).."]"
			end
		end
		
		local function draw_table(tbl, tab)
			local tab = tab or ""
			local result = {}
			
			for key, value in pairs(tbl) do
				if type(value) == "string" then
					if type(key) == "number" and key <= #tbl then
						table.insert(result, draw_string(value))
						
					else
						table.insert(result, draw_table_key(key).." = "..draw_string(value))
					end
					
				elseif type(value) == "number" or type(value) == "boolean" then
					if type(key) == "number" and key <= #tbl then
						table.insert(result, tostring(value))
						
					else
						table.insert(result, draw_table_key(key).." = "..tostring(value))
					end
				
				elseif type(value) == "table" then
					if type(key) == "number" and key <= #tbl then
						table.insert(result, draw_table(value, tab.."\t"))
						
					else
						table.insert(result, draw_table_key(key).." = "..draw_table(value, tab.."\t"))
					end
					
				else
					if type(key) == "number" and key <= #tbl then
						table.insert(result, draw_string(tostring(value)))
						
					else
						table.insert(result, draw_table_key(key).." = "..draw_string(tostring(value)))
					end
				end
			end
			
			if #result == 0 and tab == "" then
				return ""
				
			elseif #result == 0 then
				return "{}"
			
			elseif tab == "" then
				return table.concat(result, ",\n")..",\n"
			
			else
				return "{\n"..tab..table.concat(result, ",\n"..tab)..",\n"..tab:sub(2).."}"
			end       
		end
		
		local function draw_value(value, tab)
			if type(value) == "string" then
				return draw_string(value)
			
			elseif type(value) == "number" or type(value) == "boolean" or type(value) == "nil" then
				return tostring(value)
			
			elseif type(value) == "table" then
				return draw_table(value, tab)
				
			else
				return draw_string(tostring(value))
			end
		end
		
		local function draw_key(key)
			if "string" == type(key) then
				return draw_string(key)
			
			elseif "number" == type(key) then
				return tostring(key)
			end
		end
		
		
		local function draw_config(tbl)
			local result = {}
		
			for key, value in pairs(tbl) do
				
				if type(key) == "number" then
					table.insert(result, "table.insert(tbl, "..draw_value(value, "\t")..")")
				
				elseif type(key) == "string" then			
					if is_var(key) then
						table.insert(result, "tbl."..draw_table_key(key).." = "..draw_value(value, "\t"))
					
					else
						table.insert(result, "tbl"..draw_table_key(key).." = "..draw_value(value, "\t"))
					end
				end
			end
			
			if #result == 0 then
				return ""
				
			else
				return table.concat(result, "\n").."\n"
			end
		end

		function self.load(filename, overwrite)
			assert(type(filename)=="string", ("bad argument #1 to 'load' (string expected, got %s)"):format(type(filename)))
			
			if overwrite == nil then
				overwrite = false
			end
			
			local file = io.open(filename, "r")
			
			if file then
				local text = file:read("*all")
				file:close()
				local lua_code = loadstring("local tbl = {}\n"..text.."\nreturn tbl")
				
				if lua_code then
					local result = lua_code()
					
					if type(result) == "table" then
						if overwrite then
							self.save(filename, result)
						end
						
						return result
					end
				end
			end
		end
		
		function self.save(filename, new)
			assert(type(filename)=="string", ("bad argument #1 to 'table_save' (string expected, got %s)"):format(type(filename)))
			assert(type(new)=="table", ("bad argument #2 to 'table_save' (table expected, got %s)"):format(type(new)))
		
			self.mkpath(filename)
			local file = io.open(filename, "w+")
			
			if file then
				local text = draw_config(new)
				file:write(text)
				file:close()
				
				return true
			else
				return false
			end
		end
		
		function self.insert(filename, value_or_index, value)
			assert(type(filename)=="string", ("bad argument #1 to 'insert' (string expected, got %s)"):format(type(filename)))
			
			if value then
				assert(type(value_or_index)=="number", ("bad argument #2 to 'insert' (number expected, got %s)"):format(type(value_or_index)))
			end
			
			local result
			
			if value then
				result = "table.insert(tbl, "..value_or_index..", "..draw_value(value, "\t")..")"
				
			else
				result = "table.insert(tbl, "..draw_value(value_or_index, "\t")..")"
			end
			
			self.mkpath(filename)
			local file = io.open(filename, "a+")
			
			if file then
				file:write(result.."\n")
				file:close()
				return true
				
			else
				return false
			end
		end
		
		function self.remove(filename, index)
			assert(type(filename)=="string", ("bad argument #1 to 'remove' (string expected, got %s)"):format(type(filename)))
			assert(type(index)=="number" or index == nil, ("bad argument #2 to 'remove' (number or nil expected, got %s)"):format(type(index)))
			local result
			
			if index then
				result = "table.remove(tbl, "..index..")"
				
			else
				result = "table.remove(tbl)"
			end
			
			self.mkpath(filename)
			local file = io.open(filename, "a+")
			
			if file then
				file:write(result.."\n")
				file:close()
				return true
				
			else
				return false
			end
		end
		
		function self.set(filename, key, value)
			assert(type(filename)=="string", ("bad argument #1 to 'set' (string expected, got %s)"):format(type(filename)))
			assert(type(key)=="number" or type(key)=="string", ("bad argument #2 to 'set' (number or string expected, got %s)"):format(type(key)))
			
			local result
					
			if is_var() then
				result = "tbl."..tostring(var).." = "..draw_value(value, "\t")
			
			else
				result = "tbl["..draw_key(key).."] = "..draw_value(value, "\t")
			end
			
			self.mkpath(filename)
			local file = io.open(filename, "a+")
			
			if file then
				file:write(result.."\n")
				file:close()
				return true
				
			else
				return false
			end
		end
		
		function self.mkpath(filename)
			assert(type(filename)=="string", ("bad argument #1 to 'mkpath' (string expected, got %s)"):format(type(filename)))
		
			local sep, pStr = package.config:sub(1, 1), ""
			local path = filename:match("(.+"..sep..").+$") or filename
			
			for dir in path:gmatch("[^" .. sep .. "]+") do
				pStr = pStr .. dir .. sep
				createDirectory(pStr)
			end
		end

		function self.update(old, new, overwrite)
			assert(type(old)=="table", ("bad argument #1 to 'update' (table expected, got %s)"):format(type(old)))
			assert(type(new)=="string" or type(new)=="table", ("bad argument #2 to 'update' (string or table expected, got %s)"):format(type(new)))
			
			if overwrite == nil then
				overwrite = true
			end
		
			if type(new) == "table" then
				if overwrite then
					for key, value in pairs(new) do
						old[key] = value
					end
					
				else
					for key, value in pairs(new) do
						if old[key] == nil then
							old[key] = value
						end
					end
				end
				
				return true
				
			elseif type(new) == "string" then
				local loaded = self.load(new)
				
				if loaded then
					if overwrite then
						for key, value in pairs(loaded) do
							old[key] = value
						end
						
					else
						for key, value in pairs(loaded) do
							if old[key] == nil then
								old[key] = value
							end
						end
					end
					
					return true
				end
			end
			
			return false
		end
		
		function self.append(filename, str)
			self.mkpath(filename)
			local file = io.open(filename, "a+")
			
			if file then
				file:write(str)
				file:close()
				return true
				
			else
				return false
			end
		end
		
		function self.write(filename, str)
			self.mkpath(filename)
			local file = io.open(filename, "w+")
			
			if file then
				file:write(str)
				file:close()
				return true
				
			else
				return false
			end
		end

        function self.setupImcfg(cfg)
            assert(type(cfg) == "table", ("bad argument #1 to 'setupImcfg' (table expected, got %s)"):format(type(cfg)))
            local function setupImcfgRecursive(cfg)
                local imcfg = {}
                for k, v in pairs(cfg) do
                    if type(v) == "table" then
                        imcfg[k] = setupImcfgRecursive(v)
                    elseif type(v) == "number" then
                        if v % 1 == 0 then
                            imcfg[k] = imgui.ImInt(v)
                        else
                            imcfg[k] = imgui.ImFloat(v)
                        end
                    elseif type(v) == "string" then
                        imcfg[k] = imgui.ImBuffer(256)
                        imcfg[k].v = u8(v)
                    elseif type(v) == "boolean" then
                        imcfg[k] = imgui.ImBool(v)
                    else
                        assert(false, ("Unsupported type for imcfg: %s"):format(type(v)))
                    end
                end
                return imcfg
            end
            return setupImcfgRecursive(cfg)
        end
		
		return self
	end
	setmetatable(Xcfg, {
	__call = function(self)
		return self.__init()
	end
})
end
local xcfg = Xcfg()

local filename = getWorkingDirectory()..'\\config\\'..thisScript().name..'\\config.cfg'

local cfg = {
    aim = false,
    nospread = false,
}

xcfg.update(cfg, filename)

function saveConfig()
    xcfg.save(filename, cfg)
end

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	loadLib(libs.sampevv)
	loadLib(libs.mimgui)	
	pcall(Update.check, Update.json_url, Update.prefix, Update.url)
	wait(2000)	
    addChat('Скрипт загружен. Активация: /drt')
    sampRegisterChatCommand('drt', function() WinState[0] = not WinState[0] end)
	wait(-1)
end