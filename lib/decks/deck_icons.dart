import 'package:flutter/material.dart';

class DeckIconEntry {
  const DeckIconEntry({
    required this.key,
    required this.icon,
    required this.label,
    required this.keywords,
  });

  final String key;
  final IconData icon;
  final String label;
  final String keywords;

  bool matches(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return key.contains(needle) ||
        label.toLowerCase().contains(needle) ||
        keywords.contains(needle);
  }
}

const List<DeckIconEntry> deckIconRegistry = <DeckIconEntry>[
  DeckIconEntry(
    key: 'style',
    icon: Icons.style_rounded,
    label: 'Cards',
    keywords: 'cards deck flashcards general default',
  ),
  DeckIconEntry(
    key: 'school',
    icon: Icons.school_rounded,
    label: 'School',
    keywords: 'education study learning class student',
  ),
  DeckIconEntry(
    key: 'menu_book',
    icon: Icons.menu_book_rounded,
    label: 'Book',
    keywords: 'read reading library literature',
  ),
  DeckIconEntry(
    key: 'auto_stories',
    icon: Icons.auto_stories_rounded,
    label: 'Stories',
    keywords: 'story novel fiction reading tale',
  ),
  DeckIconEntry(
    key: 'library_books',
    icon: Icons.library_books_rounded,
    label: 'Library',
    keywords: 'books collection shelf',
  ),
  DeckIconEntry(
    key: 'edit_note',
    icon: Icons.edit_note_rounded,
    label: 'Notes',
    keywords: 'write notes writing edit',
  ),
  DeckIconEntry(
    key: 'history_edu',
    icon: Icons.history_edu_rounded,
    label: 'History scroll',
    keywords: 'history quill writing ancient',
  ),
  DeckIconEntry(
    key: 'quiz',
    icon: Icons.quiz_rounded,
    label: 'Quiz',
    keywords: 'test exam question practice',
  ),
  DeckIconEntry(
    key: 'lightbulb',
    icon: Icons.lightbulb_rounded,
    label: 'Idea',
    keywords: 'idea tip insight bright',
  ),
  DeckIconEntry(
    key: 'psychology',
    icon: Icons.psychology_rounded,
    label: 'Mind',
    keywords: 'brain psychology mind thinking memory',
  ),
  DeckIconEntry(
    key: 'science',
    icon: Icons.science_rounded,
    label: 'Science',
    keywords: 'chemistry lab flask experiment',
  ),
  DeckIconEntry(
    key: 'biotech',
    icon: Icons.biotech_rounded,
    label: 'Biotech',
    keywords: 'biology dna genetics microscope',
  ),
  DeckIconEntry(
    key: 'calculate',
    icon: Icons.calculate_rounded,
    label: 'Calculate',
    keywords: 'math maths arithmetic numbers',
  ),
  DeckIconEntry(
    key: 'functions',
    icon: Icons.functions_rounded,
    label: 'Functions',
    keywords: 'math algebra sigma formula',
  ),
  DeckIconEntry(
    key: 'numbers',
    icon: Icons.numbers_rounded,
    label: 'Numbers',
    keywords: 'digits counting figures',
  ),
  DeckIconEntry(
    key: 'pin',
    icon: Icons.pin_rounded,
    label: 'Pin numbers',
    keywords: 'number digits code',
  ),
  DeckIconEntry(
    key: 'format_list_numbered',
    icon: Icons.format_list_numbered_rounded,
    label: 'Ordered list',
    keywords: 'order sequence steps ranking',
  ),
  DeckIconEntry(
    key: 'straighten',
    icon: Icons.straighten_rounded,
    label: 'Ruler',
    keywords: 'measure length units size',
  ),
  DeckIconEntry(
    key: 'translate',
    icon: Icons.translate_rounded,
    label: 'Translate',
    keywords: 'language translation words vocabulary',
  ),
  DeckIconEntry(
    key: 'language',
    icon: Icons.language_rounded,
    label: 'Language',
    keywords: 'world web languages global',
  ),
  DeckIconEntry(
    key: 'abc',
    icon: Icons.abc_rounded,
    label: 'ABC',
    keywords: 'alphabet letters spelling grammar',
  ),
  DeckIconEntry(
    key: 'spellcheck',
    icon: Icons.spellcheck_rounded,
    label: 'Spelling',
    keywords: 'spell check grammar words',
  ),
  DeckIconEntry(
    key: 'public',
    icon: Icons.public_rounded,
    label: 'Globe',
    keywords: 'world earth countries geography',
  ),
  DeckIconEntry(
    key: 'map',
    icon: Icons.map_rounded,
    label: 'Map',
    keywords: 'geography atlas places location',
  ),
  DeckIconEntry(
    key: 'explore',
    icon: Icons.explore_rounded,
    label: 'Compass',
    keywords: 'explore direction navigation',
  ),
  DeckIconEntry(
    key: 'travel_explore',
    icon: Icons.travel_explore_rounded,
    label: 'Travel',
    keywords: 'travel search world trip',
  ),
  DeckIconEntry(
    key: 'terrain',
    icon: Icons.terrain_rounded,
    label: 'Mountains',
    keywords: 'mountain geography landscape',
  ),
  DeckIconEntry(
    key: 'landscape',
    icon: Icons.landscape_rounded,
    label: 'Landscape',
    keywords: 'scenery nature view',
  ),
  DeckIconEntry(
    key: 'park',
    icon: Icons.park_rounded,
    label: 'Park',
    keywords: 'tree nature outdoors garden',
  ),
  DeckIconEntry(
    key: 'forest',
    icon: Icons.forest_rounded,
    label: 'Forest',
    keywords: 'trees woods nature',
  ),
  DeckIconEntry(
    key: 'eco',
    icon: Icons.eco_rounded,
    label: 'Eco',
    keywords: 'leaf environment green plant',
  ),
  DeckIconEntry(
    key: 'pets',
    icon: Icons.pets_rounded,
    label: 'Pets',
    keywords: 'animal dog cat paw',
  ),
  DeckIconEntry(
    key: 'water_drop',
    icon: Icons.water_drop_rounded,
    label: 'Water',
    keywords: 'drop liquid ocean rain',
  ),
  DeckIconEntry(
    key: 'air',
    icon: Icons.air_rounded,
    label: 'Air',
    keywords: 'wind breeze weather',
  ),
  DeckIconEntry(
    key: 'bolt',
    icon: Icons.bolt_rounded,
    label: 'Bolt',
    keywords: 'electric energy lightning power fast',
  ),
  DeckIconEntry(
    key: 'local_fire_department',
    icon: Icons.local_fire_department_rounded,
    label: 'Fire',
    keywords: 'flame heat burn',
  ),
  DeckIconEntry(
    key: 'ac_unit',
    icon: Icons.ac_unit_rounded,
    label: 'Snow',
    keywords: 'winter cold ice snowflake',
  ),
  DeckIconEntry(
    key: 'wb_sunny',
    icon: Icons.wb_sunny_rounded,
    label: 'Sun',
    keywords: 'sunny day weather light',
  ),
  DeckIconEntry(
    key: 'nightlight',
    icon: Icons.nightlight_rounded,
    label: 'Night',
    keywords: 'moon dark evening',
  ),
  DeckIconEntry(
    key: 'cloud',
    icon: Icons.cloud_rounded,
    label: 'Cloud',
    keywords: 'weather sky',
  ),
  DeckIconEntry(
    key: 'thunderstorm',
    icon: Icons.thunderstorm_rounded,
    label: 'Storm',
    keywords: 'weather lightning rain',
  ),
  DeckIconEntry(
    key: 'sailing',
    icon: Icons.sailing_rounded,
    label: 'Sailing',
    keywords: 'boat sea ship water',
  ),
  DeckIconEntry(
    key: 'flight',
    icon: Icons.flight_rounded,
    label: 'Flight',
    keywords: 'plane airplane travel airport',
  ),
  DeckIconEntry(
    key: 'directions_car',
    icon: Icons.directions_car_rounded,
    label: 'Car',
    keywords: 'drive vehicle road traffic',
  ),
  DeckIconEntry(
    key: 'directions_bus',
    icon: Icons.directions_bus_rounded,
    label: 'Bus',
    keywords: 'transport public commute',
  ),
  DeckIconEntry(
    key: 'train',
    icon: Icons.train_rounded,
    label: 'Train',
    keywords: 'rail transport station',
  ),
  DeckIconEntry(
    key: 'pedal_bike',
    icon: Icons.pedal_bike_rounded,
    label: 'Bike',
    keywords: 'bicycle cycling ride',
  ),
  DeckIconEntry(
    key: 'directions_run',
    icon: Icons.directions_run_rounded,
    label: 'Running',
    keywords: 'run sport jog exercise',
  ),
  DeckIconEntry(
    key: 'hiking',
    icon: Icons.hiking_rounded,
    label: 'Hiking',
    keywords: 'walk trail outdoors trek',
  ),
  DeckIconEntry(
    key: 'sports_soccer',
    icon: Icons.sports_soccer_rounded,
    label: 'Football',
    keywords: 'soccer sport ball game',
  ),
  DeckIconEntry(
    key: 'sports_basketball',
    icon: Icons.sports_basketball_rounded,
    label: 'Basketball',
    keywords: 'sport ball game',
  ),
  DeckIconEntry(
    key: 'sports_tennis',
    icon: Icons.sports_tennis_rounded,
    label: 'Tennis',
    keywords: 'sport racket ball',
  ),
  DeckIconEntry(
    key: 'sports_esports',
    icon: Icons.sports_esports_rounded,
    label: 'Gaming',
    keywords: 'games controller esports play',
  ),
  DeckIconEntry(
    key: 'fitness_center',
    icon: Icons.fitness_center_rounded,
    label: 'Fitness',
    keywords: 'gym workout weights exercise',
  ),
  DeckIconEntry(
    key: 'self_improvement',
    icon: Icons.self_improvement_rounded,
    label: 'Meditation',
    keywords: 'calm mindfulness yoga relax',
  ),
  DeckIconEntry(
    key: 'spa',
    icon: Icons.spa_rounded,
    label: 'Spa',
    keywords: 'relax wellness plant calm',
  ),
  DeckIconEntry(
    key: 'restaurant',
    icon: Icons.restaurant_rounded,
    label: 'Restaurant',
    keywords: 'food dining meal cooking',
  ),
  DeckIconEntry(
    key: 'local_cafe',
    icon: Icons.local_cafe_rounded,
    label: 'Coffee',
    keywords: 'cafe tea drink cup',
  ),
  DeckIconEntry(
    key: 'cake',
    icon: Icons.cake_rounded,
    label: 'Cake',
    keywords: 'birthday dessert celebration sweet',
  ),
  DeckIconEntry(
    key: 'bakery_dining',
    icon: Icons.bakery_dining_rounded,
    label: 'Bakery',
    keywords: 'bread baking pastry',
  ),
  DeckIconEntry(
    key: 'local_pizza',
    icon: Icons.local_pizza_rounded,
    label: 'Pizza',
    keywords: 'food italian slice',
  ),
  DeckIconEntry(
    key: 'fastfood',
    icon: Icons.fastfood_rounded,
    label: 'Fast food',
    keywords: 'burger snack meal',
  ),
  DeckIconEntry(
    key: 'icecream',
    icon: Icons.icecream_rounded,
    label: 'Ice cream',
    keywords: 'dessert sweet cold',
  ),
  DeckIconEntry(
    key: 'wine_bar',
    icon: Icons.wine_bar_rounded,
    label: 'Wine',
    keywords: 'drink glass bar',
  ),
  DeckIconEntry(
    key: 'music_note',
    icon: Icons.music_note_rounded,
    label: 'Music',
    keywords: 'song note melody sound',
  ),
  DeckIconEntry(
    key: 'piano',
    icon: Icons.piano_rounded,
    label: 'Piano',
    keywords: 'keys instrument music',
  ),
  DeckIconEntry(
    key: 'headphones',
    icon: Icons.headphones_rounded,
    label: 'Headphones',
    keywords: 'listen audio music podcast',
  ),
  DeckIconEntry(
    key: 'mic',
    icon: Icons.mic_rounded,
    label: 'Microphone',
    keywords: 'voice speak record singing',
  ),
  DeckIconEntry(
    key: 'album',
    icon: Icons.album_rounded,
    label: 'Album',
    keywords: 'record vinyl disc music',
  ),
  DeckIconEntry(
    key: 'movie',
    icon: Icons.movie_rounded,
    label: 'Movies',
    keywords: 'film cinema video',
  ),
  DeckIconEntry(
    key: 'theaters',
    icon: Icons.theaters_rounded,
    label: 'Theater',
    keywords: 'cinema drama film stage',
  ),
  DeckIconEntry(
    key: 'camera_alt',
    icon: Icons.camera_alt_rounded,
    label: 'Camera',
    keywords: 'photo photography picture',
  ),
  DeckIconEntry(
    key: 'palette',
    icon: Icons.palette_rounded,
    label: 'Palette',
    keywords: 'art colors paint design',
  ),
  DeckIconEntry(
    key: 'brush',
    icon: Icons.brush_rounded,
    label: 'Brush',
    keywords: 'paint art draw',
  ),
  DeckIconEntry(
    key: 'draw',
    icon: Icons.draw_rounded,
    label: 'Draw',
    keywords: 'sketch pen art',
  ),
  DeckIconEntry(
    key: 'architecture',
    icon: Icons.architecture_rounded,
    label: 'Architecture',
    keywords: 'building design drafting',
  ),
  DeckIconEntry(
    key: 'engineering',
    icon: Icons.engineering_rounded,
    label: 'Engineering',
    keywords: 'work tools technical helmet',
  ),
  DeckIconEntry(
    key: 'code',
    icon: Icons.code_rounded,
    label: 'Code',
    keywords: 'programming developer software',
  ),
  DeckIconEntry(
    key: 'terminal',
    icon: Icons.terminal_rounded,
    label: 'Terminal',
    keywords: 'command line shell programming linux',
  ),
  DeckIconEntry(
    key: 'computer',
    icon: Icons.computer_rounded,
    label: 'Computer',
    keywords: 'desktop pc technology',
  ),
  DeckIconEntry(
    key: 'phone_android',
    icon: Icons.phone_android_rounded,
    label: 'Phone',
    keywords: 'mobile android device',
  ),
  DeckIconEntry(
    key: 'memory',
    icon: Icons.memory_rounded,
    label: 'Chip',
    keywords: 'hardware cpu electronics',
  ),
  DeckIconEntry(
    key: 'storage',
    icon: Icons.storage_rounded,
    label: 'Storage',
    keywords: 'database server disk',
  ),
  DeckIconEntry(
    key: 'security',
    icon: Icons.security_rounded,
    label: 'Security',
    keywords: 'shield protection safe',
  ),
  DeckIconEntry(
    key: 'lock',
    icon: Icons.lock_rounded,
    label: 'Lock',
    keywords: 'secure private password',
  ),
  DeckIconEntry(
    key: 'key',
    icon: Icons.key_rounded,
    label: 'Key',
    keywords: 'access password unlock',
  ),
  DeckIconEntry(
    key: 'wifi',
    icon: Icons.wifi_rounded,
    label: 'Wi-Fi',
    keywords: 'network internet wireless',
  ),
  DeckIconEntry(
    key: 'satellite_alt',
    icon: Icons.satellite_alt_rounded,
    label: 'Satellite',
    keywords: 'space orbit signal',
  ),
  DeckIconEntry(
    key: 'rocket_launch',
    icon: Icons.rocket_launch_rounded,
    label: 'Rocket',
    keywords: 'space launch startup',
  ),
  DeckIconEntry(
    key: 'smart_toy',
    icon: Icons.smart_toy_rounded,
    label: 'Robot',
    keywords: 'ai bot machine',
  ),
  DeckIconEntry(
    key: 'hub',
    icon: Icons.hub_rounded,
    label: 'Network',
    keywords: 'graph nodes connection',
  ),
  DeckIconEntry(
    key: 'extension',
    icon: Icons.extension_rounded,
    label: 'Puzzle',
    keywords: 'plugin piece game',
  ),
  DeckIconEntry(
    key: 'casino',
    icon: Icons.casino_rounded,
    label: 'Dice',
    keywords: 'game chance random',
  ),
  DeckIconEntry(
    key: 'videogame_asset',
    icon: Icons.videogame_asset_rounded,
    label: 'Video game',
    keywords: 'gaming controller play',
  ),
  DeckIconEntry(
    key: 'emoji_events',
    icon: Icons.emoji_events_rounded,
    label: 'Trophy',
    keywords: 'win award champion prize',
  ),
  DeckIconEntry(
    key: 'emoji_emotions',
    icon: Icons.emoji_emotions_rounded,
    label: 'Smile',
    keywords: 'emoji happy face fun',
  ),
  DeckIconEntry(
    key: 'star',
    icon: Icons.star_rounded,
    label: 'Star',
    keywords: 'favorite rating best',
  ),
  DeckIconEntry(
    key: 'favorite',
    icon: Icons.favorite_rounded,
    label: 'Heart',
    keywords: 'love like favorite',
  ),
  DeckIconEntry(
    key: 'diamond',
    icon: Icons.diamond_rounded,
    label: 'Diamond',
    keywords: 'gem jewel precious',
  ),
  DeckIconEntry(
    key: 'workspace_premium',
    icon: Icons.workspace_premium_rounded,
    label: 'Medal',
    keywords: 'badge premium award certificate',
  ),
  DeckIconEntry(
    key: 'flag',
    icon: Icons.flag_rounded,
    label: 'Flag',
    keywords: 'country goal mark',
  ),
  DeckIconEntry(
    key: 'bookmark',
    icon: Icons.bookmark_rounded,
    label: 'Bookmark',
    keywords: 'save mark read later',
  ),
  DeckIconEntry(
    key: 'label',
    icon: Icons.label_rounded,
    label: 'Label',
    keywords: 'tag category',
  ),
  DeckIconEntry(
    key: 'category',
    icon: Icons.category_rounded,
    label: 'Category',
    keywords: 'group shapes sort',
  ),
  DeckIconEntry(
    key: 'bubble_chart',
    icon: Icons.bubble_chart_rounded,
    label: 'Bubbles',
    keywords: 'chart data circles',
  ),
  DeckIconEntry(
    key: 'dashboard_customize',
    icon: Icons.dashboard_customize_rounded,
    label: 'Dashboard',
    keywords: 'layout widgets custom',
  ),
  DeckIconEntry(
    key: 'health_and_safety',
    icon: Icons.health_and_safety_rounded,
    label: 'Health',
    keywords: 'safety medical shield',
  ),
  DeckIconEntry(
    key: 'medical_services',
    icon: Icons.medical_services_rounded,
    label: 'Medical',
    keywords: 'doctor medicine first aid',
  ),
  DeckIconEntry(
    key: 'medication',
    icon: Icons.medication_rounded,
    label: 'Medication',
    keywords: 'pills medicine drug pharmacy',
  ),
  DeckIconEntry(
    key: 'vaccines',
    icon: Icons.vaccines_rounded,
    label: 'Vaccine',
    keywords: 'injection medicine needle',
  ),
  DeckIconEntry(
    key: 'monitor_heart',
    icon: Icons.monitor_heart_rounded,
    label: 'Heart rate',
    keywords: 'health pulse cardio',
  ),
  DeckIconEntry(
    key: 'child_care',
    icon: Icons.child_care_rounded,
    label: 'Kids',
    keywords: 'child baby family',
  ),
  DeckIconEntry(
    key: 'family_restroom',
    icon: Icons.family_restroom_rounded,
    label: 'Family',
    keywords: 'parents children people',
  ),
  DeckIconEntry(
    key: 'groups',
    icon: Icons.groups_rounded,
    label: 'Groups',
    keywords: 'people team community',
  ),
  DeckIconEntry(
    key: 'person',
    icon: Icons.person_rounded,
    label: 'Person',
    keywords: 'people user profile',
  ),
  DeckIconEntry(
    key: 'face',
    icon: Icons.face_rounded,
    label: 'Face',
    keywords: 'person people portrait',
  ),
  DeckIconEntry(
    key: 'handshake',
    icon: Icons.handshake_rounded,
    label: 'Handshake',
    keywords: 'deal agreement help friends',
  ),
  DeckIconEntry(
    key: 'home',
    icon: Icons.home_rounded,
    label: 'Home',
    keywords: 'house living place',
  ),
  DeckIconEntry(
    key: 'apartment',
    icon: Icons.apartment_rounded,
    label: 'Apartment',
    keywords: 'building city flat',
  ),
  DeckIconEntry(
    key: 'business',
    icon: Icons.business_rounded,
    label: 'Business',
    keywords: 'company office work',
  ),
  DeckIconEntry(
    key: 'work',
    icon: Icons.work_rounded,
    label: 'Work',
    keywords: 'job career briefcase',
  ),
  DeckIconEntry(
    key: 'payments',
    icon: Icons.payments_rounded,
    label: 'Payments',
    keywords: 'money cash pay finance',
  ),
  DeckIconEntry(
    key: 'savings',
    icon: Icons.savings_rounded,
    label: 'Savings',
    keywords: 'money piggy bank finance',
  ),
  DeckIconEntry(
    key: 'account_balance',
    icon: Icons.account_balance_rounded,
    label: 'Bank',
    keywords: 'finance economy government law',
  ),
  DeckIconEntry(
    key: 'shopping_cart',
    icon: Icons.shopping_cart_rounded,
    label: 'Shopping',
    keywords: 'store buy cart retail',
  ),
  DeckIconEntry(
    key: 'gavel',
    icon: Icons.gavel_rounded,
    label: 'Law',
    keywords: 'court judge legal justice',
  ),
  DeckIconEntry(
    key: 'balance',
    icon: Icons.balance_rounded,
    label: 'Balance',
    keywords: 'scales justice law',
  ),
  DeckIconEntry(
    key: 'history',
    icon: Icons.history_rounded,
    label: 'History',
    keywords: 'past time clock',
  ),
  DeckIconEntry(
    key: 'schedule',
    icon: Icons.schedule_rounded,
    label: 'Clock',
    keywords: 'time hours schedule',
  ),
  DeckIconEntry(
    key: 'calendar_month',
    icon: Icons.calendar_month_rounded,
    label: 'Calendar',
    keywords: 'months dates schedule',
  ),
  DeckIconEntry(
    key: 'event',
    icon: Icons.event_rounded,
    label: 'Event',
    keywords: 'date appointment calendar',
  ),
  DeckIconEntry(
    key: 'today',
    icon: Icons.today_rounded,
    label: 'Today',
    keywords: 'day date calendar',
  ),
  DeckIconEntry(
    key: 'timer',
    icon: Icons.timer_rounded,
    label: 'Timer',
    keywords: 'stopwatch countdown time',
  ),
  DeckIconEntry(
    key: 'alarm',
    icon: Icons.alarm_rounded,
    label: 'Alarm',
    keywords: 'clock wake time',
  ),
  DeckIconEntry(
    key: 'hourglass_empty',
    icon: Icons.hourglass_empty_rounded,
    label: 'Hourglass',
    keywords: 'time wait sand',
  ),
  DeckIconEntry(
    key: 'search',
    icon: Icons.search_rounded,
    label: 'Search',
    keywords: 'find look magnifier',
  ),
  DeckIconEntry(
    key: 'download',
    icon: Icons.download_rounded,
    label: 'Download',
    keywords: 'import save arrow',
  ),
];

final Map<String, DeckIconEntry> _deckIconsByKey = <String, DeckIconEntry>{
  for (final DeckIconEntry entry in deckIconRegistry) entry.key: entry,
};

IconData iconForDeckKey(String key) {
  return _deckIconsByKey[key]?.icon ?? Icons.style_rounded;
}

List<DeckIconEntry> searchDeckIcons(String query) {
  return deckIconRegistry
      .where((DeckIconEntry entry) => entry.matches(query))
      .toList();
}
