import 'package:flutter/material.dart';

class AppStrings {
  static const supportedLocales = [
    Locale('en'),
    Locale('ru'),
  ];

  static final Map<String, Map<String, String>> _values = {
    'en': {
      'home': 'Home',
      'favorites': 'Favorites',
      'post': 'Post',
      'chats': 'Chats',
      'profile': 'Profile',
      'searchListings': 'Search listings',
      'filter': 'Filter',
      'categories': 'Categories',
      'recommended': 'Recommended',
      'new': 'New',
      'results': 'Results',
      'clear': 'Clear',
      'retry': 'Retry',
      'seeAll': 'See all',
      'listingDetails': 'Listing details',
      'owner': 'Owner',
      'contact': 'Contact',
      'description': 'Description',
      'promoTitle': 'Instant cashback for top listings',
      'promoSubtitle': 'Limited time marketplace campaign',
      'noFavorites': 'No favorites yet',
      'noConversations': 'No conversations yet',
    },
    'ru': {
      'home': 'Главная',
      'favorites': 'Избранное',
      'post': 'Подать',
      'chats': 'Чаты',
      'profile': 'Профиль',
      'searchListings': 'Я ищу...',
      'filter': 'Фильтр',
      'categories': 'Категории',
      'recommended': 'Рекомендуемые',
      'new': 'Новые',
      'results': 'Результаты',
      'clear': 'Сброс',
      'retry': 'Повторить',
      'seeAll': 'Смотреть все',
      'listingDetails': 'Объявление',
      'owner': 'Продавец',
      'contact': 'Контакт',
      'description': 'Описание',
      'promoTitle': 'Мгновенный кешбэк для топ-объявлений',
      'promoSubtitle': 'Ограниченная акция маркетплейса',
      'noFavorites': 'Пока нет избранных',
      'noConversations': 'Пока нет чатов',
    },
  };

  static String of(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;
    return _values[lang]?[key] ?? _values['en']![key] ?? key;
  }
}
