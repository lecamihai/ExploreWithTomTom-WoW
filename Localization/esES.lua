Localization = Localization or {}

Localization["esES"] = {
    -- Continentes clásicos --

    -- World of Warcraft (Vanilla)
    ["Reinos del Este"] = { -- "Eastern Kingdoms" in Spanish
        ["Bosque Canción Eterna"] = { -- "Eversong Woods"
            achievementID = 859, 
            proxyLocation = {56, 17, "Bosque Canción Eterna"},
            waypoints = {
                {34, 23, "Isla del Caminante del Sol"},
                {44, 41, "Ruinas de Lunargenta"},
                {35, 58, "Santuario del Oeste"},
                {32, 70, "Anclaje de Velasolar"},
                {44, 53, "Santuario del Norte"},
                {53, 70, "Santuario del Este"},
                {60, 62, "Retiro de los Peregrinos"},
                {54, 55, "Estanque Murmullo"},
                {68, 47, "Tierras de Viento Brumoso"},
                {44, 71, "Aldea Brisaveloz"},
                {59, 72, "Bosque Viviente"},
                {72, 75, "Tor'Watha"},
                {36, 86, "Arboleda Calcinada"},
                {57, 41, "Lunargenta"},
                {72, 45, "Costa Azul"},
                {64, 72.5, "Cataratas Elrendar"},
                {33, 78, "Paso Hoja Dorada"},
                {66, 74, "Lago Elrendar"},
                {44, 85, "Piedra Rúnica Falithas"},
                {55, 84, "Piedra Rúnica Shan'dor"},
                {38, 73, "Refugio de Saltheril"},
                {23, 75, "Playa Dorada"},
                {61, 54, "Establo de Thuron"},
                {27, 59, "Costa Tranquila"},
                {62, 80, "Zeb'Watha"}
            }
        },
        ["Tierras Fantasma"] = { -- "Ghostlands" in Spanish
            achievementID = 858,
            proxyLocation = {56, 24, "Tierras Fantasma"},
            waypoints = {
                {46, 33, "Tranquillien"},
                {61, 12, "Aldea Sol Devastado"},
                {26, 15, "Aldea Bruma Dorada"},
                {19, 43, "Aldea Viento Libre"},
                {33, 35, "Santuario de la Luna"},
                {55, 48, "Santuario del Sol"},
                {79, 21, "Aguja del Alba"},
                {72, 31, "Enclave de los Peregrinos"},
                {40, 49, "Zigurat Chillona"},
                {33, 80, "Bosque Muerto"},
                {65, 61, "Zeb’Nowa"},
                {76, 64, "Paso de los Amani"},
                {13, 55, "Aguja Viento Libre"},
                {34, 47, "Zigurat Sangrienta"},
                {48, 13, "Cruce Elrendar"},
                {47, 78, "Paso Thalassiano"},
            },
        },
        ["Páramos de Poniente"] = { -- "Westfall" in Spanish
            achievementID = 802,
            proxyLocation = { 41, 80, "Páramos de Poniente" },
            waypoints = {
                { 56, 50, "Colina del Centinela" },
                { 54, 31, "Granja de los Saldean" },
                { 51, 21, "Huerta de los Tuercepinos" },
                { 58, 17, "Granja de los Jansen" },
                { 44, 24, "Mina del Excelsior" },
                { 45, 35, "Granja de los Molsen" },
                { 61, 59, "El Acre de la Muerte" },
                { 41, 66, "Lunargenta" },
                { 38, 52, "Granja de los Alexston" },
                { 34, 70, "Casa de Dermont" },
                { 30, 86, "Faro de los Páramos de Poniente" },
                { 44, 80, "Colinas de la Daga" },
                { 38, 42, "Garganta Rugiente" },
                { 61, 72, "Llanuras Polvorientas" },
            },
        },
        ["Bosque de Elwynn"] = { -- "Elwynn Forest" in Spanish
            achievementID = 776,
            proxyLocation = {45, 74, "Bosque de Elwynn"},
            waypoints = {
                {48, 41, "Valle de Villanorte"},
                {24, 76, "Garnición de los Cruzados"},
                {42, 65, "Villa del Oro"},
                {38, 81, "Mina de la Cantera Oscura"},
                {48, 86, "Muelle de Jerod"},
                {64, 71, "Torre de Azora"},
                {69, 80, "Calabaza de Brackwell"},
                {82, 67, "Campamento Maderero de Estival"},
                {84, 80, "Torre del Mirador"},
                {52, 66, "Lago Cristalino"},
                {74, 52, "Lago del Cairn de Piedra"},
            },
        },
        ["Bosque del Ocaso"] = {
            achievementID = 778,
            proxyLocation = { 46, 80, "Bosque del Ocaso" },
            waypoints = {
                { 21, 69, "La Granja de Addle" },
                { 19, 56, "Cerro del Cuervo" },
                { 19, 41, "Cementerio del Cerro del Cuervo" },
                { 35, 73, "Túmulo de Vul'Gol" },
                { 47, 40, "Arboleda del Crepúsculo" },
                { 49, 73, "La Hacienda Yorgen" },
                { 65, 38, "Arboleda del Destello" },
                { 64, 71, "El Vergel Pútrido" },
                { 79, 69, "Cementerio del Jardín Sereno" },
                { 74, 47, "Villa Oscura" },
                { 77, 36, "Mansión Mantoneblina" },
                { 56, 16, "La Ribera Lóbrega" },
            },
        },

        -- Continúe de forma similar con las demás zonas...
    },
    ["Kalimdor"] = {
        -- Añada las traducciones de las zonas de Kalimdor aquí...
        -- Ejemplo:
        ["Durotar"] = {
            achievementID = 123, -- ID de ejemplo
            proxyLocation = {50, 50, "Durotar"},
            waypoints = {
                {40, 50, "Orgrimmar"},
                -- Añada otros puntos de interés...
            }
        },
        -- Añada otras zonas de Kalimdor...
    },
    -- Añada otros continentes...
    ["Continents"] = {
        ["Eastern Kingdoms"] = "Reinos del Este",
        ["Kalimdor"]         = "Kalimdor",
        ["Outland"]          = "Terrallende",
        ["Northrend"]        = "Rasganorte",
        ["Pandaria"]         = "Pandaria",
        ["Draenor"]          = "Draenor",
        ["Broken Isles"]     = "Islas Quebradas",
        ["Zandalar"]         = "Zandalar",
        ["Kul Tiras"]        = "Kul Tiras",
        ["Shadowlands"]      = "Tierras Sombrías",
        ["Dragon Isles"]     = "Islas Dragón",
        ["The Maelstrom"]    = "La Vorágine",
        ["Vashj'ir"]         = "Vashj'ir",
    }
    
}
