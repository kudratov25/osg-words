"""Starter word bank: ~60 hand-picked everyday German words across
categories/difficulty matching the app's data model. Loaded into the DB
once on startup if the words table is empty.
"""

SEED_WORDS = [
    # Daily Life
    {"external_id": "der_schluessel", "german": "Schlüssel", "article": "der", "translation": "key", "example": "Wo ist mein Schlüssel?", "category": "Daily Life", "difficulty": "beginner"},
    {"external_id": "die_tuer", "german": "Tür", "article": "die", "translation": "door", "example": "Bitte mach die Tür zu.", "category": "Daily Life", "difficulty": "beginner"},
    {"external_id": "der_termin", "german": "Termin", "article": "der", "translation": "appointment", "example": "Ich habe morgen einen Termin.", "category": "Daily Life", "difficulty": "beginner"},
    {"external_id": "die_rechnung", "german": "Rechnung", "article": "die", "translation": "bill / receipt", "example": "Kann ich die Rechnung haben?", "category": "Daily Life", "difficulty": "beginner"},
    {"external_id": "der_wecker", "german": "Wecker", "article": "der", "translation": "alarm clock", "example": "Mein Wecker klingelt um sieben.", "category": "Daily Life", "difficulty": "beginner"},
    {"external_id": "die_wohnung", "german": "Wohnung", "article": "die", "translation": "apartment", "example": "Meine Wohnung ist klein, aber gemütlich.", "category": "Daily Life", "difficulty": "beginner"},
    {"external_id": "der_muell", "german": "Müll", "article": "der", "translation": "trash", "example": "Ich muss den Müll rausbringen.", "category": "Daily Life", "difficulty": "intermediate"},
    {"external_id": "die_kueche", "german": "Küche", "article": "die", "translation": "kitchen", "example": "Wir kochen zusammen in der Küche.", "category": "Daily Life", "difficulty": "beginner"},

    # Work
    {"external_id": "erledigen", "german": "erledigen", "article": None, "translation": "to complete / take care of", "example": "Ich muss meine Arbeit erledigen.", "category": "Work", "difficulty": "intermediate"},
    {"external_id": "die_besprechung", "german": "Besprechung", "article": "die", "translation": "meeting", "example": "Die Besprechung beginnt um zehn Uhr.", "category": "Work", "difficulty": "intermediate"},
    {"external_id": "die_frist", "german": "Frist", "article": "die", "translation": "deadline", "example": "Die Frist ist nächste Woche.", "category": "Work", "difficulty": "intermediate"},
    {"external_id": "der_kollege", "german": "Kollege", "article": "der", "translation": "colleague", "example": "Mein Kollege hilft mir gern.", "category": "Work", "difficulty": "beginner"},
    {"external_id": "loesen", "german": "lösen", "article": None, "translation": "to solve", "example": "Ich löse das Problem.", "category": "Work", "difficulty": "intermediate"},
    {"external_id": "die_aufgabe", "german": "Aufgabe", "article": "die", "translation": "task", "example": "Diese Aufgabe ist nicht schwer.", "category": "Work", "difficulty": "beginner"},
    {"external_id": "verdienen", "german": "verdienen", "article": None, "translation": "to earn", "example": "Er verdient gutes Geld.", "category": "Work", "difficulty": "intermediate"},

    # Food
    {"external_id": "das_brot", "german": "Brot", "article": "das", "translation": "bread", "example": "Ich kaufe frisches Brot.", "category": "Food", "difficulty": "beginner"},
    {"external_id": "der_hunger", "german": "Hunger", "article": "der", "translation": "hunger", "example": "Ich habe Hunger.", "category": "Food", "difficulty": "beginner"},
    {"external_id": "schmecken", "german": "schmecken", "article": None, "translation": "to taste", "example": "Das schmeckt sehr gut.", "category": "Food", "difficulty": "beginner"},
    {"external_id": "das_gemuese", "german": "Gemüse", "article": "das", "translation": "vegetables", "example": "Ich esse gern Gemüse.", "category": "Food", "difficulty": "beginner"},
    {"external_id": "der_durst", "german": "Durst", "article": "der", "translation": "thirst", "example": "Ich habe großen Durst.", "category": "Food", "difficulty": "beginner"},
    {"external_id": "bestellen", "german": "bestellen", "article": None, "translation": "to order", "example": "Wir bestellen zwei Kaffee.", "category": "Food", "difficulty": "beginner"},

    # Emotions
    {"external_id": "trotzdem", "german": "trotzdem", "article": None, "translation": "nevertheless", "example": "Er kommt trotzdem.", "category": "Emotions", "difficulty": "intermediate"},
    {"external_id": "sich_freuen", "german": "sich freuen", "article": None, "translation": "to be happy / look forward to", "example": "Ich freue mich auf das Wochenende.", "category": "Emotions", "difficulty": "intermediate"},
    {"external_id": "muede", "german": "müde", "article": None, "translation": "tired", "example": "Ich bin heute sehr müde.", "category": "Emotions", "difficulty": "beginner"},
    {"external_id": "aufgeregt", "german": "aufgeregt", "article": None, "translation": "excited / nervous", "example": "Sie ist vor der Prüfung aufgeregt.", "category": "Emotions", "difficulty": "intermediate"},
    {"external_id": "enttaeuscht", "german": "enttäuscht", "article": None, "translation": "disappointed", "example": "Er war von dem Film enttäuscht.", "category": "Emotions", "difficulty": "advanced"},

    # Travel
    {"external_id": "der_bahnhof", "german": "Bahnhof", "article": "der", "translation": "train station", "example": "Der Bahnhof ist ganz in der Nähe.", "category": "Travel", "difficulty": "beginner"},
    {"external_id": "die_verspaetung", "german": "Verspätung", "article": "die", "translation": "delay", "example": "Der Zug hat zehn Minuten Verspätung.", "category": "Travel", "difficulty": "advanced"},
    {"external_id": "das_gepaeck", "german": "Gepäck", "article": "das", "translation": "luggage", "example": "Mein Gepäck ist noch nicht da.", "category": "Travel", "difficulty": "intermediate"},
    {"external_id": "umsteigen", "german": "umsteigen", "article": None, "translation": "to change (trains/buses)", "example": "Sie müssen in Berlin umsteigen.", "category": "Travel", "difficulty": "intermediate"},
    {"external_id": "die_abfahrt", "german": "Abfahrt", "article": "die", "translation": "departure", "example": "Die Abfahrt ist um acht Uhr.", "category": "Travel", "difficulty": "intermediate"},

    # Health
    {"external_id": "der_arzt", "german": "Arzt", "article": "der", "translation": "doctor", "example": "Ich habe morgen einen Termin beim Arzt.", "category": "Health", "difficulty": "beginner"},
    {"external_id": "die_erkaeltung", "german": "Erkältung", "article": "die", "translation": "cold (illness)", "example": "Ich habe eine schlimme Erkältung.", "category": "Health", "difficulty": "intermediate"},
    {"external_id": "sich_ausruhen", "german": "sich ausruhen", "article": None, "translation": "to rest", "example": "Du solltest dich ausruhen.", "category": "Health", "difficulty": "intermediate"},
    {"external_id": "gesund", "german": "gesund", "article": None, "translation": "healthy", "example": "Obst ist gesund.", "category": "Health", "difficulty": "beginner"},

    # Numbers/time
    {"external_id": "gestern", "german": "gestern", "article": None, "translation": "yesterday", "example": "Gestern war ich zu Hause.", "category": "Time", "difficulty": "beginner"},
    {"external_id": "uebermorgen", "german": "übermorgen", "article": None, "translation": "the day after tomorrow", "example": "Übermorgen fahre ich nach Berlin.", "category": "Time", "difficulty": "intermediate"},
    {"external_id": "rechtzeitig", "german": "rechtzeitig", "article": None, "translation": "on time / in time", "example": "Wir kommen rechtzeitig an.", "category": "Time", "difficulty": "advanced"},
    {"external_id": "gleich", "german": "gleich", "article": None, "translation": "right away / soon", "example": "Ich bin gleich fertig.", "category": "Time", "difficulty": "beginner"},

    # Common verbs
    {"external_id": "brauchen", "german": "brauchen", "article": None, "translation": "to need", "example": "Ich brauche mehr Zeit.", "category": "Common Verbs", "difficulty": "beginner"},
    {"external_id": "versuchen", "german": "versuchen", "article": None, "translation": "to try", "example": "Ich versuche es noch einmal.", "category": "Common Verbs", "difficulty": "beginner"},
    {"external_id": "vergessen", "german": "vergessen", "article": None, "translation": "to forget", "example": "Ich habe meinen Schlüssel vergessen.", "category": "Common Verbs", "difficulty": "beginner"},
    {"external_id": "sich_beeilen", "german": "sich beeilen", "article": None, "translation": "to hurry", "example": "Wir müssen uns beeilen.", "category": "Common Verbs", "difficulty": "intermediate"},
    {"external_id": "entscheiden", "german": "entscheiden", "article": None, "translation": "to decide", "example": "Ich kann mich nicht entscheiden.", "category": "Common Verbs", "difficulty": "intermediate"},
    {"external_id": "verpassen", "german": "verpassen", "article": None, "translation": "to miss (a bus, chance)", "example": "Ich habe den Bus verpasst.", "category": "Common Verbs", "difficulty": "intermediate"},

    # Adjectives
    {"external_id": "wichtig", "german": "wichtig", "article": None, "translation": "important", "example": "Das ist sehr wichtig für mich.", "category": "Adjectives", "difficulty": "beginner"},
    {"external_id": "gefaehrlich", "german": "gefährlich", "article": None, "translation": "dangerous", "example": "Diese Straße ist gefährlich.", "category": "Adjectives", "difficulty": "intermediate"},
    {"external_id": "einfach", "german": "einfach", "article": None, "translation": "simple / easy", "example": "Diese Aufgabe ist einfach.", "category": "Adjectives", "difficulty": "beginner"},
    {"external_id": "schwierig", "german": "schwierig", "article": None, "translation": "difficult", "example": "Deutsch ist manchmal schwierig.", "category": "Adjectives", "difficulty": "beginner"},
    {"external_id": "notwendig", "german": "notwendig", "article": None, "translation": "necessary", "example": "Ein Regenschirm ist heute notwendig.", "category": "Adjectives", "difficulty": "advanced"},

    # Money
    {"external_id": "das_geld", "german": "Geld", "article": "das", "translation": "money", "example": "Ich habe kein Geld dabei.", "category": "Money", "difficulty": "beginner"},
    {"external_id": "sparen", "german": "sparen", "article": None, "translation": "to save (money)", "example": "Ich spare für den Urlaub.", "category": "Money", "difficulty": "beginner"},
    {"external_id": "bezahlen", "german": "bezahlen", "article": None, "translation": "to pay", "example": "Kann ich mit Karte bezahlen?", "category": "Money", "difficulty": "beginner"},
    {"external_id": "die_ausgabe", "german": "Ausgabe", "article": "die", "translation": "expense", "example": "Diese Ausgabe war nicht geplant.", "category": "Money", "difficulty": "advanced"},

    # Weather
    {"external_id": "der_regen", "german": "Regen", "article": "der", "translation": "rain", "example": "Der Regen hört bald auf.", "category": "Weather", "difficulty": "beginner"},
    {"external_id": "die_sonne", "german": "Sonne", "article": "die", "translation": "sun", "example": "Die Sonne scheint heute.", "category": "Weather", "difficulty": "beginner"},
    {"external_id": "der_sturm", "german": "Sturm", "article": "der", "translation": "storm", "example": "Ein Sturm zieht auf.", "category": "Weather", "difficulty": "intermediate"},

    # Social
    {"external_id": "einladen", "german": "einladen", "article": None, "translation": "to invite", "example": "Ich lade dich zum Essen ein.", "category": "Social", "difficulty": "intermediate"},
    {"external_id": "sich_verabreden", "german": "sich verabreden", "article": None, "translation": "to arrange to meet", "example": "Wir haben uns fürs Kino verabredet.", "category": "Social", "difficulty": "advanced"},
    {"external_id": "der_freund", "german": "Freund", "article": "der", "translation": "friend", "example": "Er ist ein guter Freund.", "category": "Social", "difficulty": "beginner"},
]
