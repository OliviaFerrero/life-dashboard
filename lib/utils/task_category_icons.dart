import 'package:flutter/material.dart';

class TaskCategoryIconOption {
  final String key;
  final IconData icon;

  const TaskCategoryIconOption({
    required this.key,
    required this.icon,
  });
}

const taskCategoryIconOptions = [
  // Generiche
  TaskCategoryIconOption(
    key: 'label_outline',
    icon: Icons.label_outline,
  ),
  TaskCategoryIconOption(
    key: 'star_border',
    icon: Icons.star_border,
  ),
  TaskCategoryIconOption(
    key: 'favorite_border',
    icon: Icons.favorite_border,
  ),
  TaskCategoryIconOption(
    key: 'bookmark_border',
    icon: Icons.bookmark_border,
  ),
  TaskCategoryIconOption(
    key: 'check_circle_outline',
    icon: Icons.check_circle_outline,
  ),
  TaskCategoryIconOption(
    key: 'lightbulb_outline',
    icon: Icons.lightbulb_outline,
  ),

  // Persona / relazioni
  TaskCategoryIconOption(
    key: 'person_outline',
    icon: Icons.person_outline,
  ),
  TaskCategoryIconOption(
    key: 'groups_outlined',
    icon: Icons.groups_outlined,
  ),
  TaskCategoryIconOption(
    key: 'family_restroom_outlined',
    icon: Icons.family_restroom_outlined,
  ),
  TaskCategoryIconOption(
    key: 'child_care_outlined',
    icon: Icons.child_care_outlined,
  ),
  TaskCategoryIconOption(
    key: 'pets_outlined',
    icon: Icons.pets_outlined,
  ),
  TaskCategoryIconOption(
    key: 'celebration_outlined',
    icon: Icons.celebration_outlined,
  ),

  // Lavoro / studio
  TaskCategoryIconOption(
    key: 'work_outline',
    icon: Icons.work_outline,
  ),
  TaskCategoryIconOption(
    key: 'business_center_outlined',
    icon: Icons.business_center_outlined,
  ),
  TaskCategoryIconOption(
    key: 'computer_outlined',
    icon: Icons.computer_outlined,
  ),
  TaskCategoryIconOption(
    key: 'engineering_outlined',
    icon: Icons.engineering_outlined,
  ),
  TaskCategoryIconOption(
    key: 'science_outlined',
    icon: Icons.science_outlined,
  ),
  TaskCategoryIconOption(
    key: 'school_outlined',
    icon: Icons.school_outlined,
  ),
  TaskCategoryIconOption(
    key: 'menu_book_outlined',
    icon: Icons.menu_book_outlined,
  ),
  TaskCategoryIconOption(
    key: 'edit_note_outlined',
    icon: Icons.edit_note_outlined,
  ),
  TaskCategoryIconOption(
    key: 'description_outlined',
    icon: Icons.description_outlined,
  ),
  TaskCategoryIconOption(
    key: 'language_outlined',
    icon: Icons.language_outlined,
  ),

  // Salute / sport
  TaskCategoryIconOption(
    key: 'medical_services_outlined',
    icon: Icons.medical_services_outlined,
  ),
  TaskCategoryIconOption(
    key: 'local_hospital_outlined',
    icon: Icons.local_hospital_outlined,
  ),
  TaskCategoryIconOption(
    key: 'medication_outlined',
    icon: Icons.medication_outlined,
  ),
  TaskCategoryIconOption(
    key: 'fitness_center_outlined',
    icon: Icons.fitness_center_outlined,
  ),
  TaskCategoryIconOption(
    key: 'directions_run_outlined',
    icon: Icons.directions_run_outlined,
  ),
  TaskCategoryIconOption(
    key: 'sports_soccer_outlined',
    icon: Icons.sports_soccer_outlined,
  ),
  TaskCategoryIconOption(
    key: 'sports_tennis_outlined',
    icon: Icons.sports_tennis_outlined,
  ),
  TaskCategoryIconOption(
    key: 'pool_outlined',
    icon: Icons.pool_outlined,
  ),
  TaskCategoryIconOption(
    key: 'hiking_outlined',
    icon: Icons.hiking_outlined,
  ),
  TaskCategoryIconOption(
    key: 'self_improvement_outlined',
    icon: Icons.self_improvement_outlined,
  ),

  // Casa
  TaskCategoryIconOption(
    key: 'home_outlined',
    icon: Icons.home_outlined,
  ),
  TaskCategoryIconOption(
    key: 'chair_outlined',
    icon: Icons.chair_outlined,
  ),
  TaskCategoryIconOption(
    key: 'bed_outlined',
    icon: Icons.bed_outlined,
  ),
  TaskCategoryIconOption(
    key: 'kitchen_outlined',
    icon: Icons.kitchen_outlined,
  ),
  TaskCategoryIconOption(
    key: 'cleaning_services_outlined',
    icon: Icons.cleaning_services_outlined,
  ),
  TaskCategoryIconOption(
    key: 'build_outlined',
    icon: Icons.build_outlined,
  ),
  TaskCategoryIconOption(
    key: 'inventory_2_outlined',
    icon: Icons.inventory_2_outlined,
  ),
  TaskCategoryIconOption(
    key: 'yard_outlined',
    icon: Icons.yard_outlined,
  ),

  // Commissioni / spese
  TaskCategoryIconOption(
    key: 'shopping_cart_outlined',
    icon: Icons.shopping_cart_outlined,
  ),
  TaskCategoryIconOption(
    key: 'shopping_bag_outlined',
    icon: Icons.shopping_bag_outlined,
  ),
  TaskCategoryIconOption(
    key: 'local_grocery_store_outlined',
    icon: Icons.local_grocery_store_outlined,
  ),
  TaskCategoryIconOption(
    key: 'payments_outlined',
    icon: Icons.payments_outlined,
  ),
  TaskCategoryIconOption(
    key: 'savings_outlined',
    icon: Icons.savings_outlined,
  ),
  TaskCategoryIconOption(
    key: 'receipt_long_outlined',
    icon: Icons.receipt_long_outlined,
  ),
  TaskCategoryIconOption(
    key: 'account_balance_wallet_outlined',
    icon: Icons.account_balance_wallet_outlined,
  ),

  // Cibo / locali
  TaskCategoryIconOption(
    key: 'restaurant_outlined',
    icon: Icons.restaurant_outlined,
  ),
  TaskCategoryIconOption(
    key: 'local_cafe_outlined',
    icon: Icons.local_cafe_outlined,
  ),
  TaskCategoryIconOption(
    key: 'cake_outlined',
    icon: Icons.cake_outlined,
  ),
  TaskCategoryIconOption(
    key: 'local_dining_outlined',
    icon: Icons.local_dining_outlined,
  ),

  // Viaggi / trasporti
  TaskCategoryIconOption(
    key: 'directions_car_outlined',
    icon: Icons.directions_car_outlined,
  ),
  TaskCategoryIconOption(
    key: 'flight_outlined',
    icon: Icons.flight_outlined,
  ),
  TaskCategoryIconOption(
    key: 'train_outlined',
    icon: Icons.train_outlined,
  ),
  TaskCategoryIconOption(
    key: 'directions_bus_outlined',
    icon: Icons.directions_bus_outlined,
  ),
  TaskCategoryIconOption(
    key: 'directions_bike_outlined',
    icon: Icons.directions_bike_outlined,
  ),
  TaskCategoryIconOption(
    key: 'map_outlined',
    icon: Icons.map_outlined,
  ),
  TaskCategoryIconOption(
    key: 'place_outlined',
    icon: Icons.place_outlined,
  ),
  TaskCategoryIconOption(
    key: 'luggage_outlined',
    icon: Icons.luggage_outlined,
  ),

  // Tempo / organizzazione
  TaskCategoryIconOption(
    key: 'calendar_month_outlined',
    icon: Icons.calendar_month_outlined,
  ),
  TaskCategoryIconOption(
    key: 'event_outlined',
    icon: Icons.event_outlined,
  ),
  TaskCategoryIconOption(
    key: 'schedule_outlined',
    icon: Icons.schedule_outlined,
  ),
  TaskCategoryIconOption(
    key: 'alarm_outlined',
    icon: Icons.alarm_outlined,
  ),
  TaskCategoryIconOption(
    key: 'timer_outlined',
    icon: Icons.timer_outlined,
  ),
  TaskCategoryIconOption(
    key: 'event_repeat_outlined',
    icon: Icons.event_repeat_outlined,
  ),

  // Comunicazione
  TaskCategoryIconOption(
    key: 'phone_outlined',
    icon: Icons.phone_outlined,
  ),
  TaskCategoryIconOption(
    key: 'mail_outline',
    icon: Icons.mail_outline,
  ),
  TaskCategoryIconOption(
    key: 'chat_bubble_outline',
    icon: Icons.chat_bubble_outline,
  ),
  TaskCategoryIconOption(
    key: 'videocam_outlined',
    icon: Icons.videocam_outlined,
  ),

  // Hobby / creatività
  TaskCategoryIconOption(
    key: 'sports_esports_outlined',
    icon: Icons.sports_esports_outlined,
  ),
  TaskCategoryIconOption(
    key: 'palette_outlined',
    icon: Icons.palette_outlined,
  ),
  TaskCategoryIconOption(
    key: 'music_note_outlined',
    icon: Icons.music_note_outlined,
  ),
  TaskCategoryIconOption(
    key: 'movie_outlined',
    icon: Icons.movie_outlined,
  ),
  TaskCategoryIconOption(
    key: 'photo_camera_outlined',
    icon: Icons.photo_camera_outlined,
  ),
  TaskCategoryIconOption(
    key: 'park_outlined',
    icon: Icons.park_outlined,
  ),
  TaskCategoryIconOption(
    key: 'print_outlined',
    icon: Icons.print_outlined,
  ),

  // Digitale / utility
  TaskCategoryIconOption(
    key: 'smartphone_outlined',
    icon: Icons.smartphone_outlined,
  ),
  TaskCategoryIconOption(
    key: 'wifi_outlined',
    icon: Icons.wifi_outlined,
  ),
  TaskCategoryIconOption(
    key: 'cloud_outlined',
    icon: Icons.cloud_outlined,
  ),
  TaskCategoryIconOption(
    key: 'settings_outlined',
    icon: Icons.settings_outlined,
  ),
  TaskCategoryIconOption(
    key: 'lock_outline',
    icon: Icons.lock_outline,
  ),
];

IconData taskCategoryIcon(
  String iconKey,
) {
  for (final option
      in taskCategoryIconOptions) {
    if (option.key == iconKey) {
      return option.icon;
    }
  }

  return Icons.label_outline;
}
