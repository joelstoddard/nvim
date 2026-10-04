-- Moves the test install's plugins to the lockfile, for tests/bootstrap.lua. The install already holds every
-- committed revision, so the sync runs offline first and goes online only for plugins it could not move.
-- update is vim.pack.update, and off() returns the plugins that are still off the lockfile.
return function(update, off)
	local ok, err = pcall(update, nil, { target = "lockfile", force = true, offline = true })
	local still_off = off()
	if ok and #still_off > 0 then
		ok, err = pcall(update, still_off, { target = "lockfile", force = true })
		still_off = off()
	end
	return ok, err, still_off
end
