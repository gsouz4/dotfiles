-- vim-wakatime prompts for an API key on every launch when none is
-- configured. `cond` runs before the plugin loads, so on machines without a
-- key the plugin is skipped entirely -- no wakatime-cli process, no prompt.
-- Once a key lands in ~/.wakatime.cfg (or $WAKATIME_API_KEY), the next nvim
-- start picks it up with no further action.
local function has_api_key()
  if (vim.env.WAKATIME_API_KEY or "") ~= "" then
    return true
  end
  local cfg = (vim.env.WAKATIME_HOME or vim.env.HOME or "") .. "/.wakatime.cfg"
  local f = io.open(cfg)
  if not f then
    return false
  end
  for line in f:lines() do
    if line:match "^%s*api_key%s*=%s*%S" then
      f:close()
      return true
    end
  end
  f:close()
  return false
end

return {
  "wakatime/vim-wakatime",
  lazy = false,
  cond = has_api_key,
}
