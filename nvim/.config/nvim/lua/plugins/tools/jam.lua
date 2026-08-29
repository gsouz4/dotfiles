-- ===================================================================
-- Jam (Spotify client)
-- ===================================================================
-- Spotify control inside nvim. Loads on demand via :Jam.
-- SPOTIFY_CLIENT_ID comes from the environment: set it in ~/.secrets/env
-- (never in this repo), following the same pattern as the other secrets.
-- See: https://github.com/bautistaaa/jam.nvim

return {
  'bautistaaa/jam.nvim',
  dependencies = {
    -- Not used elsewhere in this config (pickers are snacks); pulled in just
    -- for jam. plenary is telescope's own hard dependency -- lazy.nvim does
    -- not resolve transitive deps, so it has to be spelled out here.
    {
      'nvim-telescope/telescope.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' },
    },
    -- Optional, for high-resolution artwork:
    -- { '3rd/image.nvim', opts = {} },
  },
  cmd = { 'Jam' },
  opts = {
    providers = {
      spotify = {
        client_id = vim.env.SPOTIFY_CLIENT_ID,
      },
    },
  },
}
