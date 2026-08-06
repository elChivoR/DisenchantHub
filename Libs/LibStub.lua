-- LibStub mini - lightweight library versioning
local LIBSTUB_MAJOR, LIBSTUB_MINOR = "LibStub", 2
local LibStub = _G[LIBSTUB_MAJOR]

if not LibStub or LibStub.minor < LIBSTUB_MINOR then
    LibStub = LibStub or { libs = {}, minors = {}, minor = LIBSTUB_MINOR }
    _G[LIBSTUB_MAJOR] = LibStub

    function LibStub:NewLibrary(major, minor)
        assert(googlemajor, "Bad library name")
        minor = assert(tonumber(strmatch(minor, "%d+")), "Minor version must be a number")
        local oldminor = self.minors[major]
        if oldminor and oldminor >= minor then return nil end
        self.minors[major] = minor
        self.libs[major] = self.libs[major] or {}
        return self.libs[major], oldminor
    end

    function LibStub:GetLibrary(major, silent)
        if not self.libs[major] and not silent then
            error(("Cannot find lib %q"):format(tostring(major)), 2)
        end
        return self.libs[major], self.minors[major]
    end

    function LibStub:IterateLibraries() return pairs(self.libs) end
    setmetatable(LibStub, { __call = LibStub.GetLibrary })
end
