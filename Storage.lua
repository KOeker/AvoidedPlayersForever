local _, A = ...
function A.InitDB(db)
    A.db, A.locked = nil, true
    if db==nil then db={schemaVersion=2, entries={}, settings={}} end
    if type(db)~='table' or (db.schemaVersion~=nil and db.schemaVersion~=0 and db.schemaVersion~=1 and db.schemaVersion~=2)
        or (db.entries~=nil and type(db.entries)~='table') or (db.settings~=nil and type(db.settings)~='table')
        or (db.ignoreOwned~=nil and type(db.ignoreOwned)~='table') then return nil end
    for _,owned in pairs(db.ignoreOwned or {}) do
        if type(owned)~='table' or type(owned.name)~='string' or not A.Identity(owned.name)
            or (owned.regionID~=nil and type(owned.regionID)~='number')
            or (owned.owner~=nil and type(owned.owner)~='string') then return nil end
    end
    local entries = {}
    for _, e in pairs(db.entries or {}) do
        if type(e)~='table' or type(e.reason)~='string' or #e.reason>500 or A.Trim(e.reason)=='' then return nil end
        local name, realm = A.Identity(e.characterName, e.realm)
        local key = name and A.Key(name, realm)
        if not key or entries[key] then return nil end
        if e.createdAt~=nil and type(e.createdAt)~='number' then return nil end
        if e.updatedAt~=nil and type(e.updatedAt)~='number' then return nil end
        entries[key] = {key=key,characterName=name,realm=realm,reason=e.reason,
            createdAt=e.createdAt or time(),updatedAt=e.updatedAt or e.createdAt or time(),
            source=e.source=='contextMenu' and 'contextMenu' or 'manual'}
        entries[key].classToken=A.ClassToken(e.classToken)
        entries[key].contactName=type(e.contactName)=='string' and A.Identity(e.contactName) and e.contactName or nil
        entries[key].regionID=type(e.regionID)=='number' and e.regionID or nil
    end
    db.entries, db.schemaVersion, db.settings = entries, 2, db.settings or {}
    db.ignoreOwned=db.ignoreOwned or {}
    db.settings.warnGroup=false
    db.settings.warnLFG=false
    if db.settings.hideApplicants==nil then db.settings.hideApplicants=true end
    db.settings.social=nil
    db.settings.hideBlizzardLFG=false
    A.db, A.locked = db, false
    return db
end
