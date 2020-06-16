if not nyagos then
    print("This is a script for nyagos not lua.exe")
    os.exit()
end

-- hub exists, replace git command
local hubpath=nyagos.which("hub.exe")
if hubpath then
  nyagos.alias.git = "hub.exe"
end

share.git = {}

-- setup local branch listup
local branchlist = function()
  local gitbranches = {}
  local gitbranch_tmp = nyagos.eval('git for-each-ref  --format="%(refname:short)" refs/heads/ 2> nul')
  for line in gitbranch_tmp:gmatch('[^\n]+') do
    table.insert(gitbranches,line)
  end
  return gitbranches
end

--setup current branch string
local currentbranch = function()
  return nyagos.eval('git rev-parse --abbrev-ref HEAD 2> nul')
end

-- subcommands
local gitsubcommands={}

-- keyword
gitsubcommands["bisect"]={"start", "bad", "good", "skip", "reset", "visualize", "replay", "log", "run"}
gitsubcommands["notes"]={"add", "append", "copy", "edit", "list", "prune", "remove", "show"}
gitsubcommands["reflog"]={"show", "delete", "expire"}
gitsubcommands["rerere"]={"clear", "forget", "diff", "remaining", "status", "gc"}
gitsubcommands["stash"]={"save", "list", "show", "apply", "clear", "drop", "pop", "create", "branch"}
gitsubcommands["submodule"]={"add", "status", "init", "deinit", "update", "summary", "foreach", "sync"}
gitsubcommands["svn"]={"init", "fetch", "clone", "rebase", "dcommit", "log", "find-rev", "set-tree", "commit-diff", "info", "create-ignore", "propget", "proplist", "show-ignore", "show-externals", "branch", "tag", "blame", "migrate", "mkdirs", "reset", "gc"}
gitsubcommands["worktree"]={"add", "list", "lock", "prune", "unlock"}

-- branch
gitsubcommands["checkout"]=branchlist
gitsubcommands["reset"]=branchlist
gitsubcommands["merge"]=branchlist
gitsubcommands["rebase"]=branchlist

local gitvar=share.git
gitvar.subcommand=gitsubcommands
gitvar.branch=branchlist
gitvar.currentbranch=currentbranch
share.git=gitvar

if not share.maincmds then
    use "subcomplete.lua"
end

if share.maincmds and share.maincmds["git"] then
    -- git command complementation exists.
    nyagos.complete_for.git = function(args)
        while #args > 2 and args[2]:sub(1,1) == "-" do
            table.remove(args,2)
        end
        if #args == 2 then
            return share.maincmds.git
        end
        local subcmd = table.remove(args,2)
        while #args > 2 and args[2]:sub(1,1) == "-" do
            table.remove(args,2)
        end
        if #args == 2 then
            local t = gitsubcommands[subcmd]
            if type(t) == "function" then
                return t()
            elseif type(t) == "table" then
                return t
            end
        end
    end
end

-- EOF
