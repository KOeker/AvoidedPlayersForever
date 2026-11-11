local _, A = ...
local syncing=false
local addAttempts,removeAttempts={},{}
function A.ContactName(e)
    if e.regionID and e.regionID~=A.CurrentRegion() then return nil end
    return e.contactName or (e.realm and e.characterName..'-'..e.realm)
end
local function playerKey()
    local name,realm=A.UnitIdentity('player')
    return name and A.Key(name,realm)
end
local function ownerKey(name) return tostring(A.CurrentRegion() or 0)..'\031'..(playerKey() or '')..'\031'..A.Fold(name) end
local function ignored(name)
    if not C_FriendList or type(C_FriendList.IsOnIgnoredList)~='function' then return nil end
    local ok,result=pcall(C_FriendList.IsOnIgnoredList,name)
    if ok then return A.Plain(result,'boolean') end
end
function A.IgnoreStatus(e)
    local name=A.ContactName(e)
    if not name then return 'unknown' end
    local state=ignored(name)
    return state==true and 'active' or (state==false and 'pending' or 'unavailable')
end
function A.FindAvoidedContact(name)
    if A.locked or not A.Plain(name,'string') then return nil end
    local folded,key=A.Fold(name),A.FullNameKey(name)
    for _,e in pairs(A.db.entries) do
        local contact=A.ContactName(e)
        if contact and A.Fold(contact)==folded then return e end
        if key and (not e.regionID or e.regionID==A.CurrentRegion()) then
            local fullName=e.realm and (e.characterName..'-'..e.realm) or e.characterName
            if A.FullNameKey(fullName)==key or A.FullNameKey(contact)==key then return e end
        end
    end
    return nil
end
function A.IsAvoidedContact(name) return A.FindAvoidedContact(name)~=nil end
local function syncIgnore(e, owner, region)
    local name=A.ContactName(e)
    if not name then return end
    local key=ownerKey(name)
    if addAttempts[key] or ignored(name)~=false then return end
    addAttempts[key]=true
    local ok,added=pcall(C_FriendList.AddIgnore,name)
    if ok and A.Plain(added,'boolean')==true then
        A.db.ignoreOwned[key]={name=name,regionID=region,owner=owner}
    end
end
function A.SyncIgnores(entry)
    if A.locked or syncing or (InCombatLockdown and InCombatLockdown()) then return end
    local owner=playerKey()
    if not C_FriendList or type(C_FriendList.AddIgnore)~='function' or not owner then return end
    local region=A.CurrentRegion()
    syncing=true
    if entry then
        syncIgnore(entry,owner,region)
    else
        for _,e in pairs(A.db.entries) do syncIgnore(e,owner,region) end
        for key,owned in pairs(A.db.ignoreOwned) do
            if owned.regionID==region and owned.owner==owner and not A.IsAvoidedContact(owned.name) then
                local state=ignored(owned.name)
                if state==false then
                    A.db.ignoreOwned[key]=nil
                elseif state==true and not removeAttempts[key] and type(C_FriendList.DelIgnore)=='function' then
                    removeAttempts[key]=true
                    local ok,removed=pcall(C_FriendList.DelIgnore,owned.name)
                    if ok and A.Plain(removed,'boolean')==true then A.db.ignoreOwned[key]=nil end
                end
            end
        end
    end
    syncing=false
end
function A.ReleaseIgnore(e)
    local name=A.ContactName(e)
    if not name then return true end
    local key=ownerKey(name)
    if not A.db.ignoreOwned[key] then addAttempts[key]=nil; return true end
    for otherKey,other in pairs(A.db.entries) do
        if otherKey~=e.key and A.ContactName(other)==name then return true end
    end
    if ignored(name)==false then A.db.ignoreOwned[key]=nil; addAttempts[key]=nil; return true end
    if not C_FriendList or type(C_FriendList.DelIgnore)~='function' then return false,A.L.IGNORE_RELEASE_FAILED end
    local wasSyncing=syncing
    syncing=true
    local ok,removed=pcall(C_FriendList.DelIgnore,name)
    syncing=wasSyncing
    if not ok or A.Plain(removed,'boolean')~=true then return false,A.L.IGNORE_RELEASE_FAILED end
    A.db.ignoreOwned[key]=nil
    addAttempts[key],removeAttempts[key]=nil,nil
    return true
end
function A.BlockingStatus()
    if not C_FriendList or type(C_FriendList.IsOnIgnoredList)~='function' then return A.L.IGNORE_UNAVAILABLE..'\n'..A.L.APPLICANT_LIMIT end
    local active,total=0,0
    for _,e in pairs(A.db.entries) do total=total+1; if A.IgnoreStatus(e)=='active' then active=active+1 end end
    return string.format(A.L.IGNORE_STATUS,active,total)..'\n'..A.L.APPLICANT_LIMIT
end
