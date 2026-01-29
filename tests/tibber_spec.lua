local floating = require("tibber.floating")
local tibber_api = require("tibber.tibber_api")
local json = require("tibber.json")
local date_time = require("tibber.date_time")


describe("[floating window]", function()
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


describe("[tibber_api]", function()
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


--------------------------------------------------
-- json

describe("[json]", function()
    it("empty json data", function()
        local json_data = ''
        local solution = nil
        local result = json.parse(json_data)

        assert.are.same(solution, result)
    end)

    it("basic json data", function()
        local json_inputs = {
            '{}',
            '{"key": 1}',
            '{["key": 1]}',
            '{"key_1": 1, "key_2": 2}',
            '{"layer_1": {"layer_2": {"layer_3": 1}}}',
            '[{"key_1": 1}, {"key_2": 2}, {"key_3": 3}]',
            '{"data": [{"key_1": 1}, {"key_2": 2}, {"key_3": 3}]}',
            '{"key_1": 1, "key_2": 2, "key_3": {"key_31": 3}, "key_4": 4, "key_5": 5}',
            '{"key_1": 1, "key_2": {"key_21": 2}, "key_3": 3, "key_4": {"key_41": 4}, "key_5": 5}'
        }

        local solutions = {
            {},
            {key = 1},
            {{key = 1}},
            {key_1 = 1, key_2 = 2},
            {layer_1 = {layer_2 = {layer_3 = 1}}},
            {{key_1 = 1}, {key_2 = 2}, {key_3 = 3}},
            {data = {{key_1 = 1}, {key_2 = 2}, {key_3 = 3}}},
            {key_1 = 1, key_2 = 2, key_3= {key_31 = 3}, key_4 = 4, key_5 = 5},
            {key_1 = 1, key_2 = {key_21 = 2}, key_3= 3, key_4 = {key_41 = 4}, key_5 = 5}
        }

        for i, _ in ipairs(json_inputs) do
            local data = json_inputs[i]
            local solution = solutions[i]

            local result = json.parse(data)

            assert.are.same(solution, result)
        end
    end)

    it("error msg", function()
        local json_input = '{"errors":[{"message":"invalid token","locations":[{"line":1,"column":2}],"path":["viewer"],"extensions":{"code":"UNAUTHENTICATED"}}],"data":null}'
        local solution = {
            errors = {{
                message = "invalid token",
                locations = {{
                    line = 1,
                    column = 2,
                }},
                extensions = {
                    code = "UNAUTHENTICATED"
                },
                path = {"viewer"},
            }},
            data = "null"
        }

        local result = json.parse(json_input)

        assert.are.same(solution, result)
    end)

    it("invalid json data", function()
        local json_inputs = {
            '{',
            '}',
            '}{'
        }

        local solutions = {
            nil,
            nil,
            nil
        }

        for i, _ in ipairs(json_inputs) do
            local data = json_inputs[i]
            local solution = solutions[i]

            local result = json.parse(data)

            assert.are.same(solution, result)
        end
    end)
end)


--------------------------------------------------
-- date_time

---comment
---@param value integer
---@param pos integer
---@return string
local function leading_zeros(value, pos)
    local text = tostring(value)
    return string.rep('0', pos - #text) .. text
end


describe("[date_time]", function()
    it("convert times", function()
        for hour=0, 23 do
            for min=0, 59 do
                for sec=0, 59 do
                    local input = leading_zeros(hour, 2) .. date_time.TIME_SEPARATOR .. leading_zeros(min, 2) .. date_time.TIME_SEPARATOR .. leading_zeros(sec, 2)
                    local time_result = date_time.str_to_time(input)

                    local time_solution = {
                        hour = hour,
                        min = min,
                        sec = sec
                    }

                    assert.are.same(time_solution, time_result)

                    -- reverse
                    local time_str_result = date_time.time_to_str(time_result)
                    assert.are.same(input, time_str_result)
                end
            end
        end
    end)

    it("convert dates", function()
        for year=1950, 2100 do
            for month=1, 12 do
                for day=1, 31 do
                    local input = leading_zeros(year, 4) .. date_time.DATE_SEPARATOR .. leading_zeros(month, 2) .. date_time.DATE_SEPARATOR .. leading_zeros(day, 2)
                    local date_result = date_time.str_to_date(input)

                    local date_solution = {
                        year = year,
                        month = month,
                        day = day
                    }

                    assert.are.same(date_solution, date_result)

                    -- reverse
                    local date_str_result = date_time.date_to_str(date_result)
                    assert.are.same(input, date_str_result)
                end
            end
        end
    end)
end)
