-- Load mira from a remote repo. Replace the string with your real origin.
-- Examples:
--   "suhailphotos/mira"                -- GitHub shorthand
--   "https://github.com/suhailphotos/mira"
--   "git@github.com:suhailphotos/mira.git"
return {
  {
    "suhailphotos/mira",
    name = "mira",
    branch = "main",   -- or whatever branch you’ll push to
    lazy = false,      -- on rtp immediately so colors/ is discoverable
    -- no config; keep UI completely stock
  },
}
