// TeamKiizonMenuData.swift
import SwiftUI

// MARK: - Menu Data

private let bistroMenu: [BistroMenuItem] = [

    // MARK: Signature Buns — 招牌包
    BistroMenuItem(
        name: "Braised Pork Pan-Fried Buns",
        nameZH: "酱香老娘水煎包",
        nameFR: "Brioches Frites au Porc Braise",
        description: "Crispy-bottom buns filled with slow-braised pork and aromatics. 4 pieces.",
        descriptionZH: "脆底水煎包，内馅红烧猪肉，香气四溢。4个。",
        descriptionFR: "Brioches croustillantes farcies de porc braise lentement. 4 pieces.",
        price: 12.99, category: .signatureBuns, systemImage: "circle.grid.3x3.fill",
        localImagePath: "braisedporkpanfriedbuns", allergens: ["Gluten", "Soy"], calories: 420
    ),
    BistroMenuItem(
        name: "Fresh Pork Pan-Fried Buns",
        nameZH: "鲜肉老娘水煎包",
        nameFR: "Brioches Frites au Porc Frais",
        description: "Juicy fresh pork filling, pan-fried golden on the bottom. 4 pieces.",
        descriptionZH: "新鲜猪肉馅，底部煎至金黄，汁水丰盈。4个。",
        descriptionFR: "Garniture de porc frais juteux, frits en bas. 4 pieces.",
        price: 11.99, category: .signatureBuns, systemImage: "circle.grid.3x3.fill",
        localImagePath: "freshporkpanfriedbuns", allergens: ["Gluten", "Soy"], calories: 390
    ),
    BistroMenuItem(
        name: "Mom's Soup Dumplings",
        nameZH: "老娘小笼汤包",
        nameFR: "Xiaolongbao de Maman",
        description: "Thin-skin soup dumplings bursting with savory pork broth. 6 pieces.",
        descriptionZH: "皮薄汤多，一口咬下满满肉汁。6个。",
        descriptionFR: "Raviolis a peau fine, bouillon savoureux porc. 6 pieces.",
        price: 13.99, category: .signatureBuns, systemImage: "drop.circle.fill",
        localImagePath: "soupdumplings", allergens: ["Gluten"], calories: 310
    ),
    BistroMenuItem(
        name: "Siu Mai Bamboo & Sticky Rice",
        nameZH: "笋干糯米烧卖",
        nameFR: "Siu Mai Bambou et Riz Gluant",
        description: "Open-top steamed dumplings with pork, sticky rice, and bamboo shoot. 4 pieces.",
        descriptionZH: "蒸制烧卖，猪肉竹笋糯米馅，鲜嫩可口。4个。",
        descriptionFR: "Dim sum vapeur, porc, riz gluant et pousses de bambou. 4 pieces.",
        price: 10.99, category: .signatureBuns, systemImage: "seal.fill",
        localImagePath: "siumai", allergens: ["Gluten", "Shellfish"], calories: 260
    ),

    // MARK: Appetizers — 开胃小食
    BistroMenuItem(
        name: "Spicy Vinegar Tofu Skin",
        nameZH: "老坛酸辣豆腐皮",
        nameFR: "Peau de Tofu Epicee au Vinaigre",
        description: "Tender tofu skin strips tossed in bold Sichuan vinegar chili dressing.",
        descriptionZH: "嫩滑豆腐皮，四川酸辣调味，开胃爽口。",
        descriptionFR: "Lanières de peau de tofu en sauce vinaigrée piquante du Sichuan.",
        price: 8.99, category: .appetizers, systemImage: "flame.fill",
        localImagePath: "spicyvinegartofuskin", allergens: ["Soy", "Sesame"], calories: 180
    ),
    BistroMenuItem(
        name: "Garlic Sliced Pork Belly",
        nameZH: "蒜泥白肉",
        nameFR: "Tranches de Porc a l'Ail",
        description: "Thinly sliced boiled pork belly drizzled with chili garlic sauce and sesame.",
        descriptionZH: "薄切白肉，浇上蒜泥红油，鲜香微辣。",
        descriptionFR: "Fines tranches de porc bouilli, sauce à l'ail pimentée et sésame.",
        price: 9.99, category: .appetizers, systemImage: "leaf.fill",
        localImagePath: "garlic sliced pork belly", allergens: ["Soy", "Sesame"], calories: 290
    ),
    BistroMenuItem(
        name: "Pickled Vinegar Peanuts",
        nameZH: "老醋花生",
        nameFR: "Cacahuetes au Vinaigre Vieilli",
        description: "Crispy peanuts marinated in aged black vinegar with coriander and garlic.",
        descriptionZH: "酥脆花生，陈醋腌制，香菜大蒜提香，下酒开胃。",
        descriptionFR: "Cacahuètes croquantes marinées au vinaigre noir, coriandre et ail.",
        price: 5.99, category: .appetizers, systemImage: "leaf",
        localImagePath: "pickledvinegarpeanuts", allergens: [], calories: 210
    ),

    // MARK: Noodles & Rice — 面食饭食
    BistroMenuItem(
        name: "Classic Beef Noodle Soup",
        nameZH: "经典牛肉面",
        nameFR: "Soupe de Nouilles au Boeuf Classique",
        description: "Slow-braised beef shank, hand-pulled noodles, rich bone broth, bok choy.",
        descriptionZH: "慢炖牛腱，手拉面条，浓郁骨汤，小白菜点缀。",
        descriptionFR: "Jarret de boeuf braise, nouilles tirees a la main, bouillon d'os riche.",
        price: 14.99, category: .noodlesRice, systemImage: "flame.fill",
        localImagePath: "classicbeefnoodlesoup", allergens: ["Gluten", "Soy"], calories: 720
    ),
    BistroMenuItem(
        name: "Braised Beef Noodle Soup",
        nameZH: "红烧牛肉面",
        nameFR: "Soupe de Nouilles au Boeuf Braise",
        description: "Melt-in-your-mouth red-braised beef, wide noodles, Sichuan spiced broth.",
        descriptionZH: "红烧牛肉入口即化，宽面条吸满浓郁汤汁。",
        descriptionFR: "Boeuf braise fondant, larges nouilles, bouillon epicé Sichuan.",
        price: 15.99, category: .noodlesRice, systemImage: "flame",
        localImagePath: "braisedbeefnoodlesoup", allergens: ["Gluten", "Soy"], calories: 760
    ),
    BistroMenuItem(
        name: "Beef & Pickled Mustard Rice Noodles",
        nameZH: "老坛酸菜牛肉粉",
        nameFR: "Nouilles de Riz Boeuf et Moutarde Marinee",
        description: "Tender beef slices over silky flat rice noodles in tangy pickled mustard broth.",
        descriptionZH: "嫩牛肉配酸菜，滑溜溜米粉，酸爽开胃。",
        descriptionFR: "Tranches de boeuf sur nouilles de riz en bouillon de moutarde marinée.",
        price: 13.99, category: .noodlesRice, systemImage: "fork.knife",
        localImagePath: "pickledmustardricenoods", allergens: [], calories: 560
    ),
    BistroMenuItem(
        name: "Grilled Pork Belly Egg on Rice",
        nameZH: "炭烧五花肉蛋拌饭",
        nameFR: "Riz au Porc Grille et Oeuf",
        description: "Charcoal-grilled pork belly, soft-boiled egg, pickled mustard on jasmine rice.",
        descriptionZH: "炭烤五花肉片，溏心蛋，酸菜配茉莉香米饭。",
        descriptionFR: "Porc grillé au charbon, oeuf mollet, moutarde marinée sur riz jasmin.",
        price: 12.99, category: .noodlesRice, systemImage: "bowl.fill",
        localImagePath: "grilledporkbellyeggonrice", allergens: ["Soy", "Eggs"], calories: 850
    ),

    // MARK: Fried Chicken — 炸鸡
    BistroMenuItem(
        name: "Magic Fried Chicken Wings",
        nameZH: "魔法炸鸡翅",
        nameFR: "Ailes de Poulet Frites Magiques",
        description: "Crispy wings in signature sweet-spicy glaze with sesame and green onion.",
        descriptionZH: "金黄酥脆鸡翅，招牌甜辣酱汁，芝麻葱花点缀。",
        descriptionFR: "Ailes croustillantes en sauce sucrée-épicée, sésame et oignons verts.",
        price: 13.99, category: .friedChicken, systemImage: "bolt.fill",
        localImagePath: "magicfriedchickenwings", allergens: ["Soy", "Sesame", "Gluten"], calories: 520
    ),
    BistroMenuItem(
        name: "Crispy Fried Chicken Bites",
        nameZH: "酥炸鸡块",
        nameFR: "Morceaux de Poulet Croustillants",
        description: "Bite-sized chicken pieces marinated in five-spice, fried to golden perfection.",
        descriptionZH: "五香腌制鸡块，炸至金黄，外酥里嫩。",
        descriptionFR: "Petits morceaux de poulet marinés aux cinq-épices, frits à la perfection.",
        price: 11.99, category: .friedChicken, systemImage: "bolt",
        localImagePath: "crispyfriedchickenbites", allergens: ["Gluten", "Soy"], calories: 460
    ),

    // MARK: Warm Congee & Noodles — 暖心粥粉
    BistroMenuItem(
        name: "Century Egg & Lean Pork Congee",
        nameZH: "皮蛋瘦肉粥",
        nameFR: "Congee Oeuf de Siecle et Porc Maigre",
        description: "Silky rice porridge with century egg, tender pork strips, ginger, and scallion.",
        descriptionZH: "细腻粥底，皮蛋瘦肉，姜丝葱花，温暖一碗。",
        descriptionFR: "Bouillie de riz soyeuse, oeuf de siècle, porc tendre, gingembre, oignon vert.",
        price: 9.99, category: .warmCongee, systemImage: "thermometer.medium",
        localImagePath: "centuryeggleanporkcongee", allergens: ["Eggs"], calories: 350
    ),
    BistroMenuItem(
        name: "Spicy & Sour Glass Noodle Soup",
        nameZH: "肥肠酸辣粉",
        nameFR: "Soupe de Vermicelles Epices et Aigres",
        description: "Silky vermicelli, tofu, black fungus, braised intestine in bold Sichuan broth.",
        descriptionZH: "滑嫩粉丝，豆腐，木耳，卤肥肠，浓郁麻辣汤底。",
        descriptionFR: "Vermicelles soyeux, tofu, champignon noir, boyaux en bouillon Sichuan.",
        price: 12.99, category: .warmCongee, systemImage: "flame.fill",
        localImagePath: "spicysourglassnoodlesoup", allergens: ["Soy", "Gluten"], calories: 480
    ),

    // MARK: Drinks — 饮品
    BistroMenuItem(
        name: "Sour Plum Drink",
        nameZH: "乌梅汁",
        nameFR: "Boisson Prune Aigre",
        description: "House-made sour plum drink with rock sugar and osmanthus blossom. Chilled.",
        descriptionZH: "自制乌梅汁，冰糖桂花，酸甜清爽，消暑解腻。",
        descriptionFR: "Boisson maison à la prune aigre, sucre candi et osmanthus. Glacée.",
        price: 4.99, category: .drinks, systemImage: "drop.fill",
        localImagePath: "sourplumdrink", allergens: [], calories: 90
    ),
    BistroMenuItem(
        name: "Chrysanthemum Wolfberry Tea",
        nameZH: "菊花枸杞茶",
        nameFR: "The Chrysantheme et Baies de Goji",
        description: "Traditional flowering chrysanthemum with dried wolfberries and rock sugar.",
        descriptionZH: "菊花枸杞泡茶，冰糖调味，清热明目，养生之选。",
        descriptionFR: "Chrysanthème fleuri traditionnel avec baies de goji et sucre candi.",
        price: 4.99, category: .drinks, systemImage: "leaf.fill",
        localImagePath: nil, allergens: [], calories: 30
    ),
    BistroMenuItem(
        name: "Sweet Soy Milk",
        nameZH: "甜豆浆",
        nameFR: "Lait de Soja Sucre",
        description: "Freshly pressed soy milk, lightly sweetened. Served warm or iced.",
        descriptionZH: "现磨豆浆，微甜润口，冷热皆宜。",
        descriptionFR: "Lait de soja fraîchement pressé, légèrement sucré. Chaud ou glacé.",
        price: 3.99, category: .drinks, systemImage: "cup.and.saucer.fill",
        localImagePath: "sweetsoymilk", allergens: ["Soy"], calories: 120
    ),
]
