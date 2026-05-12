class LocationService {
  // 简化版本：只提供手动输入经纬度的功能
  // 自动定位功能因 geolocator 包与当前 Flutter 版本不兼容而暂时移除

  String generateMapUrl(double latitude, double longitude, String name) {
    // 生成高德地图链接
    return 'https://uri.amap.com/marker?position=$longitude,$latitude&name=$name';
  }

  bool isValidLatitude(double? lat) {
    if (lat == null) return false;
    return lat >= -90 && lat <= 90;
  }

  bool isValidLongitude(double? lng) {
    if (lng == null) return false;
    return lng >= -180 && lng <= 180;
  }
}
