local _, A = ...
local L,key=A.L,'AvoidedPlayersForever'
local host,panel,fallback
local previousIcon,iconWidth,iconHeight
local rows,search,status,counter,page={},nil,nil,nil,1
function A.ResizeSocialIcon()
    if previousIcon then previousIcon:SetSize(iconWidth,iconHeight); previousIcon=nil end
    local tab=host and type(host.GetTabByType)=='function' and host:GetTabByType(key)
    if not tab or not tab.Icon then return end
    previousIcon=tab.Icon
    iconWidth,iconHeight=previousIcon:GetWidth(),previousIcon:GetHeight()
    previousIcon:SetSize(iconWidth*0.9,iconHeight*0.9)
end
function A.RefreshSocial()
    if not panel or not panel:IsShown() then return end
    local width=math.max(250,panel:GetWidth()-36)
    local visible=math.max(0,math.min(12,math.floor((panel:GetHeight()-180)/56)))
    local count=math.max(1,visible)
    local items=A.List(search:GetText())
    local pages=math.max(1,math.ceil(#items/count)); page=math.min(page,pages)
    search:SetWidth(width-12); status:SetWidth(width)
    for _,control in pairs(panel.controls) do
        control:SetChecked(A.db.settings[control.setting])
        control.label:SetWidth(width-30)
    end
    status:SetText(A.locked and L.LOCKED or (#items==0 and L.EMPTY or ''))
    counter:SetText(string.format(L.PAGE,page,pages))
    for i,row in ipairs(rows) do
        local e
        if i<=visible then e=items[(page-1)*count+i] end
        row.entry=e; row:SetShown(e~=nil)
        if e then
            row:SetWidth(width)
            row.name:SetText(A.SafeText(A.Display(e))); row.name:SetWidth(width-86)
            row.reason:SetText(A.SafeText(e.reason:gsub('[\r\n]',' '))); row.reason:SetWidth(width-86)
            local coords=e.classToken and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[e.classToken]
            row.icon:SetTexture(coords and 'Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES' or 'Interface\\Icons\\INV_Misc_QuestionMark')
            if coords then row.icon:SetTexCoord(unpack(coords)) else row.icon:SetTexCoord(0,1,0,1) end
        end
    end
end
local function createPanel(parent)
    panel=CreateFrame('Frame',nil,parent)
    panel:SetPoint('TOPLEFT',parent.BattleNetBar,'BOTTOMLEFT',0,5)
    panel:SetPoint('BOTTOMRIGHT',parent,'BOTTOMRIGHT',-2,2); panel:Hide()
    panel.controls={}
    local function option(setting,label,y)
        local c=CreateFrame('CheckButton',nil,panel,'UICheckButtonTemplate')
        c:SetPoint('TOPLEFT',16,y); c:SetSize(26,26); c.setting=setting
        c.label=A.Label(panel,label,48,y-4,320); c.label:SetHeight(32); c.label:SetJustifyV('TOP')
        c:SetChecked(A.db.settings[setting])
        c:SetScript('OnClick',function(self)
            A.Click(); A.db.settings[setting]=not not self:GetChecked()
            A.RefreshApplicants(); A.RefreshSocial()
        end)
        panel.controls[setting]=c
    end
    option('hideApplicants',L.HIDE_APPLICANTS,-8)
    panel.searchLabel=A.Label(panel,L.SEARCH,18,-64,350)
    search=CreateFrame('EditBox',nil,panel,'InputBoxTemplate')
    search:SetPoint('TOPLEFT',24,-86); search:SetSize(340,26)
    search:SetAutoFocus(false); search:SetMaxBytes(200)
    search:SetScript('OnTextChanged',function() page=1; A.RefreshSocial() end)
    search:SetScript('OnEscapePressed',function() search:ClearFocus() end)
    status=A.Label(panel,'',18,-126,350); status:SetHeight(40); status:SetJustifyV('TOP')
    for i=1,12 do
        local row=CreateFrame('Frame',nil,panel)
        row:SetPoint('TOPLEFT',18,-148-(i-1)*56); row:SetSize(350,48); row:EnableMouse(true); row:Hide()
        row.icon=row:CreateTexture(nil,'ARTWORK'); row.icon:SetSize(32,32); row.icon:SetPoint('LEFT',0,0)
        row.name=A.Label(row,'',44,-4,260); row.name:SetHeight(18)
        row.reason=A.Label(row,'',44,-24,260); row.reason:SetHeight(18); row.reason:SetJustifyV('TOP')
        row.remove=CreateFrame('Button',nil,row,'UIPanelCloseButton')
        row.remove:SetSize(28,28); row.remove:SetPoint('RIGHT',0,0)
        row.remove:SetScript('OnClick',function()
            A.Click()
            if row.entry then local ok,err=A.Remove(row.entry.key); if not ok and err then A.Say(err) end end
        end)
        local function tooltip()
            if not row.entry then return end
            GameTooltip:SetOwner(row,'ANCHOR_RIGHT')
            GameTooltip:SetText(A.SafeText(A.Display(row.entry)))
            GameTooltip:AddLine(A.SafeText(row.entry.reason),1,1,1,true)
            if not row.entry.realm then GameTooltip:AddLine(L.UNKNOWN,1,0.8,0,true) end
            GameTooltip:Show()
        end
        row:SetScript('OnEnter',tooltip); row:SetScript('OnLeave',function() GameTooltip:Hide() end)
        row.remove:SetScript('OnEnter',function()
            GameTooltip:SetOwner(row.remove,'ANCHOR_RIGHT'); GameTooltip:SetText(L.REMOVE); GameTooltip:Show()
        end)
        row.remove:SetScript('OnLeave',function() GameTooltip:Hide() end)
        rows[i]=row
    end
    local prev=A.Button(panel,L.PREV,0,0,100,function() page=math.max(1,page-1); A.RefreshSocial() end)
    prev:ClearAllPoints(); prev:SetPoint('BOTTOMLEFT',18,10)
    local next=A.Button(panel,L.NEXT,0,0,100,function() page=page+1; A.RefreshSocial() end)
    next:ClearAllPoints(); next:SetPoint('BOTTOMRIGHT',-18,10)
    counter=A.Label(panel,'',0,0,120); counter:ClearAllPoints(); counter:SetPoint('BOTTOM',0,16)
    panel:SetScript('OnShow',A.RefreshSocial); panel:SetScript('OnSizeChanged',A.RefreshSocial)
    return panel
end
function A.OpenSocial()
    if not host or A.locked then return false end
    if ShowUIPanel then ShowUIPanel(host) else host:Show() end
    host:SelectTab(key)
    return true
end
function A.InstallSocial()
    if A.locked or (InCombatLockdown and InCombatLockdown()) then return end
    local parent=SocialUIFrame
    if parent and not parent:IsProtected() and parent.BattleNetBar and type(parent.tabDefinitions)=='table'
        and type(parent.ResetTabs)=='function' and type(parent.SelectTab)=='function'
        and type(parent.GetSelectedTab)=='function' and type(parent.SelectBestDefaultTab)=='function' then
        if host~=parent then
            local order=0
            for _,data in pairs(parent.tabDefinitions) do order=math.max(order,data.tabOrder or 0) end
            parent.tabDefinitions[key]={tabType=key,tabOrder=order+1,tabName=L.TITLE,
                iconAtlas='common-icon-redx',contentFrame=createPanel(parent),
                IsAvailable=function() return not A.locked end}
            host=parent
            if type(hooksecurefunc)=='function' then
                hooksecurefunc(parent,'RefreshTabs',A.ResizeSocialIcon)
                if type(parent.RefreshVisuals)=='function' then hooksecurefunc(parent,'RefreshVisuals',A.ResizeSocialIcon) end
            end
            local selected=parent:GetSelectedTab(); parent:ResetTabs()
            if selected then parent:SelectTab(selected)
            else parent:SelectBestDefaultTab() end
            A.ResizeSocialIcon()
        end
        if fallback then fallback:Hide() end
        return
    end
    local legacy=FriendsFrame
    if legacy and not legacy:IsProtected() then
        if not fallback then
            fallback=A.Button(legacy,L.TITLE,0,0,190,A.Open)
            fallback:ClearAllPoints(); fallback:SetPoint('TOPLEFT',legacy,'TOPRIGHT',4,-160)
        end
        fallback:Show()
    end
end
