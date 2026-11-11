local _, A = ...
function A.Locale(locale)
    return setmetatable({}, {__index=function(_, key)
        return (A.locales[locale] and A.locales[locale][key]) or A.locales.enUS[key] or key
    end})
end
A.L = A.Locale(type(GetLocale)=='function' and GetLocale() or 'enUS')
