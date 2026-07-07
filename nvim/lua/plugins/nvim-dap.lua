return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "mfussenegger/nvim-dap-python",
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    require("dap-python").setup(".venv/bin/python")
    dapui.setup()

    dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

    vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
    vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
    vim.keymap.set("n", "<leader>dn", dap.step_over, { desc = "Next line" })
    vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
    vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step over" })
    vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Step out" })
    vim.keymap.set("n", "<leader>dr", dap.restart, { desc = "Restart" })
    vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })
    vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
  end,
}
