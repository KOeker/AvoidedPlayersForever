local _, A = ...
local installed={}
local function menuIdentity(context)
    local unit=A.Plain(context.unit,'string')
    if unit and type(UnitIsPlayer)=='function' and A.Plain(UnitIsPlayer(unit),'boolean') then
        local name,realm=A.UnitIdentity(unit)
        local token
        if type(UnitClass)=='function' then local ok,_,file=pcall(UnitClass,unit); token=ok and A.ClassToken(A.Plain(file,'string')) end
        return name,realm,token
    end
    local accountID=A.Plain(context.bnetIDAccount,'number')
    if accountID then
        if not C_BattleNet or type(C_BattleNet.GetAccountInfoByID)~='function' then return end
        local ok,account=pcall(C_BattleNet.GetAccountInfoByID,accountID)
        account=ok and A.Plain(account,'table')
        local game=account and A.Plain(account.gameAccountInfo,'table')
        if not game or not WOW_PROJECT_ID or A.Plain(game.clientProgram,'string')~=BNET_CLIENT_WOW
            or A.Plain(game.wowProjectID,'number')~=WOW_PROJECT_ID
            or A.Plain(game.isInCurrentRegion,'boolean')~=true then return end
        local name,realm=A.Identity(A.Plain(game.characterName,'string'),A.Plain(game.realmName,'string'))
        return name,realm,A.ClassInfo(game)
    end
    local name,realm=A.Plain(context.name,'string'),A.Plain(context.server,'string')
    if name and realm then return A.Identity(name,realm) end
    local recent=A.Plain(context.recentAllyData,'table')
    local character=recent and A.Plain(recent.characterData,'table')
    if character then
        local name=A.Identity(A.Plain(character.fullName,'string') or A.Plain(character.name,'string'))
        return name,nil,A.ClassInfo(character)
    end
end
function A.ModifyPlayerMenu(_, root, context)
    context=A.Plain(context,'table')
    if A.locked or (InCombatLockdown and InCombatLockdown()) or not context
        or not root or type(root.CreateButton)~='function' then return end
    local name,realm,classToken=menuIdentity(context)
    if not name then return end
    local contactName
    if not A.Plain(context.bnetIDAccount,'number') and UnitPopupSharedUtil and type(UnitPopupSharedUtil.GetFullPlayerName)=='function' then
        local ok,full=pcall(UnitPopupSharedUtil.GetFullPlayerName,context)
        contactName=ok and A.Plain(full,'string')
    end
    contactName=contactName or (realm and name..'-'..realm)
    local key=A.Key(name,realm)
    local entry=A.db.entries[key]
    if entry and entry.regionID and entry.regionID~=A.CurrentRegion() then return end
    root:CreateButton(entry and A.L.REMOVE or A.L.AVOID,function()
        if InCombatLockdown and InCombatLockdown() then A.Say(A.L.COMBAT); return end
        A.Click()
        if entry then
            local ok,err=A.Remove(key); if not ok and err then A.Say(err) end
        else A.OpenReason(name,realm,classToken,contactName,A.CurrentRegion()) end
    end)
end
function A.InstallMenus()
    if A.locked or (InCombatLockdown and InCombatLockdown()) or not Menu
        or type(Menu.ModifyMenu)~='function' or type(Menu.IsMenuProxy)~='function' then return end
    for _,tag in ipairs({'MENU_UNIT_TARGET','MENU_UNIT_PLAYER','MENU_UNIT_PARTY','MENU_UNIT_RAID_PLAYER',
        'MENU_UNIT_FRIEND','MENU_UNIT_FRIEND_OFFLINE','MENU_UNIT_BN_FRIEND','MENU_UNIT_BN_FRIEND_OFFLINE',
        'MENU_UNIT_RECENT_ALLY','MENU_UNIT_RECENT_ALLY_OFFLINE'}) do
        if not installed[tag] then
            local ok=pcall(Menu.ModifyMenu,tag,A.ModifyPlayerMenu)
            if ok then installed[tag]=true end
        end
    end
end
