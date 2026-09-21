-- Let the Godot editor open scripts in this Neovim.
-- Godot: Editor Settings → Text Editor → External
--   Exec Path:  nvim
--   Exec Flags: --server /tmp/godot.pipe --remote-send "<C-\><C-N>:e {file}<CR>:call cursor({line},{col})<CR>"
local pipe = "/tmp/godot.pipe"

if not vim.fs.root(vim.fn.getcwd(), "project.godot") then
  return
end

-- a socket file left behind by a crashed Neovim would make serverstart() fail
if vim.uv.fs_stat(pipe) then
  local ok, chan = pcall(vim.fn.sockconnect, "pipe", pipe, { rpc = true })
  if ok and chan > 0 then
    vim.fn.chanclose(chan) -- another Neovim already owns it
    return
  end
  os.remove(pipe)
end

pcall(vim.fn.serverstart, pipe)
