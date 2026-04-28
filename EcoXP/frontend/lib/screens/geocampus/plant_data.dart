class PlantDetail {
  final String name;
  final String scientificName;
  final List<String> lightRequirements;
  final List<String> waterRequirements;
  final List<String> growthForms;
  final bool droughtTolerant;
  final List<String> keyCharacteristics;

  // Legacy compat fields
  String get type => growthForms.join(', ');
  String get characteristics => keyCharacteristics.join(', ');
  String get environment =>
      '${lightRequirements.join('/')} · ${waterRequirements.join('/')}';

  const PlantDetail({
    required this.name,
    required this.scientificName,
    required this.lightRequirements,
    required this.waterRequirements,
    required this.growthForms,
    required this.droughtTolerant,
    required this.keyCharacteristics,
  });
}

// Legacy alias so existing code still compiles
typedef Plant = PlantDetail;

const List<PlantDetail> plantList = [
  PlantDetail(
    name: 'Bougainvillea White',
    scientificName: 'Bougainvillea spectabilis',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water', 'Moderate Water'],
    growthForms: ['Climber', 'Shrub'],
    droughtTolerant: true,
    keyCharacteristics: ['Ornamental Flowers'],
  ),
  PlantDetail(
    name: 'Bougainvillea Magenta',
    scientificName: 'Bougainvillea glabra',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water', 'Moderate Water'],
    growthForms: ['Climber', 'Shrub'],
    droughtTolerant: true,
    keyCharacteristics: ['Ornamental Flowers'],
  ),
  PlantDetail(
    name: "Bougainvillea 'Rosenka'",
    scientificName: "Bougainvillea × buttiana 'Rosenka'",
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water', 'Moderate Water'],
    growthForms: ['Climber', 'Shrub'],
    droughtTolerant: true,
    keyCharacteristics: ['Ornamental Flowers'],
  ),
  PlantDetail(
    name: "Bougainvillea 'Enid Lancaster'",
    scientificName: "Bougainvillea × buttiana 'Enid Lancaster'",
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water', 'Moderate Water'],
    growthForms: ['Climber', 'Shrub'],
    droughtTolerant: true,
    keyCharacteristics: ['Ornamental Flowers'],
  ),
  PlantDetail(
    name: 'Yellow Oleander',
    scientificName: 'Cascabela thevetia',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water'],
    growthForms: ['Shrub'],
    droughtTolerant: true,
    keyCharacteristics: ['Ornamental Flowers', 'Ornamental Leaves'],
  ),
  PlantDetail(
    name: 'Oxalis corniculata',
    scientificName: 'Oxalis corniculata',
    lightRequirements: ['Full Sun', 'Semi Shade'],
    waterRequirements: ['Moderate Water'],
    growthForms: ['Annual', 'Herbaceous Plant'],
    droughtTolerant: false,
    keyCharacteristics: [],
  ),
  PlantDetail(
    name: 'Date Palm',
    scientificName: 'Phoenix dactylifera',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Moderate Water'],
    growthForms: ['Palm'],
    droughtTolerant: true,
    keyCharacteristics: ['Fruit or Vegetable', 'Cool Environment', 'Solitary Environment'],
  ),
  PlantDetail(
    name: 'Oriental Arborvitae',
    scientificName: 'Platycladus orientalis',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Moderate Water'],
    growthForms: ['Tree'],
    droughtTolerant: true,
    keyCharacteristics: ['Ornamental Leaves'],
  ),
  PlantDetail(
    name: 'Eve\'s Needle Cactus',
    scientificName: 'Austrocylindropuntia subulata',
    lightRequirements: ['Full Sun', 'Semi Shade'],
    waterRequirements: ['Little Water'],
    growthForms: ['Herbaceous Succulent Plant'],
    droughtTolerant: true,
    keyCharacteristics: [],
  ),
  PlantDetail(
    name: "Agave 'Variegata'",
    scientificName: "Agave desmetiana 'Variegata'",
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water'],
    growthForms: ['Underground Storage Organ'],
    droughtTolerant: true,
    keyCharacteristics: ['Suitable for Rooftops', 'Ornamental Leaves', 'Storage Organ'],
  ),
  PlantDetail(
    name: 'White Plumbago',
    scientificName: 'Plumbago auriculata f. alba',
    lightRequirements: ['Full Sun', 'Semi Shade'],
    waterRequirements: ['Moderate Water'],
    growthForms: ['Shrub'],
    droughtTolerant: true,
    keyCharacteristics: ['Butterfly-Attracting Plant', 'Ornamental Flowers'],
  ),
  PlantDetail(
    name: 'Olive Tree',
    scientificName: 'Olea europaea',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water'],
    growthForms: ['Tree'],
    droughtTolerant: true,
    keyCharacteristics: ['Herb or Spice', 'Fragrant Plant'],
  ),
  PlantDetail(
    name: "Lantana 'Nivea'",
    scientificName: "Lantana camara 'Nivea'",
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water'],
    growthForms: ['Shrub'],
    droughtTolerant: true,
    keyCharacteristics: [
      'Butterfly Host Plant',
      'Butterfly-Attracting Plant',
      'Coastal Plant',
      'Fragrant Plant',
      'Ornamental Flowers'
    ],
  ),
  PlantDetail(
    name: "Lantana 'Mutabilis'",
    scientificName: "Lantana camara 'Mutabilis'",
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water'],
    growthForms: ['Shrub'],
    droughtTolerant: true,
    keyCharacteristics: [
      'Butterfly Host Plant',
      'Butterfly-Attracting Plant',
      'Coastal Plant',
      'Fragrant Plant',
      'Ornamental Flowers'
    ],
  ),
  PlantDetail(
    name: 'Silver Ragwort',
    scientificName: 'Jacobaea maritima',
    lightRequirements: ['Full Sun', 'Semi Shade'],
    waterRequirements: ['Moderate Water'],
    growthForms: ['Herbaceous Plant'],
    droughtTolerant: true,
    keyCharacteristics: ['Ornamental Leaves', 'Cool Environment'],
  ),
  PlantDetail(
    name: 'Hibiscus',
    scientificName: 'Hibiscus rosa-sinensis',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Moderate Water'],
    growthForms: ['Shrub'],
    droughtTolerant: false,
    keyCharacteristics: ['Ornamental Flowers', 'Ornamental Leaves'],
  ),
  PlantDetail(
    name: 'Spanish Jasmine',
    scientificName: 'Jasminum grandiflorum',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Moderate Water'],
    growthForms: ['Climber', 'Shrub'],
    droughtTolerant: false,
    keyCharacteristics: [
      'Herb or Spice',
      'Suitable for Hanging Baskets',
      'Fragrant Plant',
      'Ornamental Flowers'
    ],
  ),
  PlantDetail(
    name: "Bush Daisy 'Viridis'",
    scientificName: "Euryops pectinatus 'Viridis'",
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water', 'Moderate Water'],
    growthForms: ['Shrub'],
    droughtTolerant: true,
    keyCharacteristics: ['Butterfly-Attracting Plant', 'Coastal Plant', 'Ornamental Flowers'],
  ),
  PlantDetail(
    name: 'Weeping Fig',
    scientificName: "Ficus benjamina 'Variegated White'",
    lightRequirements: ['Full Sun', 'Semi Shade'],
    waterRequirements: ['Moderate Water'],
    growthForms: ['Tree'],
    droughtTolerant: false,
    keyCharacteristics: ['Indoor Plant', 'Ornamental Leaves'],
  ),
  PlantDetail(
    name: 'Jerusalem Thorn',
    scientificName: 'Parkinsonia aculeata',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water'],
    growthForms: ['Tree'],
    droughtTolerant: true,
    keyCharacteristics: ['Butterfly-Attracting Plant', 'Fruit or Vegetable', 'Fragrant Plant'],
  ),
  PlantDetail(
    name: 'Spanish Dagger',
    scientificName: 'Yucca gloriosa',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water'],
    growthForms: ['Shrub'],
    droughtTolerant: true,
    keyCharacteristics: ['Ornamental Flowers', 'Ornamental Leaves'],
  ),
  PlantDetail(
    name: 'Norfolk Island Pine',
    scientificName: 'Araucaria heterophylla',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Little Water', 'Moderate Water'],
    growthForms: ['Tree'],
    droughtTolerant: false,
    keyCharacteristics: ['Coastal Plant', 'Indoor Plant', 'Ornamental Leaves'],
  ),
  PlantDetail(
    name: 'Common Fig',
    scientificName: 'Ficus carica',
    lightRequirements: ['Full Sun'],
    waterRequirements: ['Moderate Water'],
    growthForms: ['Shrub', 'Tree'],
    droughtTolerant: true,
    keyCharacteristics: ['Fruit or Vegetable'],
  ),
  PlantDetail(
    name: 'Emilia',
    scientificName: 'Emilia sonchifolia',
    lightRequirements: ['Full Sun', 'Semi Shade'],
    waterRequirements: ['Moderate Water'],
    growthForms: ['Shrub'],
    droughtTolerant: false,
    keyCharacteristics: ['Herb or Spice'],
  ),
];
