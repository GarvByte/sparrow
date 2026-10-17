import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String imageUrl;
  final int? tmdbGenreId;
  final Color accentColor;

  const CategoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imageUrl,
    this.tmdbGenreId,
    this.accentColor = const Color(0xFF10E871),
  });

  static const List<CategoryItem> defaultCategories = [
    CategoryItem(
      id: 'cyberpunk',
      title: 'Cyberpunk & Sci-Fi',
      subtitle: 'AI, Distopia, Neon World',
      icon: Icons.psychology_outlined,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD6E8werGzvv5a004fwbawbPzqmhdq9Tt38dZwZ84mg929bJhiZZGjQ27h9qNCdlaex5IsYNFOxLnkCepDndzSkOoOVZ08TuiREUb6J6KCTsK7ibVDTONM4UlwCXh0cXTRNxgYRL9vR2f6d3fAyYqlLiLtmA2zLYXZqHhR5aw90tMPDAax3wniuuRJ04w3NBRO_1w0WLHURbCYDaQhPUbuABKOOVKRDQRseOOJGNXbL6Lvt8nFwK_Dtgg',
      tmdbGenreId: 878, // Science Fiction
      accentColor: Color(0xFF10E871),
    ),
    CategoryItem(
      id: 'action',
      title: 'Action & Adrenaline',
      subtitle: 'Heists, Martial Arts, Fury',
      icon: Icons.bolt_rounded,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuADl4qHS0vFe93aBeZmBBjd8934FBt3laPtLZYj9E2PKPP1YSkA7QwgqFlas0Z_5G3fTReNVKLE6KVEDFLYaGclHIrhyFLYYaQYLd_D6y54j2yCsKPRmrRfzzU0soPUtF1HRBjgswFWpxoz8gVIDLZduKTqAzgL0ZNc3_CbFylZKTVo5S34VUqzl-egLFJW6qj1KgvSMk2bo9qTqirh55yrzoT2YPh9qK0qd6Rt_4Dlcem8Axpmft7CKg',
      tmdbGenreId: 28, // Action
      accentColor: Color.fromARGB(255, 255, 101, 101),
    ),
    CategoryItem(
      id: 'thriller',
      title: 'Psychological Thriller',
      subtitle: 'Mind-benders & Noir',
      icon: Icons.psychology_rounded,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAypdjIzSMl3VIXC6-okOzowx_-Lz6x2iUqboAgu6rUzLT3GhFWDq9lE67BH5_h4WvCEBXuXJk--hletNDQAxzFs8GW5VcC0vdlX8wpS8KtQwCbM-W5g-YurT_B56pw-TwwE6Kdps0XSl5UXX9_u7Fxfvd2WLZSVe6prNbAUjV0ad86KuYCYavok-uVnjF_M3vlpl8k9rmH-UeVMBJ5TAg32GcmMNayK9_qMF6UwqmvJUBcEmE2xxBcGg',
      tmdbGenreId: 53, // Thriller
      accentColor: Color.fromARGB(255, 159, 168, 255),
    ),
    CategoryItem(
      id: 'anime',
      title: 'Animation & Disney',
      subtitle: 'Fantasy, Pixar',
      icon: Icons.sports_kabaddi_rounded,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAeTdEFyDKGkDeK_WR7jhBaH3Vi8Gc0hHMavXhBaqvBb7yjGF3VWmG8RpCWFVZsivst8sYyeUwUK-8sFN4B_TVCE-OFjDuKQgVcrbYX8UMTX_AK3Ri9Fzh_kC0nUmk29-24DgC5_eI2jctdVECT80IEO05jnSbX7_3dM38btR3JAND56SEUp4LyLH3RbUcb2-Y2q1lW_w00z-OrZnOI5YUboUxVDSkntjKJ7srVD9Z0_lhH3UklMlxk5A',
      tmdbGenreId: 16, // Animation
      accentColor: Color.fromRGBO(0, 179, 255, 1),
    ),
    CategoryItem(
      id: 'cosmic',
      title: 'Mystery Odysseys',
      subtitle: 'Mystery unveils and thrillers',
      icon: Icons.public_rounded,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCyaZp5YzURfh3p8tg94Qpo4f4Lt3isQ-lGU2Ty8R63UupmHAfp5o0P5xjpJI8cZLYbabUg9bgxw7OHdj5oESQKyIFDgmM0K2IoSqv9YzwgvOJ15QKPNCoyFtssYdV1GH7SZOEu85WfYKXRs9hxDd9E8BDjsFiBhTNhUIAC1UpT0O91ODoVWybxyjTjQOKsyCVpE8z16i8u0NgtvrAaz6fFcebgVn3LhuZ1HJ7paf1ka4PXvjRf90lVBQ',
      tmdbGenreId: 9648, // Science Fiction
      accentColor: Color.fromARGB(255, 232, 228, 16),
    ),
    CategoryItem(
      id: 'family',
      title: 'Family',
      subtitle: 'Pure family-friendly entertainment',
      icon: Icons.verified_rounded,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAgjEP-7uDPId-LeXLEyF4wGRPGrek0oDtb0wohw8KoJsHsk1ye4ITkfE9AOEQs5NeyL_isKkiqIdzdzBsgM-ZaCnnnLkUYXtdQE0uB-VfLJvmNbpoUklXwRuDdONyEDXsIN0m-Hbh-zLCcPZ3QDcDPkTNiMrVJy9uS4WSRjHzVtCPj_L3RUGJbnBoUf6xBQtzvyJitJRPpB4JPKQoXnFTYLjXe17v1VmD-ZYjDw4kV8nqrW2sJyRXKJg',
      tmdbGenreId: 10751, // Editorial / Top-rated
      accentColor: Color.fromARGB(255, 232, 16, 232),
    ),
  ];
}
