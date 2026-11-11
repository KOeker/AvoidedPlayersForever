local _, A = ...
function A.Changed()
    if A.Refresh then A.Refresh() end
    if A.RefreshSocial then A.RefreshSocial() end
    if A.RefreshApplicants then A.RefreshApplicants() end
end
function A.Save(oldKey, name, realm, reason, source, classToken, contactName, regionID)
    if A.locked then return nil, A.L.LOCKED end
    name, realm = A.Identity(name, realm)
    reason = A.Trim(reason)
    if not name or reason=='' or #reason>500 or reason:find('[%z\1-\8\11\12\14-\31]') then return nil, A.L.INVALID end
    local key = A.Key(name, realm)
    if oldKey and oldKey~=key and A.db.entries[key] then return nil, A.L.COLLISION end
    local e = A.db.entries[oldKey or key]
    if e and e.regionID and regionID and e.regionID~=regionID then return nil,A.L.REGION_COLLISION end
    if oldKey and not e then return nil, A.L.NOT_FOUND end
    e = e or {createdAt=time(),source=source=='contextMenu' and 'contextMenu' or 'manual'}
    if oldKey and oldKey~=key then A.db.entries[oldKey]=nil end
    e.key,e.characterName,e.realm,e.reason,e.updatedAt=key,name,realm,reason,time()
    e.classToken=A.ClassToken(classToken) or e.classToken
    if type(contactName)=='string' and A.Identity(contactName) then e.contactName=contactName end
    e.regionID=regionID or e.regionID
    A.db.entries[key]=e
    if A.SyncIgnores then A.SyncIgnores() end
    A.Changed()
    return e
end
function A.Remove(key)
    if A.locked or not A.db.entries[key] then return false end
    if A.ReleaseIgnore then
        local ok,err=A.ReleaseIgnore(A.db.entries[key]); if not ok then return false,err end
    end
    A.db.entries[key]=nil; A.Changed(); return true
end
function A.Match(name, realm)
    if A.locked or not realm or A.Trim(realm)=='' then return nil end
    return A.db.entries[A.Key(name,realm)]
end
function A.PossibleMatch(name)
    if A.locked or type(name)~='string' then return nil end
    for _, e in ipairs(A.List('')) do
        if A.Fold(e.characterName)==A.Fold(name) then return e end
    end
end
function A.List(query)
    local out = {}
    if A.locked then return out end
    query=A.Fold(query or '')
    for _, e in pairs(A.db.entries) do
        if A.Fold(A.Display(e)..' '..e.reason):find(query,1,true) then out[#out+1]=e end
    end
    table.sort(out,function(a,b) return a.key<b.key end)
    return out
end
