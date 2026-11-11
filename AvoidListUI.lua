local _, A = ...
local L=A.L
local dialog
function A.Click()
    local sound=SOUNDKIT and (SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION)
    if PlaySound and sound then PlaySound(sound) end
end
function A.Label(parent,text,x,y,width)
    local f=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    f:SetPoint('TOPLEFT',x,y); f:SetWidth(width); f:SetJustifyH('LEFT'); f:SetText(text)
    return f
end
function A.Button(parent,text,x,y,width,fn)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
    b:SetPoint('TOPLEFT',x,y); b:SetSize(width,26); b:SetText(text)
    b:SetScript('OnClick',function(self) A.Click(); fn(self) end)
    return b
end
local function frame(name,title,w,h)
    local f=CreateFrame('Frame',name,UIParent,'BasicFrameTemplateWithInset')
    f:SetSize(w,h); f:SetPoint('CENTER'); f.TitleText:SetText(title)
    f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag('LeftButton')
    f:SetScript('OnDragStart',f.StartMoving); f:SetScript('OnDragStop',f.StopMovingOrSizing)
    f:SetScale(math.min(1,(UIParent:GetHeight()-40)/h,(UIParent:GetWidth()-40)/w))
    UISpecialFrames[#UISpecialFrames+1]=name
    return f
end
function A.OpenReason(name,realm,classToken,contactName,regionID,source,onSaved)
    if A.locked then A.Say(L.LOCKED); return end
    name,realm=A.Identity(name,realm)
    if not name then return end
    if not dialog then
        dialog=frame('AvoidedPlayersForeverReason',L.AVOID,510,340)
        dialog:SetFrameStrata('DIALOG')
        dialog.identity=A.Label(dialog,'',24,-46,460)
        A.Label(dialog,L.REASON,24,-82,460)
        dialog.reason=CreateFrame('EditBox',nil,dialog,'InputBoxTemplate')
        dialog.reason:SetPoint('TOPLEFT',28,-112); dialog.reason:SetSize(450,90)
        dialog.reason:SetAutoFocus(false); dialog.reason:SetMultiLine(true); dialog.reason:SetMaxBytes(500)
        dialog.reason:SetFontObject(ChatFontNormal); dialog.reason:SetTextInsets(6,6,4,4)
        dialog.reason:SetScript('OnEscapePressed',function() dialog:Hide() end)
        dialog.error=A.Label(dialog,'',24,-220,460); dialog.error:SetTextColor(1,0.35,0.25)
        A.Button(dialog,L.SAVE,24,-294,210,function()
            local e,err=A.Save(nil,dialog.characterName,dialog.characterRealm,dialog.reason:GetText(),dialog.source,dialog.classToken,dialog.contactName,dialog.regionID)
            if e then
                local callback=dialog.onSaved
                dialog:Hide()
                if callback then callback() end
            else
                dialog.error:SetText(err)
            end
        end)
        A.Button(dialog,L.CANCEL,266,-294,210,function() dialog:Hide() end)
    end
    dialog.source,dialog.onSaved=source or 'contextMenu',onSaved
    dialog.characterName,dialog.characterRealm=name,realm
    dialog.classToken,dialog.contactName,dialog.regionID=classToken,contactName,regionID
    dialog.identity:SetText(A.SafeText(A.Display({characterName=name,realm=realm})))
    dialog.reason:SetText(''); dialog.error:SetText(''); dialog:Show(); dialog.reason:SetFocus()
end
function A.Open()
    if A.locked then A.Say(L.LOCKED); return end
    if not A.OpenSocial or not A.OpenSocial() then A.Say(L.SOCIAL_UNAVAILABLE) end
end
