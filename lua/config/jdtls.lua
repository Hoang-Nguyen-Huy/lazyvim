local home = os.getenv("HOME")
local workspace_path = home .. "/.local/share/nvim/jdtls-workspace/"
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = workspace_path .. project_name

local status, jdtls = pcall(require, "jdtls")
if not status then
  return
end
local extendedClientCapabilities = jdtls.extendedClientCapabilities

-- Set the command that starts the JDTLS language server jar
local cmd = {
  "java",
  "-Declipse.application=org.eclipse.jdt.ls.core.id1",
  "-Dosgi.bundles.defaultStartLevel=4",
  "-Declipse.product=org.eclipse.jdt.ls.core.product",
  "-Dlog.protocol=true",
  "-Dlog.level=ALL",
  "-Xmx1g",
  "--add-modules=ALL-SYSTEM",
  "--add-opens",
  "java.base/java.util=ALL-UNNAMED",
  "--add-opens",
  "java.base/java.lang=ALL-UNNAMED",
  "-javaagent:" .. home .. "/.local/share/nvim/mason/packages/jdtls/lombok.jar",
  "-jar",
  vim.fn.glob(home .. "/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
  "-configuration",
  home .. "/.local/share/nvim/mason/packages/jdtls/config_mac",
  "-data",
  workspace_dir,
}

-- Configure settings in the JDTLS server
local settings = {
  java = {
    -- Enable method signature help
    signatureHelp = {
      enabled = true,
    },
    extendedClientCapabilities = extendedClientCapabilities,
    -- Enable downloading archives from maven automatically
    maven = {
      downloadSources = true,
    },
    -- Enable downloading archves from eclipse automatically
    eclipse = {
      downloadSources = true,
    },
    -- Enable code lens in the lsp
    referencesCodeLens = {
      enabled = true,
    },
    references = {
      includeDecompiledSources = true,
    },
    -- Enable inlay hints for parameter names
    inlayHints = {
      parameterNames = {
        enabled = "all", -- literals, all, none
      },
    },
    -- Enable code formatting
    format = {
      enabled = true,
      -- Use the Google Style guid for code formatting
      settings = {
        url = vim.fn.stdpath("config") .. "/lang_servers/intellij-java-google-style.xml",
        profile = "GoogleStyle",
      },
    },
    -- Use the fernflower decompiler when using the javap command to decompile byte code back to java code
    contentProvider = {
      preferred = "fernflower",
    },
    -- Setup automatical package import organization on file save
    saveActions = {
      organizeImports = true,
    },
    sources = {
      -- How many classes from a specific package should be imported before automatic imports combine them all into a single import
      organizeImports = {
        starThreshold = 9999,
        staticThreshold = 9999,
      },
    },
    -- Customize completion options
    completion = {
      -- When using an unimported static method, how should the LSP rank possible places to import the static method from
      favoriteStaticMembers = {
        "org.hamcrest.MatcherAssert.assertThat",
        "org.hamcrest.Matchers.*",
        "org.hamcrest.CoreMatchers.*",
        "org.junit.jupiter.api.Assertions.*",
        "java.util.Objects.requireNonNull",
        "java.util.Objects.requireNonNullElse",
        "org.mockito.Mockito.*",
      },
      -- Try not to suggest imports from these packages in the code action window
      filteredTypes = {
        "com.sun.*",
        "io.micrometer.shaded.*",
        "java.awt.*",
        "jdk.*",
        "sun.*",
      },
      -- Set the order in which the language server should organize imports
      importOrder = {
        "java",
        "jakarta",
        "javax",
        "com",
        "org",
      },
    },
    -- How should different pieces of code be generated?
    codeGeneration = {
      -- When generating toString use a json format
      toString = {
        template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
      },
      -- When generating code use code blocks
      useBlocks = true,
    },
  },
}

-- Create a table called init_options to pass the bundles with debug and testing jar, along with the extended client capablies to the start or attach function of JDTLS
local init_options = {
  bundles = {},
  extendedClientCapabilities = extendedClientCapabilities,
}

local function java_keymaps()
  -- Allow yourself to run JdtCompile as a Vim command
  vim.cmd(
    "command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>)"
  )
  -- Allow yourself/register to run JdtUpdateConfig as a Vim command
  vim.cmd("command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()")
  -- Allow yourself/register to run JdtBytecode as a Vim command
  vim.cmd("command! -buffer JdtBytecode lua require('jdtls').javap()")
  -- Allow yourself/register to run JdtShell as a Vim command
  vim.cmd("command! -buffer JdtJshell lua require('jdtls').jshell()")

  -- Set a Vim motion to <Space> + <Shift>J + o to organize imports in normal mode
  vim.keymap.set(
    "n",
    "<leader>Jo",
    "<Cmd> lua require('jdtls').organize_imports()<CR>",
    { desc = "[J]ava [O]rganize Imports" }
  )
  -- Set a Vim motion to <Space> + <Shift>J + v to extract the code under the cursor to a variable
  vim.keymap.set(
    "n",
    "<leader>Jv",
    "<Cmd> lua require('jdtls').extract_variable()<CR>",
    { desc = "[J]ava Extract [V]ariable" }
  )
  -- Set a Vim motion to <Space> + <Shift>J + v to extract the code selected in visual mode to a variable
  vim.keymap.set(
    "v",
    "<leader>Jv",
    "<Esc><Cmd> lua require('jdtls').extract_variable(true)<CR>",
    { desc = "[J]ava Extract [V]ariable" }
  )
  -- Set a Vim motion to <Space> + <Shift>J + <Shift>C to extract the code under the cursor to a static variable
  vim.keymap.set(
    "n",
    "<leader>JC",
    "<Cmd> lua require('jdtls').extract_constant()<CR>",
    { desc = "[J]ava Extract [C]onstant" }
  )
  -- Set a Vim motion to <Space> + <Shift>J + <Shift>C to extract the code selected in visual mode to a static variable
  vim.keymap.set(
    "v",
    "<leader>JC",
    "<Esc><Cmd> lua require('jdtls').extract_constant(true)<CR>",
    { desc = "[J]ava Extract [C]onstant" }
  )
  -- Set a Vim motion to <Space> + <Shift>J + t to run the test method currently under the cursor
  vim.keymap.set(
    "n",
    "<leader>Jt",
    "<Cmd> lua require('jdtls').test_nearest_method()<CR>",
    { desc = "[J]ava [T]est Method" }
  )
  -- Set a Vim motion to <Space> + <Shift>J + t to run the test method that is currently selected in visual mode
  vim.keymap.set(
    "v",
    "<leader>Jt",
    "<Esc><Cmd> lua require('jdtls').test_nearest_method(true)<CR>",
    { desc = "[J]ava [T]est Method" }
  )
  -- Set a Vim motion to <Space> + <Shift>J + <Shift>T to run an entire test suite (class)
  vim.keymap.set("n", "<leader>JT", "<Cmd> lua require('jdtls').test_class()<CR>", { desc = "[J]ava [T]est Class" })
  -- Set a Vim motion to <Space> + <Shift>J + u to update the project configuration
  vim.keymap.set("n", "<leader>Ju", "<Cmd> JdtUpdateConfig<CR>", { desc = "[J]ava [U]pdate Config" })
end

-- Function that will be ran once the language server is attached
local on_attach = function(_, bufnr)
  -- Map the Java specific key mappings of the JDTLS server
  java_keymaps()

  -- Setup the java debug adapter of the JDTLS server
  require("jdtls.dap").setup_dap()

  -- Find the main method(s) of the application so the debug adapter can successfully start up the application
  -- Sometimes this will randomly fail if language server takes to long to startup for the project, if a ClassDefNotFoundException occurs when running
  -- the debug tool, attempt to run the debug tool while in the main class of the application, or restart the neovim instance
  -- Unfortunately I have not found an elegant way to ensure this works 100%
  require("jdtls.dap").setup_dap_main_class_configs()

  -- Refresh the codelens
  -- Code lens enables features such as code reference counts, implementation counts and more.
  vim.lsp.codelens.enable(true)

  -- Setup a function that automatically runs every time a java file is saved to refresh the code lens
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = { "*.java" },
    callback = function()
      local _, _ = pcall(vim.lsp.codelens.enable, true)
    end,
  })
end

local function setup_jdtls()
  -- Create the configuration table for the start or attach function
  local config = {
    cmd = cmd,
    root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),
    settings = settings,
    init_options = init_options,
    on_attach = on_attach,
  }
  -- Start the JDTLS server
  require("jdtls").start_or_attach(config)
end

return {
  setup_jdtls = setup_jdtls,
}
