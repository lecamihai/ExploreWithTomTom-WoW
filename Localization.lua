-- Localization.lua

local Localization = {
    ["enUS"] = {
        ["ZONE_REACHED"] = "Zone reached: %s. Setting waypoints.",
        ["NO_UNDISCOVERED_WAYPOINTS"] = "No undiscovered waypoints found for %s.",
        ["GO_TO_ZONE"] = "Please go to %s and try again.",
        ["CLEARING_WAYPOINTS"] = "Zone change detected after 15 seconds. Clearing zone waypoints.",

        ["SELECT_A_ZONE"] = "Select a Zone",
        ["SELECT_ZONE"] = "Select Zone",
        ["SELECT_CONTINENT"] = "Select Continent",
        ["ADD_WAYPOINTS"] = "Add Waypoints",
        ["SELECT_CONTINENT_AND_ZONE"] = "Please select a continent and zone.",
        
        -- ["CONTINENT"] = "",
        ["CONTINENT_EASTERN_KINGDOMS"] = "Eastern Kingdoms",
        ["CONTINENT_KALIMDOR"] = "Kalimdor",
        ["CONTINENT_OUTLAND"] = "Outland",
        ["CONTINENT_NORTHREND"] = "Northrend",
        ["CONTINENT_PANDARIA"] = "Pandaria",
        ["CONTINENT_DRAENOR"] = "Draenor",
        ["CONTINENT_BROKEN_ISLES"] = "Broken Isles",
        ["CONTINENT_ZANDALAR"] = "Zandalar",
        ["CONTINENT_KUL_TIRAS"] = "Kul Tiras",
        ["CONTINENT_ARGUS"] = "Argus",
        ["CONTINENT_MAELSTROM"] = "The Maelstrom",
        ["CONTINENT_VASHJIR"] = "Vashj'ir",
        ["CONTINENT_SHADOWLANDS"] = "Shadowlands",
        ["CONTINENT_DRAGON_ISLES"] = "Dragon Isles",

        -- ["ZONE_"] = "",
        ["ZONE_EVERSONG_WOODS"] = "Eversong Woods",
        ["ZONE_GHOSTLAND"] = "Ghostlands",
        ["ZONE_ELWYNN_FOREST"] = "Elwynn Forest",
        ["ZONE_WESTFALL"] = "Westfall",

        -- ["WP_"] = "",
    },
    ["ruRU"] = {
        ["ZONE_REACHED"] = "Зона достигнута: %s. Устанавливаем точки маршрута.",
        ["NO_UNDISCOVERED_WAYPOINTS"] = "Не найдены неоткрытые точки маршрута для %s.",
        ["GO_TO_ZONE"] = "Пожалуйста, перейдите в %s и попробуйте снова.",
        ["CLEARING_WAYPOINTS"] = "Обнаружено изменение зоны через 15 секунд. Очистка точек маршрута.",

        ["SELECT_A_ZONE"] = "Выбрать зону",
        ["SELECT_ZONE"] = "Выбрать зону",
        ["SELECT_CONTINENT"] = "Выбрать континент",
        ["ADD_WAYPOINTS"] = "Добавить точки",
        ["SELECT_CONTINENT_AND_ZONE"] = "Пожалуйста, выберите континент и зону.",
        
        ["CONTINENT_EASTERN_KINGDOMS"] = "Восточные королевства",
        ["CONTINENT_KALIMDOR"] = "Калимдор",
        ["CONTINENT_OUTLAND"] = "Запределье",
        ["CONTINENT_NORTHREND"] = "Нордскол",
        ["CONTINENT_PANDARIA"] = "Пандария",
        ["CONTINENT_DRAENOR"] = "Дренор",
        ["CONTINENT_BROKEN_ISLES"] = "Расколотые острова",
        ["CONTINENT_ZANDALAR"] = "Зандалар",
        ["CONTINENT_KUL_TIRAS"] = "Кул-Тирас",
        ["CONTINENT_ARGUS"] = "Аргус",
        ["CONTINENT_MAELSTROM"] = "Водоворот",
        ["CONTINENT_VASHJIR"] = "Вайш'ир",
        ["CONTINENT_SHADOWLANDS"] = "Темные Земли",
        ["CONTINENT_DRAGON_ISLES"] = "Драконьи острова",

        ["ZONE_EVERSONG_WOODS"] = "Леса Вечной Песни",
        ["ZONE_GHOSTLAND"] = "Призрачные земли",
        ["ZONE_ELWYNN_FOREST"] = "Элвиннский лес",
        ["ZONE_WESTFALL"] = "Западный Край",
    }
}

local selectedLocale = GetLocale()
local currentLocalization = Localization[selectedLocale] or Localization["enUS"]

function localize(key, ...)
    local text = currentLocalization[key] or key
    return string.format(text, ...)
end

Localize = localize