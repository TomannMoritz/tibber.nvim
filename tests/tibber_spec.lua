local floating = require("tibber.floating")
local tibber_api = require("tibber.tibber_api")


describe("floating window", function()
    it("create new buffer", function()
        local start_state = {
            buf_nr = -1,
            win_id = -1,
            win_open = false
        }
        assert.are.same(start_state, floating.state)


        floating._create_new_floating_buffer()
        start_state.buf_nr = floating.state.buf_nr

        assert.are.same(start_state, floating.state)
        assert.are.same(true, vim.api.nvim_buf_is_valid(floating.state.buf_nr))
    end)
end)


describe("tibber_api", function()
    it("combine days: today", function()
        local energy_data = {
            today = {
                {"foo"},
                {"bar"},
            }
        }

        local result = tibber_api._combine_days(energy_data)
        local solution = {{"foo"}, {"bar"}}
        assert.are.same(solution, result)
    end)

    it("combine days: tomorrow", function()
        local energy_data = {
            tomorrow = {
                {"foo"},
                {"bar"},
            }
        }

        local result = tibber_api._combine_days(energy_data)
        local solution = {{"foo"}, {"bar"}}
        assert.are.same(solution, result)
    end)

    it("combine days: today and tomorrow", function()
        local energy_data = {
            today = {
                {"foo"},
                {"bar"},
            },
            tomorrow = {
                {"0"},
                {"1"},
            }
        }

        local result = tibber_api._combine_days(energy_data)
        local solution = {{"foo"}, {"bar"}, {"0"}, {"1"}}
        assert.are.same(solution, result)
    end)

    it("combine days: empty days", function()
        local energy_data = {
            today = { },
            tomorrow = { }
        }

        local result = tibber_api._combine_days(energy_data)
        local solution = {}
        assert.are.same(solution, result)
    end)
end)
