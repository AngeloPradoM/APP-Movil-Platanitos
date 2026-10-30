class StoreLocation {
  const StoreLocation({
    required this.name,
    required this.district,
    required this.address,
    required this.hours,
  });
  final String name, district, address, hours;
}

class BlogArticle {
  const BlogArticle({
    required this.title,
    required this.category,
    required this.summary,
    required this.body,
    required this.image,
    required this.readMinutes,
  });
  final String title, category, summary, body, image;
  final int readMinutes;
}
