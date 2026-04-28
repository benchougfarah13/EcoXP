/**
 * ============================================
 * PLANTS-DATA.JS — Base de données des plantes
 * Future Roots — Campus de la Manouba
 * ============================================
 *
 * Chaque plante possède :
 * - Identité (nom, nom latin, emoji, description)
 * - Statistiques de jeu (eau, soleil, résistance, croissance)
 * - Rareté (common, uncommon, rare, epic, legendary)
 * - Modèle 3D (chemin vers le fichier .glb)
 * - Position GPS (à définir par l'utilisateur)
 * - Caractéristiques botaniques réelles
 */

const PLANTS_DATABASE = [
  {
    id: 'olive_tree',
    name: 'Olivier',
    latinName: 'Olea europaea',
    emoji: '🫒',
    icon: '🌳',
    rarity: 'legendary',
    xpReward: 50,
    modelPath: 'Olive tree.glb',
    description: "L'olivier est l'arbre emblématique de la Méditerranée. Symbole de paix et de longévité, il peut vivre plus de 2000 ans. Ses feuilles argentées et son tronc noueux en font un monument vivant du campus.",
    funFact: "Un olivier peut produire des olives pendant plus de 1500 ans !",
    family: 'Oleaceae',
    origin: 'Bassin méditerranéen',
    maxHeight: '15m',
    floweringSeason: 'Printemps (Avril-Juin)',
    uses: ['Huile d\'olive', 'Alimentation', 'Bois', 'Médecine traditionnelle'],
    stats: {
      water: 30,       // Très résistant à la sécheresse
      sun: 95,         // Adore le soleil
      resistance: 90,  // Très résistant
      growth: 20,      // Croissance lente
    },
    // Position GPS — À DÉFINIR PAR L'UTILISATEUR
    position: { lng: 10.0630, lat: 36.8140 },
  },
  {
    id: 'palm_tree',
    name: 'Palmier',
    latinName: 'Phoenix dactylifera',
    emoji: '🌴',
    icon: '🌴',
    rarity: 'rare',
    xpReward: 40,
    modelPath: 'Palm Tree.glb',
    description: "Le palmier dattier est le roi des oasis. Ses palmes majestueuses offrent une ombre précieuse sur le campus. Il peut atteindre 30 mètres de hauteur et produire jusqu'à 100 kg de dattes par an.",
    funFact: "Le palmier dattier est cultivé depuis plus de 5000 ans en Afrique du Nord !",
    family: 'Arecaceae',
    origin: 'Afrique du Nord & Moyen-Orient',
    maxHeight: '30m',
    floweringSeason: 'Printemps (Mars-Mai)',
    uses: ['Dattes', 'Ombre', 'Vannerie', 'Construction'],
    stats: {
      water: 40,
      sun: 95,
      resistance: 75,
      growth: 45,
    },
    position: { lng: 10.0640, lat: 36.8132 },
  },
  {
    id: 'orange_tree',
    name: 'Oranger',
    latinName: 'Citrus sinensis',
    emoji: '🍊',
    icon: '🍊',
    rarity: 'epic',
    xpReward: 45,
    modelPath: 'Orange tree.glb',
    description: "L'oranger apporte couleur et parfum au campus. Ses fleurs blanches dégagent un arôme envoûtant au printemps, tandis que ses fruits dorés illuminent l'hiver méditerranéen.",
    funFact: "La fleur d'oranger (zhar) est un symbole de mariage en Tunisie !",
    family: 'Rutaceae',
    origin: 'Asie du Sud-Est',
    maxHeight: '10m',
    floweringSeason: 'Printemps (Avril-Mai)',
    uses: ['Fruits', 'Jus', 'Eau de fleur d\'oranger', 'Parfumerie'],
    stats: {
      water: 65,
      sun: 80,
      resistance: 55,
      growth: 60,
    },
    position: { lng: 10.0638, lat: 36.8138 },
  },
  {
    id: 'pine_tree',
    name: 'Pin d\'Alep',
    latinName: 'Pinus halepensis',
    emoji: '🌲',
    icon: '🌲',
    rarity: 'uncommon',
    xpReward: 30,
    modelPath: 'Pine.glb',
    description: "Le Pin d'Alep est le conifère le plus répandu en Tunisie. Sa silhouette élancée et son parfum résineux caractérisent les paysages du nord tunisien. Il joue un rôle crucial dans la lutte contre l'érosion.",
    funFact: "Son bois résineux était utilisé par les Phéniciens pour construire leurs navires !",
    family: 'Pinaceae',
    origin: 'Bassin méditerranéen',
    maxHeight: '20m',
    floweringSeason: 'Printemps (Mars-Mai)',
    uses: ['Reboisement', 'Bois', 'Résine', 'Ombre'],
    stats: {
      water: 25,
      sun: 85,
      resistance: 85,
      growth: 50,
    },
    position: { lng: 10.0628, lat: 36.8134 },
  },
  {
    id: 'jasmine',
    name: 'Jasmin',
    latinName: 'Jasminum grandiflorum',
    emoji: '🤍',
    icon: '🌸',
    rarity: 'epic',
    xpReward: 45,
    modelPath: 'jasmine.glb',
    description: "Le jasmin est l'âme de la Tunisie. Son parfum envoûtant embaume les ruelles et les jardins. Le petit bouquet de jasmin (machmoum) est un symbole culturel fort, offert en signe de bienvenue et d'amitié.",
    funFact: "Le jasmin de Tunisie est considéré comme l'un des plus parfumés au monde !",
    family: 'Oleaceae',
    origin: 'Asie du Sud',
    maxHeight: '4m (grimpant)',
    floweringSeason: 'Été (Juin-Septembre)',
    uses: ['Parfumerie', 'Tradition culturelle', 'Infusion', 'Décoration'],
    stats: {
      water: 60,
      sun: 75,
      resistance: 50,
      growth: 70,
    },
    position: { lng: 10.0642, lat: 36.8136 },
  },
  {
    id: 'apple_tree',
    name: 'Pommier',
    latinName: 'Malus domestica',
    emoji: '🍎',
    icon: '🍏',
    rarity: 'rare',
    xpReward: 40,
    modelPath: 'Apple tree.glb',
    description: "Le pommier est un arbre fruitier apprécié pour sa floraison spectaculaire au printemps et ses fruits en automne. Bien que plus typique des régions tempérées, certaines variétés s'adaptent au climat tunisien.",
    funFact: "Il existe plus de 7500 variétés de pommes dans le monde !",
    family: 'Rosaceae',
    origin: 'Asie centrale',
    maxHeight: '12m',
    floweringSeason: 'Printemps (Avril-Mai)',
    uses: ['Fruits', 'Jus', 'Confiture', 'Cidre'],
    stats: {
      water: 70,
      sun: 70,
      resistance: 45,
      growth: 55,
    },
    position: { lng: 10.0633, lat: 36.8130 },
  },
  {
    id: 'pear_tree',
    name: 'Poirier',
    latinName: 'Pyrus communis',
    emoji: '🍐',
    icon: '🍐',
    rarity: 'rare',
    xpReward: 40,
    modelPath: 'Pear tree.glb',
    description: "Le poirier est un arbre fruitier élégant connu pour sa forme pyramidale naturelle et sa floraison blanche printanière. Ses fruits juteux et sucrés en font un trésor du verger méditerranéen.",
    funFact: "Les poiriers peuvent vivre et produire des fruits pendant plus de 100 ans !",
    family: 'Rosaceae',
    origin: 'Europe & Asie occidentale',
    maxHeight: '15m',
    floweringSeason: 'Printemps (Mars-Avril)',
    uses: ['Fruits', 'Pâtisserie', 'Bois précieux', 'Confiture'],
    stats: {
      water: 65,
      sun: 75,
      resistance: 50,
      growth: 40,
    },
    position: { lng: 10.0645, lat: 36.8142 },
  },
  {
    id: 'bush_flowers',
    name: 'Bougainvillier',
    latinName: 'Bougainvillea spectabilis',
    emoji: '🌺',
    icon: '🌺',
    rarity: 'uncommon',
    xpReward: 30,
    modelPath: 'Bush with Flowers.glb',
    description: "Le bougainvillier est une explosion de couleurs qui habille les murs et les façades du campus. Ses bractées violettes, roses ou rouges ne sont pas des pétales mais des feuilles transformées qui protègent de petites fleurs blanches.",
    funFact: "Le bougainvillier a été nommé d'après l'explorateur français Louis Antoine de Bougainville !",
    family: 'Nyctaginaceae',
    origin: 'Amérique du Sud',
    maxHeight: '8m (grimpant)',
    floweringSeason: 'Été (Juin-Octobre)',
    uses: ['Décoration', 'Haies', 'Ombre', 'Médecine traditionnelle'],
    stats: {
      water: 35,
      sun: 90,
      resistance: 70,
      growth: 80,
    },
    position: { lng: 10.0625, lat: 36.8139 },
  },
  {
    id: 'generic_tree',
    name: 'Eucalyptus',
    latinName: 'Eucalyptus camaldulensis',
    emoji: '🌿',
    icon: '🌿',
    rarity: 'common',
    xpReward: 20,
    modelPath: 'low_poly_tree.glb',
    description: "L'eucalyptus est un arbre imposant introduit en Tunisie pour le reboisement. Son écorce qui pèle révèle un tronc lisse et ses feuilles dégagent une odeur camphrée caractéristique, utilisée en médecine traditionnelle.",
    funFact: "Les feuilles d'eucalyptus contiennent une huile essentielle aux propriétés décongestionnantes !",
    family: 'Myrtaceae',
    origin: 'Australie',
    maxHeight: '25m',
    floweringSeason: 'Variable',
    uses: ['Huiles essentielles', 'Reboisement', 'Bois', 'Apiculture'],
    stats: {
      water: 40,
      sun: 85,
      resistance: 80,
      growth: 90,
    },
    position: { lng: 10.0632, lat: 36.8144 },
  },
];

/**
 * Quêtes du campus — Missions à accomplir
 */
const QUESTS_DATABASE = [
  {
    id: 'quest_first_discovery',
    title: 'Premier Pas de Botaniste',
    description: 'Découvrez votre première plante sur le campus.',
    icon: '🌱',
    type: 'discovery',
    target: 1,
    xpReward: 50,
    completed: false,
  },
  {
    id: 'quest_three_species',
    title: 'Collectionneur en Herbe',
    description: 'Ajoutez 3 espèces différentes à votre Herbier.',
    icon: '📖',
    type: 'collection',
    target: 3,
    xpReward: 100,
    completed: false,
  },
  {
    id: 'quest_five_photos',
    title: 'Photographe Nature',
    description: 'Prenez 5 photos de plantes avec le Scanner.',
    icon: '📸',
    type: 'photo',
    target: 5,
    xpReward: 75,
    completed: false,
  },
  {
    id: 'quest_find_legendary',
    title: 'À la Recherche de l\'Olivier Millénaire',
    description: 'Trouvez et photographiez l\'olivier légendaire du campus.',
    icon: '🏆',
    type: 'specific',
    targetPlantId: 'olive_tree',
    target: 1,
    xpReward: 150,
    completed: false,
  },
  {
    id: 'quest_all_trees',
    title: 'Encyclopédie Vivante',
    description: 'Découvrez toutes les espèces d\'arbres du campus.',
    icon: '🌳',
    type: 'collection',
    target: 9,
    xpReward: 300,
    completed: false,
  },
  {
    id: 'quest_jasmine',
    title: 'Le Parfum de la Tunisie',
    description: 'Photographiez le jasmin, symbole de la Tunisie.',
    icon: '🤍',
    type: 'specific',
    targetPlantId: 'jasmine',
    target: 1,
    xpReward: 100,
    completed: false,
  },
];

/**
 * Obtenir la couleur associée à une rareté
 * @param {string} rarity - Niveau de rareté
 * @returns {string} Code couleur CSS
 */
function getRarityColor(rarity) {
  const colors = {
    common: '#94a3b8',
    uncommon: '#34d399',
    rare: '#60a5fa',
    epic: '#a78bfa',
    legendary: '#fbbf24',
  };
  return colors[rarity] || colors.common;
}

/**
 * Obtenir le label français d'une rareté
 * @param {string} rarity - Niveau de rareté
 * @returns {string} Label en français
 */
function getRarityLabel(rarity) {
  const labels = {
    common: 'Commune',
    uncommon: 'Peu Commune',
    rare: 'Rare',
    epic: 'Épique',
    legendary: 'Légendaire',
  };
  return labels[rarity] || labels.common;
}
