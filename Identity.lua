local _, A = ...
local classes={WARRIOR=true,PALADIN=true,HUNTER=true,ROGUE=true,PRIEST=true,DEATHKNIGHT=true,
    SHAMAN=true,MAGE=true,WARLOCK=true,MONK=true,DRUID=true,DEMONHUNTER=true,EVOKER=true}
function A.ClassToken(token) return type(token)=='string' and classes[token] and token or nil end
function A.ClassInfo(info)
    local token=A.ClassToken(A.Plain(info.classFilename,'string'))
    local id=A.Plain(info.classID,'number')
    if not token and id and type(GetClassInfo)=='function' then
        local ok,_,file=pcall(GetClassInfo,id); token=ok and A.ClassToken(A.Plain(file,'string')) or nil
    end
    return token
end
function A.CurrentRegion()
    if type(GetCurrentRegion)=='function' then
        local ok,id=pcall(GetCurrentRegion); if ok then return A.Plain(id,'number') end
    end
end
function A.Plain(value, kind)
    if type(issecretvalue)=='function' and issecretvalue(value) then return nil end
    if type(value)=='table' and type(canaccesstable)=='function' and not canaccesstable(value) then return nil end
    if kind and type(value)~=kind then return nil end
    return value
end
function A.Trim(s) return type(s)=='string' and s:match('^%s*(.-)%s*$') or '' end
function A.Fold(s)
    return (s:gsub('[A-Z]', function(c) return string.char(c:byte()+32) end))
end
function A.Identity(name, realm)
    name, realm = A.Trim(name), A.Trim(realm)
    if name=='' or #name>120 or #realm>120 or name:find('[%c|]') or realm:find('[%c|]') then return nil end
    return name, realm~='' and realm or nil
end
function A.Key(name, realm)
    name, realm = A.Identity(name, realm)
    if not name then return nil end
    return A.Fold(name) .. '\031' .. (realm and A.Fold(realm) or '')
end
function A.Split(text)
    local name, realm = A.Trim(text):match('^([^%-]+)%-(.+)$')
    return name or A.Trim(text), realm
end
function A.SafeText(text) return (tostring(text or ''):gsub('|','||')) end
function A.Display(e) return e.characterName .. (e.realm and '-' .. e.realm or ' (?)') end
function A.UnitIdentity(unit)
    if type(UnitFullName)~='function' then return nil end
    local ok, name, realm = pcall(UnitFullName, unit)
    if not ok then return nil end
    name, realm = A.Plain(name, 'string'), A.Plain(realm, 'string')
    if not name then return nil end
    return A.Identity(name, realm)
end
