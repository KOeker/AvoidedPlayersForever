local addonName, A = ...
function A.Say(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99Avoided Players Forever|r: '..A.SafeText(message)) end
end
local function declineAvoidedInvite(name,guid)
    if A.locked or (InCombatLockdown and InCombatLockdown()) or type(DeclineGroup)~='function' then return end
    name=A.Plain(name,'string')
    if not name then return end
    if not A.FullNameKey(name) and A.Plain(guid,'string') and type(GetPlayerInfoByGUID)=='function' then
        local ok,_,_,_,_,_,character,realm=pcall(GetPlayerInfoByGUID,guid)
        character=ok and A.Plain(character,'string')
        realm=ok and A.Plain(realm,'string')
        if character and realm and realm~='' and A.Fold(name)==A.Fold(character) then
            name=character..'-'..realm
        end
    end
    if A.FullNameKey(name) and A.FindAvoidedContact(name) then pcall(DeclineGroup) end
end
local events=CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent',function(_,event,name,...)
    if event=='ADDON_LOADED' and name==addonName then
        local db=A.InitDB(AvoidedPlayersForeverDB)
        if db then AvoidedPlayersForeverDB=db else A.Say(A.L.LOCKED) end
        for _,ev in ipairs({'PLAYER_LOGIN','PLAYER_ENTERING_WORLD','PLAYER_REGEN_ENABLED','IGNORELIST_UPDATE',
            'LFG_LIST_APPLICANT_LIST_UPDATED','LFG_LIST_APPLICANT_UPDATED','PARTY_INVITE_REQUEST'}) do
            pcall(events.RegisterEvent,events,ev)
        end
    end
    if not A.db then return end
    if event=='ADDON_LOADED' or event=='PLAYER_LOGIN' or event=='PLAYER_REGEN_ENABLED' or event=='PLAYER_ENTERING_WORLD' then
        A.InstallMenus(); A.InstallSocial(); A.InstallApplicantFilter(); A.InstallBrowseFilter()
    end
    if event=='PARTY_INVITE_REQUEST' then declineAvoidedInvite(name,select(7,...)) end
    if event=='PLAYER_REGEN_ENABLED' then A.RefreshBrowse() end
    if event=='PLAYER_ENTERING_WORLD' or event=='PLAYER_REGEN_ENABLED' or event=='IGNORELIST_UPDATE' then A.SyncIgnores() end
    if event=='PLAYER_LOGIN' then A.Say(string.format(A.L.LOADED,'0.2.2')) end
    if event=='LFG_LIST_APPLICANT_LIST_UPDATED' or event=='LFG_LIST_APPLICANT_UPDATED' or event=='PLAYER_REGEN_ENABLED' then
        A.RefreshApplicants()
    end
end)
