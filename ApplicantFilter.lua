local _, A = ...
local installed,filtering=false,false
local markedRows=setmetatable({},{__mode='k'})
local nameColors=setmetatable({},{__mode='k'})
local hoverIDs=setmetatable({},{__mode='k'})
local hoverInstalled=setmetatable({},{__mode='k'})
function A.ApplicantMatch(id)
    if A.locked or not A.Plain(id,'number') or not C_LFGList
        or type(C_LFGList.GetApplicantInfo)~='function' or type(C_LFGList.GetApplicantMemberInfo)~='function' then return nil end
    local ok,info=pcall(C_LFGList.GetApplicantInfo,id)
    info=ok and A.Plain(info,'table')
    local count=info and A.Plain(info.numMembers,'number')
    if not count or count<1 or count>40 then return nil end
    for member=1,count do
        local read,name=pcall(C_LFGList.GetApplicantMemberInfo,id,member)
        name=read and A.Plain(name,'string')
        local e=name and A.FindAvoidedContact(name)
        if e then return e end
    end
    return nil
end
function A.ShouldHideApplicant(id)
    return not A.locked and A.db.settings.hideApplicants and A.ApplicantMatch(id)~=nil or false
end
local function hover(frame)
    if A.locked or A.db.settings.hideApplicants or (InCombatLockdown and InCombatLockdown()) then return end
    local e=A.ApplicantMatch(hoverIDs[frame])
    if not e then return end
    if not GameTooltip.IsOwned or not GameTooltip:IsOwned(frame) then
        GameTooltip:SetOwner(frame,'ANCHOR_RIGHT'); GameTooltip:SetText(A.L.TITLE)
    end
    GameTooltip:AddLine(string.format(A.L.AVOID_BECAUSE,A.SafeText(e.reason)),1,0.15,0.15,true)
    GameTooltip:Show()
end
local function installHover(frame,id)
    if not hoverInstalled[frame] then
        frame:HookScript('OnEnter',hover)
        frame:HookScript('OnLeave',function(self)
            if not GameTooltip.IsOwned or GameTooltip:IsOwned(self) then GameTooltip:Hide() end
        end)
        hoverInstalled[frame]=true
    end
    hoverIDs[frame]=id
end
function A.MarkApplicant(button,id)
    if A.locked or (InCombatLockdown and InCombatLockdown()) or not button or button:IsProtected() then return end
    local e=not A.db.settings.hideApplicants and A.ApplicantMatch(id)
    hoverIDs[button]=id
    local tint=markedRows[button]
    if e and not tint then
        tint=button:CreateTexture(nil,'BACKGROUND',nil,1)
        tint:SetAllPoints(button); tint:SetColorTexture(1,0,0,0.18); markedRows[button]=tint
    end
    if tint then tint:SetShown(not not e) end
    if e then installHover(button,id) end
    for _,member in ipairs(A.Plain(button.Members,'table') or {}) do
        hoverIDs[member]=id
        if not member:IsProtected() and member.Name then
            local text=member.Name
            local r,g,b,a=text:GetTextColor()
            if A.Plain(r,'number') and A.Plain(g,'number') and A.Plain(b,'number') then
                local ours=r==1 and g==0.15 and b==0.15
                if e then
                    if not ours then nameColors[text]={r,g,b,A.Plain(a,'number') or 1} end
                    text:SetTextColor(1,0.15,0.15)
                    installHover(member,id)
                else
                    if ours and nameColors[text] then text:SetTextColor(unpack(nameColors[text])) end
                    nameColors[text]=nil
                end
            end
        end
    end
end
function A.FilterApplicants(viewer)
    if filtering or A.locked or (InCombatLockdown and InCombatLockdown()) then return end
    local scroll=viewer and viewer.ScrollBox
    if not scroll or scroll:IsProtected() or viewer:IsProtected() or type(scroll.GetDataProvider)~='function'
        or type(scroll.SetDataProvider)~='function' or type(CreateDataProvider)~='function' then return end
    if not A.db.settings.hideApplicants then
        if type(scroll.ForEachFrame)=='function' then scroll:ForEachFrame(function(button) A.MarkApplicant(button,A.Plain(button.applicantID,'number')) end) end
        return
    end
    local provider=scroll:GetDataProvider()
    if not provider or type(provider.Enumerate)~='function' then return end
    local kept,hidden={},0
    for _,data in provider:Enumerate() do
        if not A.Plain(data,'table') or not A.Plain(data.id,'number') then return end
        if A.ShouldHideApplicant(data.id) then hidden=hidden+1 else kept[#kept+1]=data end
    end
    if hidden==0 then
        if scroll.NoApplicants and not scroll.NoApplicants:IsProtected() then scroll.NoApplicants:SetShown(#kept==0) end
        return
    end
    local filtered=CreateDataProvider()
    for _,data in ipairs(kept) do filtered:Insert(data) end
    filtering=true
    local ok=pcall(scroll.SetDataProvider,scroll,filtered,ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition)
    filtering=false
    if ok and scroll.NoApplicants and not scroll.NoApplicants:IsProtected() then scroll.NoApplicants:SetShown(#kept==0) end
end
function A.InstallApplicantFilter()
    if installed or (InCombatLockdown and InCombatLockdown()) or type(hooksecurefunc)~='function'
        or type(LFGListApplicationViewer_UpdateResults)~='function' then return end
    installed=pcall(hooksecurefunc,'LFGListApplicationViewer_UpdateResults',function(viewer)
        local ok=pcall(A.FilterApplicants,viewer)
        A.applicantError=not ok
    end)
    A.applicantHookInstalled=installed
    if installed and type(LFGListApplicationViewer_UpdateApplicant)=='function' then
        pcall(hooksecurefunc,'LFGListApplicationViewer_UpdateApplicant',function(button,id) pcall(A.MarkApplicant,button,id) end)
    end
end
function A.RefreshApplicants()
    if not installed or (InCombatLockdown and InCombatLockdown()) then return end
    local viewer=LFGListFrame and LFGListFrame.ApplicationViewer
    if viewer and viewer:IsShown() and not viewer:IsProtected() then
        if type(LFGListApplicationViewer_UpdateAvailability)=='function' then pcall(LFGListApplicationViewer_UpdateAvailability,viewer) end
        pcall(LFGListApplicationViewer_UpdateResults,viewer)
    end
end
