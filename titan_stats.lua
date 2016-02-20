-- Titan Stats

local titan_stats_init = HUDStatsScreen.init
local titan_stats_show = HUDStatsScreen.show

function HUDStatsScreen:init()
    titan_stats_init(self)

    self.right_panel = self._full_hud_panel:child("right_panel")
    self.day_wrapper_panel = self.right_panel:child("day_wrapper_panel")
    self:clean_up()

    -- pro job? make title red
    if managers.job:is_current_job_professional() then
        self.day_wrapper_panel:child("day_title"):set_color(Color.red)
    end

    -- create new text elements
    local category_left = 0

    -- current balance
    local balance_category = self:add_text_entry("balance_category", "BALANCE")

    balance_category:set_left(category_left)
    balance_category:set_top(self.day_wrapper_panel:child("day_title"):bottom() + 5)

    local cash_balance_title, cash_balance_text = self:add_text_pair("cash_balance", balance_category, "SPENDING CASH:", "...")
    local offshore_balance_title, offshore_balance_text = self:add_text_pair("offshore_balance", cash_balance_title, "OFFSHORE:", "...")

    -- job stats
    local jobstats_category = self:add_text_entry("jobstats_category", "JOB STATS")

    jobstats_category:set_left(category_left)
    jobstats_category:set_top(offshore_balance_title:bottom() + 10)

    local difficulty_title, difficulty_text = self:add_text_pair("difficulty", jobstats_category, managers.localization:to_upper_text("menu_lobby_difficulty_title"), "...")

    if managers.job:current_job_data() then
        local job_stars = managers.job:current_job_stars()
        local job_and_difficulty_stars = managers.job:current_job_and_difficulty_stars()
        local difficulty_stars = managers.job:current_difficulty_stars()
        local difficulty = tweak_data.difficulties[difficulty_stars + 2] or 1
        local difficulty_string_id = tweak_data.difficulty_name_ids[difficulty]

        self:update_text("difficulty_text", managers.localization:to_upper_text(difficulty_string_id))

        if difficulty_stars > 0 then
            difficulty_text:set_color(tweak_data.screen_colors.risk)
        end
    end

    local day_payout_title, day_payout_text = self:add_text_pair("day_payout", difficulty_title, "TOTAL PAYOUT:", "...")
    local spending_cash_title, spending_cash_text = self:add_text_pair("spending_cash", day_payout_title, "SPENDING CASH:", "...", 20)
    local offshore_payout_title, offshore_payout_text = self:add_text_pair("offshore_payout", spending_cash_title, "OFFSHORE:", "...", 20)
    local cleaner_costs_title, cleaner_costs_text = self:add_text_pair("cleaner_costs", offshore_payout_title, "CLEANER COSTS:", "...")
    local gagepackages_title, gagepackages_text = self:add_text_pair("gagepackages", cleaner_costs_title, "GAGE PACKAGES:", "...")

    gagepackages_text:set_color(tweak_data.screen_colors.risk)

    -- side jobs
    local sidejobs_category = self:add_text_entry("sidejobs_category", "SIDE JOBS")

    sidejobs_category:set_left(category_left)
    sidejobs_category:set_top(gagepackages_title:bottom() + 10)

    local last_job = sidejobs_category

    for _, challenge in pairs(Global.challenge_manager.active_challenges or {}) do
        local progress_string = nil

        -- if has progress show a progress indicator instead
        if challenge.objectives[1].progress then
            progress_string = challenge.objectives[1].progress .. "/" .. challenge.objectives[1].max_progress
        else
            progress_string = "0/" .. challenge.objectives[1].max_progress
        end

        local sj_title, sj_progress = self:add_text_pair("sj_" .. challenge.id, last_job, managers.localization:to_upper_text(challenge.name_id), progress_string)

        sj_progress:set_color(tweak_data.screen_colors.risk)

        -- if has no progress don't use desc since they're way too long
        local desc_id = challenge.desc_id

        if not challenge.objectives[1].progress and challenge.objective_id then
            desc_id = challenge.objective_id
        end

        local sj_desc = self:add_desc_entry("sj_" .. challenge.id .. "_desc", managers.localization:to_upper_text(desc_id))

        sj_desc:set_top(sj_title:bottom())
        sj_desc:set_left(spending_cash_title:left())

        last_job = sj_desc
    end
end

function HUDStatsScreen:show()
    titan_stats_show(self)

    self.right_panel = self._full_hud_panel:child("right_panel")

    if not self.right_panel then
        return
    end

	self.day_wrapper_panel = self.right_panel:child("day_wrapper_panel")

    if not self.day_wrapper_panel then
        return
    end

    self:clean_up()

    self:update_text("cash_balance_text", managers.experience:cash_string(managers.money:total()))
    self:update_text("offshore_balance_text", managers.experience:cash_string(managers.money:offshore()))

    self:update_text("day_payout_text", self:day_payout_string())
    self:update_text("spending_cash_text", self:spending_cash_string())
    self:update_text("offshore_payout_text", self:offshore_payout_string())
    self:update_text("cleaner_costs_text", self:cleaner_costs_string())

    local total_civilian_kills = managers.statistics:session_total_civilian_kills() or 0

    if total_civilian_kills > 0 then
        self.day_wrapper_panel:child("cleaner_costs_text"):set_color(tweak_data.screen_colors.risk)
    end

    local gagepackages_left = managers.gage_assignment:count_active_units()

    self:update_text("gagepackages_text", gagepackages_left .. " LEFT")

    if gagepackages_left == 0 then
        self.day_wrapper_panel:child("gagepackages_text"):set_color(Color.green)
    end

    -- update side jobs
    for _, challenge in pairs(Global.challenge_manager.active_challenges or {}) do
        -- only objectives with progress are shown
        if challenge.objectives[1].progress then
            local progress_string = challenge.objectives[1].progress .. "/" .. challenge.objectives[1].max_progress

            self:update_text("sj_" .. challenge.id .. "_text", progress_string)

            if challenge.objectives[1].completed then
                self.day_wrapper_panel:child("sj_" .. challenge.id .. "_text"):set_color(Color.green)
            end
        else
            -- side jobs without a real progress need to be handled seperatly
            if challenge.objectives[1].completed then
                local progress_string = challenge.objectives[1].max_progress .. "/" .. challenge.objectives[1].max_progress
                self:update_text("sj_" .. challenge.id .. "_text", progress_string)

                self.day_wrapper_panel:child("sj_" .. challenge.id .. "_text"):set_color(Color.green)
            end
        end
    end
end

function HUDStatsScreen:update_text(name, text)
    local field = self.day_wrapper_panel:child(name)

    if not field then
        return
    end

    field:set_text(text)
    field:set_w(self.day_wrapper_panel:w() / 2)
end

function HUDStatsScreen:add_text_pair(name, bottom_of, title_text, text_text, title_padding_left)
    local title = self:add_text_entry(name .. "_title", title_text)
    local text = self:add_text_entry(name .. "_text", text_text)

    if bottom_of then
        title:set_top(math.round(bottom_of:bottom()))

        if not title_padding_left then
            title_padding_left = 0
        end

        title:set_left(20 + title_padding_left)
        text:set_top(title:top())
        text:set_left(title:right() + 8)
    end

    return title, text
end

function HUDStatsScreen:add_text_entry(name, text)
    local text_entry = self.day_wrapper_panel:child(name) or self.day_wrapper_panel:text({
        name = name,
        font = tweak_data.menu.pd2_small_font,
        font_size = 18,--tweak_data.menu.pd2_small_font_size,
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

function HUDStatsScreen:add_desc_entry(name, text)
    local text_entry = self.day_wrapper_panel:child(name) or self.day_wrapper_panel:text({
        name = name,
        font = tweak_data.menu.pd2_small_font,
        font_size = 12,
        text = text,
        color = Color.white,
        w = self.day_wrapper_panel:w() - 20,
        blend_mode = "add",
        align = "left",
        vertical = "top",
        wrap = true,
        word_wrap = true
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

    return "" .. exp:cash_string(cost * total_civilian_kills) .. " (" .. total_civilian_kills .. ")"
end

function HUDStatsScreen:spending_cash_string()
    local exp = managers.experience

    local potential_payout = managers.money:get_potential_payout_from_current_stage()
    local offshore_rate = managers.money:get_tweak_value("money_manager", "offshore_rate")

    return exp:cash_string(math.round(potential_payout * offshore_rate))
end
