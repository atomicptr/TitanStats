-- Titan Stats

local init = HUDStatsScreen.init
local show = HUDStatsScreen.show

function HUDStatsScreen:init()
    init(self)

    self.right_panel = self._full_hud_panel:child("right_panel")
    self.day_wrapper_panel = self.right_panel:child("day_wrapper_panel")
    self:clean_up()

    -- pro job? make title red
    if managers.job:is_current_job_professional() then
        self.day_wrapper_panel:child("day_title"):set_color(Color.red)
    end

    -- create new text elements

    -- difficulty
    local paygrade_title = self:add_text_entry("paygrade_title", managers.localization:to_upper_text("menu_lobby_difficulty_title"))
    paygrade_title:set_top(math.round(self.day_wrapper_panel:child("day_title"):bottom()))

    if managers.job:current_job_data() then
        local job_stars = managers.job:current_job_stars()
        local job_and_difficulty_stars = managers.job:current_job_and_difficulty_stars()
        local difficulty_stars = managers.job:current_difficulty_stars()
        local difficulty = tweak_data.difficulties[difficulty_stars + 2] or 1
        local difficulty_string_id = tweak_data.difficulty_name_ids[difficulty]

        local risk_text = self:add_text_entry("risk_text",
            managers.localization:to_upper_text(difficulty_string_id))

        risk_text:set_top(paygrade_title:top())
        risk_text:set_left(paygrade_title:right() + 8)

        if difficulty_stars > 0 then
            risk_text:set_color(tweak_data.screen_colors.risk)
        end
    end

    local day_payout_title, day_payout_text = self:add_text_pair("day_payout", paygrade_title, "TOTAL PAYOUT:", "...")
    local spending_cash_title, spending_cash_text = self:add_text_pair("spending_cash", day_payout_title, "SPENDING CASH PAYOUT:", "...")
    local offshore_payout_title, offshore_payout_text = self:add_text_pair("offshore_payout", spending_cash_title, "OFFSHORE PAYOUT:", "...")
    local cleaner_costs_title, cleaner_costs_text = self:add_text_pair("cleaner_costs", offshore_payout_title, "CLEANER COSTS:", "...")

    local cash_balance_title, cash_balance_text = self:add_text_pair("cash_balance", nil, "CASH BALANCE:", "...")
    cash_balance_title:set_top(cleaner_costs_title:bottom() + 20)
    cash_balance_text:set_top(cash_balance_title:top())
    cash_balance_text:set_left(cash_balance_title:right() + 8)
    local offshore_balance_title, offshore_balance_text = self:add_text_pair("offshore_balance", cash_balance_title, "OFFSHORE BALANCE:", "...")

end

function HUDStatsScreen:show()
    show(self)

    self.right_panel = self._full_hud_panel:child("right_panel")

    if not self.right_panel then
        return
    end

	self.day_wrapper_panel = self.right_panel:child("day_wrapper_panel")

    if not self.day_wrapper_panel then
        return
    end

    self:clean_up()

    self:update_text("day_payout_text", self:day_payout_string())
    self:update_text("spending_cash_text", self:spending_cash_string())
    self:update_text("offshore_payout_text", self:offshore_payout_string())
    self:update_text("cleaner_costs_text", self:cleaner_costs_string())

    self:update_text("cash_balance_text", managers.experience:cash_string(managers.money:total()))
    self:update_text("offshore_balance_text", managers.experience:cash_string(managers.money:offshore()))
end

function HUDStatsScreen:update_text(name, text)
    local field = self.day_wrapper_panel:child(name)

    if not field then
        return
    end

    field:set_text(text)
    field:set_w(self.day_wrapper_panel:w() / 2)
end

function HUDStatsScreen:add_text_pair(name, bottom_of, title_text, text_text)
    local title = self:add_text_entry(name .. "_title", title_text)
    local text = self:add_text_entry(name .. "_text", text_text)

    if bottom_of then
        title:set_top(math.round(bottom_of:bottom()))
        text:set_top(title:top())
        text:set_left(title:right() + 8)
    end

    return title, text
end

function HUDStatsScreen:add_text_entry(name, text)
    local text_entry = self.day_wrapper_panel:child(name) or self.day_wrapper_panel:text({
        name = name,
        font = tweak_data.menu.pd2_small_font,
        font_size = tweak_data.menu.pd2_small_font_size,
        text = text,
        color = Color.white,
        w = self.right_panel:w() / 2,
        blend_mode = "add",
        align = "left",
        vertical = "top"
    })

    managers.hud:make_fine_text(text_entry)

    return text_entry
end

function HUDStatsScreen:clean_up()
    self.day_wrapper_panel:child("paygrade_title"):set_visible(false)
    self.day_wrapper_panel:child("risk_text"):set_visible(false)
    self.day_wrapper_panel:child("day_payout"):set_visible(false)
    self.day_wrapper_panel:child("day_description"):set_visible(false)
    self.day_wrapper_panel:child("bains_plan"):set_visible(false)
    self.day_wrapper_panel:child("ghostable_text"):set_visible(false)
end

function HUDStatsScreen:day_payout_string()
    local exp = managers.experience
    return exp:cash_string(managers.money:get_potential_payout_from_current_stage())
end

function HUDStatsScreen:offshore_payout_string()
    local exp = managers.experience

    local potential_payout = managers.money:get_potential_payout_from_current_stage()
    local offshore_rate = managers.money:get_tweak_value("money_manager", "offshore_rate")

    return exp:cash_string(potential_payout - math.round(potential_payout * offshore_rate))
end

function HUDStatsScreen:cleaner_costs_string()
    local exp = managers.experience

    local cost = managers.money:get_civilian_deduction()
    local total_civilian_kills = managers.statistics:session_total_civilian_kills() or 0

    return "" .. exp:cash_string(cost * total_civilian_kills) .. "(" .. total_civilian_kills .. ")"
end

function HUDStatsScreen:spending_cash_string()
    local exp = managers.experience

    local potential_payout = managers.money:get_potential_payout_from_current_stage()
    local offshore_rate = managers.money:get_tweak_value("money_manager", "offshore_rate")
    local cleaner_costs = managers.money:get_civilian_deduction()
    local total_civilian_kills = managers.statistics:session_total_civilian_kills() or 0

    return exp:cash_string(math.round(potential_payout * offshore_rate) - cleaner_costs * total_civilian_kills)
end
