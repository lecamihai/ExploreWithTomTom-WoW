-- frFR.lua

Localization = Localization or {}

Localization["frFR"] = {
    -- Continents classiques --

    -- World of Warcraft (Vanilla)
    ["Royaumes de l’Est"] = { -- "Eastern Kingdoms" in French
        ["Bois des Chants éternels"] = { -- "Eversong Woods"
            achievementID = 859, 
            proxyLocation = {56, 17, "Bois des Chants éternels"},
            waypoints = {
                {34, 23, "Île de Haut-Soleil"},
                {44, 41, "Ruines de Lune-d'argent"},
                {35, 58, "Sanctum de l’Ouest"},
                {32, 70, "Ancrage de Voile-d'été"},
                {44, 53, "Sanctum du Nord"},
                {53, 70, "Sanctum de l’Est"},
                {60, 62, "Retraite des Pérégrins"},
                {54, 55, "Étang Murmevent"},
                {68, 47, "Les Terres de Brumevent"},
                {44, 71, "Village de Brise-clair"},
                {59, 72, "Bois Vivant"},
                {72, 75, "Tor'Watha"},
                {36, 86, "Bosquet calciné"},
                {57, 41, "Lune-d’argent"},
                {72, 45, "Côte d'Azur"},
                {64, 72.5, "Chutes d'Elrendar"},
                {33, 78, "Passage de Feuille-d’Or"},
                {66, 74, "Lac Elrendar"},
                {44, 85, "Pierre runique Falithas"},
                {55, 84, "Pierre runique Shan’dor"},
                {38, 73, "Havre de Saltheril"},
                {23, 75, "Grève Dorée"},
                {61, 54, "Écurie de Thuron"},
                {27, 59, "Rivage paisible"},
                {62, 80, "Zeb'Watha"}
            }
        },
        ["Bois de la Pénombre"] = {
            achievementID = 778,
            proxyLocation = { 46, 80, "Bois de la Pénombre" },
            waypoints = {
                { 21, 69, "Ferme d'Addle" },
                { 19, 56, "Colline-aux-Corbeaux" },
                { 19, 41, "Cimetière de la Colline-aux-Corbeaux" },
                { 35, 73, "Monticule des Ogres de Vul'Gol" },
                { 47, 40, "Bosquet du Crépuscule" },
                { 49, 73, "Ferme des Yorgen" },
                { 65, 38, "Bosquet Boisbrillant" },
                { 64, 71, "Vergers Pourrissants" },
                { 79, 69, "Cimetière des Jardins Tranquilles" },
                { 74, 47, "Sombre-Comté" },
                { 77, 36, "Manoir Mistmantle" },
                { 56, 16, "Rivage Assombri" },
            },
        },
        ["Les Terres Fantômes"] = { -- "Ghostlands" in French
            achievementID = 858,
            proxyLocation = {56, 24, "Les Terres Fantômes"},
            waypoints = {
                {46, 33, "Tranquillien"},
                {61, 12, "Village de Soleil brisé"},
                {26, 15, "Village de Brume-d'or"},
                {19, 43, "Village des Coursevent"},
                {33, 35, "Sanctum de la Lune"},
                {55, 48, "Sanctum du Soleil"},
                {79, 21, "Flèche de l’Aube"},
                {72, 31, "Enclave des Pérégrins"},
                {40, 49, "Ziggourat hurlante"},
                {33, 80, "Mort-Bois"},
                {65, 61, "Zeb’Nowa"},
                {76, 64, "Passe d’Amani"},
                {13, 55, "Flèche Coursevent"},
                {34, 47, "Ziggourat sanglante"},
                {48, 13, "Croisée d’Elrendar"},
                {47, 78, "Passe thalassienne"},
            },
        },
        ["Marche de l’Ouest"] = { -- This is the only correct one
            achievementID = 802,
            proxyLocation = { 41, 80, "Marche de l’Ouest" },
            waypoints = {
                { 56, 50, "Colline des Sentinelles" },
                { 54, 31, "Ferme des Saldean" },
                { 51, 21, "Ferme de potirons des Froncebouille" },
                { 58, 17, "Ferme des Jansen" },
                { 44, 24, "Mine Veine-de-Jango" },
                { 45, 35, "Ferme des Molsen" },
                { 61, 59, "L’acre Mort" },
                { 41, 66, "Ruisselune" },
                { 38, 52, "Ferme des Alexston" },
                { 34, 70, "Maison de Dermont" },
                { 30, 86, "Phare de la Marche de l’Ouest" },
                { 44, 80, "Les collines de la Dague" },
                { 38, 42, "Le gouffre Déchaîné" },
                { 61, 72, "Les plaines de Poussière" },
            },
        },
        ["Forêt d’Elwynn"] = { -- "Elwynn Forest" in French
            achievementID = 776,
            proxyLocation = {45, 74, "Forêt d’Elwynn"},
            waypoints = {
                {48, 41, "Vallée de Comté-du-Nord"},
                {24, 76, "Garnison des Croisées"},
                {42, 65, "Comté-de-l’Or"},
                {38, 81, "Mine Veine-de-Jais"},
                {48, 86, "Accostage de Jerod"},
                {64, 71, "Tour d’Azora"},
                {69, 80, "Potiron de Brackwell"},
                {82, 67, "Camp des bûcherons d’Estiville"},
                {84, 80, "Tour du point de vue"},
                {52, 66, "Lac Cristal"},
                {74, 52, "Lac Cairn de pierre"},
            },
        },
        -- Continue similarly for other zones...
    },
    ["Kalimdor"] = {
        -- Add French translations for Kalimdor zones here...
        -- Example:
        ["Durotar"] = {
            achievementID = 123, -- Example ID
            proxyLocation = {50, 50, "Durotar"},
            waypoints = {
                {40, 50, "Orgrimmar"},
                -- Add other waypoints...
            }
        },
        -- Add other Kalimdor zones...
    },
    -- Add other continents...
    ["Continents"] = {
        ["Eastern Kingdoms"] = "Royaumes de l’Est",
        ["Kalimdor"]         = "Kalimdor",
        ["Outland"]          = "Outreterre",
        ["Northrend"]        = "Norfendre",
        ["Pandaria"]         = "Pandarie",
        ["Draenor"]          = "Draenor",
        ["Broken Isles"]     = "Îles Brisées",
        ["Zandalar"]         = "Zandalar",
        ["Kul Tiras"]        = "Kul Tiras",
        ["Shadowlands"]      = "Shadowlands", -- If Blizzard doesn't localize name
        ["Dragon Isles"]     = "Îles aux Dragons",
        ["The Maelstrom"]    = "Le Maelström",
        ["Vashj'ir"]         = "Vashj'ir",
        -- etc. if you need more...
    },
}