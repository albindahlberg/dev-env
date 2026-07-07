return {
    "ray-x/lsp_signature.nvim",
    event = "InsertEnter",
    opts = {
        -- cfg options
    },
    config = function()
        require("lsp_signature").setup()
    end
}
