local addonName, A = ...
function A.Say(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99Avoided Players Forever|r: '..A.SafeText(message)) end
end
local events=CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent',function(_,event,name)
    if event=='ADDON_LOADED' and name==addonName then
        local db=A.InitDB(AvoidedPlayersForeverDB)
        if db then AvoidedPlayersForeverDB=db else A.Say(A.L.LOCKED) end
        for _,ev in ipairs({'PLAYER_LOGIN','PLAYER_ENTERING_WORLD','PLAYER_REGEN_ENABLED','IGNORELIST_UPDATE',
            'LFG_LIST_APPLICANT_LIST_UPDATED','LFG_LIST_APPLICANT_UPDATED'}) do
            pcall(events.RegisterEvent,events,ev)
        end
    end
    if not A.db then return end
    if event=='ADDON_LOADED' or event=='PLAYER_LOGIN' or event=='PLAYER_REGEN_ENABLED' or event=='PLAYER_ENTERING_WORLD' then
        A.InstallMenus(); A.InstallSocial(); A.InstallApplicantFilter()
    end
    if event=='PLAYER_ENTERING_WORLD' or event=='PLAYER_REGEN_ENABLED' or event=='IGNORELIST_UPDATE' then A.SyncIgnores() end
    if event=='PLAYER_LOGIN' then A.Say(string.format(A.L.LOADED,'0.2.1')) end
    if event=='LFG_LIST_APPLICANT_LIST_UPDATED' or event=='LFG_LIST_APPLICANT_UPDATED' or event=='PLAYER_REGEN_ENABLED' then
        A.RefreshApplicants()
    end
end)
