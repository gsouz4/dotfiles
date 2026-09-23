-- ===================================================================
-- Claude Code - AI pair programming dentro do Neovim
-- ===================================================================
-- Implementa o mesmo protocolo WebSocket/MCP das extensões oficiais de VSCode
-- e JetBrains: o CLI enxerga o Neovim como uma IDE de verdade, então sabe qual
-- buffer está ativo, recebe a seleção visual como contexto e propõe edições
-- como diff nativo em vez de escrever no arquivo pelas suas costas.
-- See: https://github.com/coder/claudecode.nvim
--
-- Usage:
--  - ;ic     - Toggle do terminal do Claude (esconde/mostra no layout atual)
--  - ;iw     - Alterna o layout: split à direita <-> janela flutuante (modal)
--  - ;if     - Foca o terminal (ou esconde, se já estiver focado)
--  - ;ir     - Retoma uma sessão anterior (`claude --resume`)
--  - ;iC     - Continua a última sessão (`claude --continue`)
--  - ;im     - Escolhe o modelo da sessão
--  - ;ib     - Adiciona o buffer atual ao contexto
--  - ;is     - (visual) envia a seleção / (file tree) adiciona o arquivo
--  - ;ia/;id - Aceita / rejeita o diff proposto
--  - <C-.>   - Troca o foco editor <-> Claude (split fica à vista; float esconde)
--
-- Esconder nunca mata o processo: o buffer e o `claude` seguem vivos, então ao
-- reabrir (em qualquer layout) a conversa está onde parou.
--
-- O prefixo `a` do upstream é do harpoon (;a = add file), então aqui é `i`.
--
-- O terminal precisa nascer daqui: o plugin injeta CLAUDE_CODE_SSE_PORT no env
-- do job, e é assim que o `claude` acha este Neovim. Um `claude` aberto em
-- outra aba do terminal não conecta nesta instância.

-- Geometria dos dois layouts. O split é o que o plugin cria por padrão
-- (`split_side`/`split_width_percentage` lá embaixo); o float é o "modal".
local layouts = {
  split = { position = 'right', width = 0.35, height = 0, border = 'none' },
  float = { position = 'float', width = 0.85, height = 0.85, border = 'rounded' },
}

-- A instância Snacks que roda o `claude`. O plugin só expõe o bufnr, então a
-- instância vem da lista do próprio Snacks.
local function claude_term()
  local buf = require('claudecode.terminal').get_active_terminal_bufnr()
  if not buf then
    return nil
  end
  for _, term in ipairs(Snacks.terminal.list()) do
    if term.buf == buf then
      return term
    end
  end
end

-- O plugin não troca de layout em runtime: `snacks_win_opts` é lido uma vez,
-- na criação. Então a troca é feita direto na janela do Snacks: reescreve a
-- geometria em `term.opts`, fecha a janela atual (o buffer e o job ficam) e
-- manda o Snacks abrir de novo. Com `opts.position` atualizado, o resize do
-- editor e o hide/show do plugin passam a respeitar o layout novo.
local function toggle_layout()
  local term = claude_term()
  if not term then
    -- Nada rodando ainda: sobe no split padrão e já converte pra float.
    require('claudecode.terminal').open()
    term = claude_term()
    if not term then
      return
    end
  end

  local target = term.opts.position == 'float' and 'split' or 'float'
  term.opts = vim.tbl_extend('force', term.opts, layouts[target])

  local old = term.win
  term.win = nil
  if old and vim.api.nvim_win_is_valid(old) then
    -- pcall: se for a última janela (E444), o Snacks só reaproveita.
    pcall(vim.api.nvim_win_close, old, false)
  end

  -- Chama o `show` da classe, não o da instância: o plugin sobrescreve
  -- `term:show()` com um caminho que sempre recria como split.
  Snacks.win.show(term)
  if term.win and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_set_current_win(term.win)
    vim.cmd 'startinsert'
  end
end

return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' },

  -- Sem `cmd` o plugin só carrega ao apertar um keymap, e aí os comandos
  -- :ClaudeCode* ainda não existem num Neovim recém-aberto.
  cmd = {
    'ClaudeCode',
    'ClaudeCodeFocus',
    'ClaudeCodeSelectModel',
    'ClaudeCodeAdd',
    'ClaudeCodeSend',
    'ClaudeCodeTreeAdd',
    'ClaudeCodeStatus',
    'ClaudeCodeStart',
    'ClaudeCodeStop',
    'ClaudeCodeOpen',
    'ClaudeCodeClose',
    'ClaudeCodeDiffAccept',
    'ClaudeCodeDiffDeny',
    'ClaudeCodeCloseAllDiffs',
  },

  keys = {
    { '<leader>ic', '<cmd>ClaudeCode<cr>', desc = 'Claude toggle' },
    { '<leader>iw', toggle_layout, desc = 'Claude alternar split/[w]indow flutuante' },
    { '<leader>if', '<cmd>ClaudeCodeFocus<cr>', desc = 'Claude [f]ocus' },
    { '<leader>ir', '<cmd>ClaudeCode --resume<cr>', desc = 'Claude [r]esume sessão' },
    { '<leader>iC', '<cmd>ClaudeCode --continue<cr>', desc = 'Claude [C]ontinue última sessão' },
    { '<leader>im', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Claude escolher [m]odelo' },
    { '<leader>ib', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Claude adicionar [b]uffer atual' },
    { '<leader>is', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Claude enviar [s]eleção' },

    -- Mesmo prefixo, significado equivalente dentro de um explorador de arquivos.
    {
      '<leader>is',
      '<cmd>ClaudeCodeTreeAdd<cr>',
      desc = 'Claude adicionar arquivo',
      ft = { 'neo-tree', 'oil', 'minifiles', 'netrw', 'snacks_picker_list' },
    },

    -- Revisão das edições propostas
    { '<leader>ia', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Claude [a]ceitar diff' },
    { '<leader>id', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Claude rejeitar ([d]eny) diff' },

    -- Troca de foco pura: `ClaudeCodeOpen` foca sem esconder se já estiver
    -- focado (diferente do `ClaudeCodeFocus`, que é toggle). O caminho de volta
    -- é o mapa em modo `t` lá embaixo, então `<C-.>` vai e volta.
    --
    -- É `.` e não `,` porque `ctrl+,` é default do Ghostty (`open_config`) e
    -- nunca chega no nvim. `ctrl+.` não está na lista de binds dele.
    -- Nenhum dos dois existe em ASCII: dependem de CSI-u, que funciona aqui
    -- porque o Ghostty fala kitty keyboard e o tmux está com `extended-keys on`.
    { '<C-.>', '<cmd>ClaudeCodeOpen<cr>', mode = { 'n', 'x' }, desc = 'Claude focar terminal' },
  },

  opts = {
    terminal = {
      -- `auto` escolheria snacks de qualquer forma (já é dependência e carrega
      -- com lazy = false), mas fixar evita cair no terminal nativo em silêncio.
      provider = 'snacks',
      split_side = 'right',
      split_width_percentage = 0.35,
      auto_close = true,

      -- Repassado pro snacks, então o mapa é buffer-local: só vale dentro do
      -- terminal do Claude, não em todo `:terminal` do editor.
      snacks_win_opts = {
        keys = {
          claude_back_to_editor = {
            '<C-.>',
            function(self)
              -- No float, "voltar pro editor" deixaria o modal cobrindo o
              -- código, então ali ele esconde (o processo segue vivo) e o
              -- `<C-.>` do modo normal traz de volta.
              if self:is_floating() then
                self:hide()
                return
              end
              -- No split, sai do modo terminal e volta pra janela anterior. O
              -- split continua aberto e o Claude segue rodando à vista -- o
              -- que esconde é o `;ic`.
              vim.cmd 'stopinsert'
              vim.schedule(function()
                vim.cmd 'wincmd p'
              end)
            end,
            mode = 't',
            desc = 'Voltar pro editor (split) / esconder (float)',
          },
        },
      },
    },

    diff_opts = {
      -- Diff lado a lado, na aba atual: o buffer original continua à vista.
      layout = 'vertical',
      open_in_new_tab = false,
    },
  },
}
