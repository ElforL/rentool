class CityLocalization {
  /// Return a string of the [city]'s name in the language with the code [langCode]
  static String cityName(String city, String langCode) {
    return _json[city]?[langCode] ?? city;
  }

  /// Return a map of the cities for the language of [langCode].
  static Map<String, String> cities(String langCode) {
    return _json.map<String, String>((cityCode, value) => MapEntry(cityCode, value[langCode] ?? ''));
  }

  static bool hasCity(String city) => _json[city] != null;
}

/// A map of the cities as:
/// cityCode: {
///   'en': name_in_english
///   'ar': name_in_arabic
/// }
const _json = {
  'riyadh': {'en': 'Riyadh', 'ar': 'الرياض'},
  'jeddah': {'en': 'Jeddah', 'ar': 'جدة'},
  'makkah': {'en': 'Makkah', 'ar': 'مكة المكرمة'},
  'medina': {'en': 'Medina', 'ar': 'المدينة المنورة'},
  'al-ahsa': {'en': 'Al-Ahsa', 'ar': 'الأحساء'},
  'dammam': {'en': 'Dammam', 'ar': 'الدمام'},
  'taif': {'en': 'Taif', 'ar': 'الطائف'},
  'buraidah': {'en': 'Buraidah', 'ar': 'بريدة'},
  'tabuk': {'en': 'Tabuk', 'ar': 'تبوك'},
  'qatif': {'en': 'Qatif', 'ar': 'القطيف'},
  'khamis_mushayt': {'en': 'Khamis Mushayt', 'ar': 'خميس مشيط'},
  'khobar': {'en': 'Khobar', 'ar': 'الخبر'},
  'hafar_al_Batin': {'en': 'Hafar al-Batin', 'ar': 'حفر الباطن'},
  'jubail': {'en': 'Jubail', 'ar': 'الجبيل'},
  'kharj': {'en': 'Kharj', 'ar': 'الخرج'},
  'abha': {'en': 'Abha', 'ar': 'أبها'},
  'hail': {'en': 'Haʼil', 'ar': 'حائل'},
  'najran': {'en': 'Najran', 'ar': 'نجران'},
  'yanbu': {'en': 'Yanbu', 'ar': 'ينبع'},
  'sabya': {'en': 'Sabya', 'ar': 'صبيا'},
  'dawadmi': {'en': 'Dawadmi', 'ar': 'الدوادمي'},
  'bisha': {'en': 'Bisha', 'ar': 'بيشة'},
  'abu_arish': {'en': 'Abu Arish', 'ar': 'أبو عريش'},
  'al_qunfudhah': {'en': 'Al Qunfudhah', 'ar': 'القنفذة'},
  'muhayil': {'en': 'Muhayil', 'ar': 'محايل'},
  'sakakah': {'en': 'Sakakah', 'ar': 'سكاكا'},
  'arar': {'en': 'Arar', 'ar': 'عرعر'},
  'unaizah': {'en': 'Unaizah', 'ar': 'عنيزة'},
  'qurayyat': {'en': 'Qurayyat', 'ar': 'القريات'},
  'samtah': {'en': 'Samtah', 'ar': 'صامطة'},
  'jazan': {'en': 'Jazan', 'ar': 'جازان'},
  'al_majmaah': {'en': "Al Majma'ah", 'ar': 'المجمعة'},
  'al-quwayiyah': {'en': "Al-Quway'iyah", 'ar': 'القويعية'},
  'ar_rass': {'en': 'Ar Rass', 'ar': 'الرس'},
  'wadi_ad_dawasir': {'en': 'Wadi ad-Dawasir', 'ar': 'وادي الدواسر'},
  'bahrah': {'en': 'Bahrah', 'ar': 'بحرة'},
  'al_bahah': {'en': 'Al Bahah', 'ar': 'الباحة'},
  'al_jumum': {'en': 'Al Jumum', 'ar': 'الجموم'},
  'rabigh': {'en': 'Rabigh', 'ar': 'رابغ'},
  'ahad_rafidah': {'en': 'Ahad Rafidah', 'ar': 'أحد رفيدة'},
  'sharurah': {'en': 'Sharurah', 'ar': 'شرورة'},
  'al_lith': {'en': 'Al Lith', 'ar': 'الليث'},
  'rafha': {'en': 'Rafha', 'ar': 'رفحاء'},
  'afif': {'en': 'Afif', 'ar': 'عفيف'},
  'al_aridhah': {'en': 'Al Aridhah', 'ar': 'العارضة'},
  'al-khafji': {'en': 'Al-Khafji', 'ar': 'الخفجي'},
  'balqarn': {'en': 'Balqarn', 'ar': 'بلقرن'},
  'damad': {'en': 'Damad', 'ar': 'ضمد'},
  'tubarjal': {'en': 'Tubarjal', 'ar': 'طبرجل'},
  'baish': {'en': 'Baish', 'ar': 'بيش'},
  'az_zulfi': {'en': 'Az Zulfi', 'ar': 'الزلفي'},
  'ad_darb': {'en': 'Ad Darb', 'ar': 'الدرب'},
  'al-aflaj': {'en': 'Al-Aflaj', 'ar': 'الافلاج'},
  'sarat_abidah': {'en': 'Sarat Abidah', 'ar': 'سراة عبيدة'},
  'rijal_almaa': {'en': 'Rijal Almaa', 'ar': 'رجال المع'},
  'baljurashi': {'en': 'Baljurashi', 'ar': 'بلجرشي'},
  'al_hait': {'en': 'Al Hait', 'ar': 'الحائط'},
  'maysaan': {'en': 'Maysaan', 'ar': 'ميسان'},
  'badr': {'en': 'Badr', 'ar': 'بدر'},
  'umluj': {'en': 'Umluj', 'ar': 'أملج'},
  'ras_tanura': {'en': 'Ras Tanura', 'ar': 'رأس تنورة'},
  'al_dayer': {'en': 'Al Dayer', 'ar': 'الدائر'},
  'al_bukayriyah': {'en': 'Al Bukayriyah', 'ar': 'البكيرية'},
  'al_badayea': {'en': 'Al Badayea', 'ar': 'البدائع'},
  'khulais': {'en': 'Khulais', 'ar': 'خليص'},
  'al_hinakiyah': {'en': 'Al Hinakiyah', 'ar': 'الحناكية'},
  'al-ula': {'en': 'Al-Ula', 'ar': 'العلا'},
  'al_tuwal': {'en': 'Al Tuwal', 'ar': 'الطوال'},
  'al_namas': {'en': 'Al Namas', 'ar': 'النماص'},
  'al_majaridah': {'en': 'Al Majaridah', 'ar': 'المجاردة'},
  'buqayq': {'en': 'Buqayq', 'ar': 'بقيق'},
  'tathlith': {'en': 'Tathlith', 'ar': 'تثليث'},
  'al_makhwah': {'en': 'Al Makhwah', 'ar': 'المخواة'},
  'al_nairyah': {'en': 'Al Nairyah', 'ar': 'النعيرية'},
  'al_wajh': {'en': 'Al Wajh', 'ar': 'الوجه'},
  'duba': {'en': 'Duba', 'ar': 'ضباء'},
  'bareq': {'en': 'Bareq', 'ar': 'بارق'},
  'turaif': {'en': 'Turaif', 'ar': 'طريف'},
  'khaybar': {'en': 'Khaybar', 'ar': 'خيبر'},
  'adham': {'en': 'Adham', 'ar': 'أضم'},
  'al_nabhaniyah': {'en': 'Al Nabhaniyah', 'ar': 'النبهانية'},
  'ranyah': {'en': 'Ranyah', 'ar': 'رنية'},
  'dumat_al-jandal': {'en': 'Dumat al-Jandal', 'ar': 'دومة الجندل'},
  'al_mithnab': {'en': 'Al Mithnab', 'ar': 'المذنب'},
  'turubah': {'en': 'Turubah', 'ar': 'تربة'},
  'howtat_bani_tamim': {'en': 'Howtat Bani Tamim', 'ar': 'حوطة بني تميم'},
  'al_khurma': {'en': 'Al Khurma', 'ar': 'الخرمة'},
  'qilwah': {'en': 'Qilwah', 'ar': 'قلوة'},
  'shaqra': {'en': 'Shaqra', 'ar': 'شقراء'},
  'al_muwayh': {'en': 'Al Muwayh', 'ar': 'المويه'},
  'al_asyah': {'en': 'Al Asyah', 'ar': 'الأسياح'},
  'baqaa': {'en': 'Baqaa', 'ar': 'بقعاء'},
  'as_sulayyil': {'en': 'As Sulayyil', 'ar': 'السليل'},
  'tayma': {'en': 'Tayma', 'ar': 'تيماء'}
};
