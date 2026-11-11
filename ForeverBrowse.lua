local _, A = ...
local browse, source, filtered
local applying, queued
local marks=setmetatable({},{__mode='k'})
local tooltip

local function inCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function readResult(id)
    if not A.Plain(id,'number') or not C_LFGList or type(C_LFGList.GetSearchResultInfo)~='function' then return end
    local ok,info=pcall(C_LFGList.GetSearchResultInfo,id)
    info=ok and A.Plain(info,'table')
    if not info or A.Plain(info.hasSelf,'boolean')~=false then return end
    local name=A.Plain(info.leaderName,'string')
    if A.FullNameKey(name) then return A.FindAvoidedContact(name) end

    local count=A.Plain(info.numMembers,'number')
    local member
    if count==1 and type(C_LFGList.GetSearchResultPlayerInfo)=='function' then
        ok,member=pcall(C_LFGList.GetSearchResultPlayerInfo,id,1)
    elseif count and count>1 and type(C_LFGList.GetSearchResultLeaderInfo)=='function' then
        ok,member=pcall(C_LFGList.GetSearchResultLeaderInfo,id)
    end
    member=ok and A.Plain(member,'table')
    name=member and A.Plain(member.name,'string')
    if A.FullNameKey(name) then return A.FindAvoidedContact(name) end
end

local function borderEdge(row, first, last, horizontal)
    local edge=row:CreateTexture(nil,'OVERLAY',nil,7)
    edge:SetPoint(first,row,first)
    edge:SetPoint(last,row,last)
    if horizontal then edge:SetHeight(2) else edge:SetWidth(2) end
    edge:SetColorTexture(1,0.22,0.22,1)
    return edge
end

local function hideReason(row)
    if tooltip and tooltip:IsOwned(row) then tooltip:Hide() end
end

local function mark(row)
    if A.locked or inCombat() or row:IsProtected() then return end
    local id=A.Plain(row.resultID,'number')
    local entry=id and not A.db.settings.hideApplicants and readResult(id)
    local markState=marks[row]
    if not markState and entry then
        markState={edges={
            borderEdge(row,'TOPLEFT','TOPRIGHT',true),
            borderEdge(row,'BOTTOMLEFT','BOTTOMRIGHT',true),
            borderEdge(row,'TOPLEFT','BOTTOMLEFT',false),
            borderEdge(row,'TOPRIGHT','BOTTOMRIGHT',false),
        }}
        marks[row]=markState
        row:HookScript('OnEnter',function(self)
            local current=marks[self]
            if A.locked or inCombat() or A.db.settings.hideApplicants or not current.entry
                or A.Plain(self.resultID,'number')~=current.id then return end
            if not tooltip then
                tooltip=CreateFrame('GameTooltip','AvoidedPlayersForeverBrowseTooltip',UIParent,'GameTooltipTemplate')
            end
            tooltip:SetOwner(self,'ANCHOR_CURSOR')
            tooltip:AddLine(string.format(A.L.AVOID_BECAUSE,A.SafeText(current.entry.reason)),1,0.3,0.3,true)
            tooltip:Show()
        end)
        row:HookScript('OnLeave',hideReason)
        row:HookScript('OnHide',hideReason)
    end
    if markState then
        if not entry or markState.id~=id then hideReason(row) end
        markState.id,markState.entry=id,entry
        for _,edge in ipairs(markState.edges) do edge:SetShown(not not entry) end
    end
end

local function copyVisible(from,to,previous)
    local removed=false
    for _,node in ipairs(from:GetNodes()) do
        local data=A.Plain(node.data,'table')
        if not data then error('Unreadable Group Finder row') end
        if readResult(data.resultID) then
            removed=true
        else
            local child=to:Insert(data)
            if type(node.IsCollapsed)=='function' and type(child.SetCollapsed)=='function' then
                local old=previous and previous[data] or node
                child:SetCollapsed(old:IsCollapsed())
            end
            if copyVisible(node,child,previous) then removed=true end
        end
    end
    return removed
end

local function rememberNodes(node, nodes)
    for _,child in ipairs(node:GetNodes()) do
        if A.Plain(child.data,'table') then nodes[child.data]=child end
        rememberNodes(child,nodes)
    end
end

local function refresh()
    local scroll=browse.ScrollBox
    if not browse:IsShown() or browse:IsProtected() or scroll:IsProtected() then return end
    local current=scroll:GetDataProvider()
    if current~=filtered then source=current; filtered=nil end
    local target=source
    if source and A.db.settings.hideApplicants and type(source.GetRootNode)=='function' then
        local replacement=CreateTreeDataProvider()
        local previous={}
        if filtered then rememberNodes(filtered:GetRootNode(),previous) end
        if copyVisible(source:GetRootNode(),replacement,previous) then target=replacement end
    end
    if target and target~=current then
        if browse.selectionBehavior then browse.selectionBehavior:ClearSelections() end
        filtered=target~=source and target or nil
        scroll:SetDataProvider(target,ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition)
        if filtered then filtered=scroll:GetDataProvider() end
        if type(browse.UpdateButtonState)=='function' then browse:UpdateButtonState() end
    end
    scroll:ForEachFrame(mark)
end

function A.RefreshBrowse()
    if A.locked or not browse or applying or inCombat() then return end
    applying=true
    pcall(refresh)
    applying=false
end

local function queueRefresh()
    if applying or queued then return end
    queued=true
    C_Timer.After(0,function()
        queued=false
        A.RefreshBrowse()
    end)
end

function A.InstallBrowseFilter()
    if browse or A.locked or inCombat() then return end
    local frame=LFGBrowseFrame
    local scroll=frame and frame.ScrollBox
    if not scroll or frame:IsProtected() or scroll:IsProtected()
        or type(scroll.GetDataProvider)~='function' or type(scroll.SetDataProvider)~='function'
        or type(scroll.ForEachFrame)~='function' or type(CreateTreeDataProvider)~='function'
        or not ScrollUtil or type(ScrollUtil.AddInitializedFrameCallback)~='function'
        or type(hooksecurefunc)~='function' or not C_Timer or type(C_Timer.After)~='function' then return end
    browse=frame
    hooksecurefunc(scroll,'SetDataProvider',queueRefresh)
    ScrollUtil.AddInitializedFrameCallback(scroll,function(_,row) pcall(mark,row) end,browse)
    browse:HookScript('OnShow',queueRefresh)
    queueRefresh()
end
