/// Image paths from `puli-meka-game-android` (copied into `assets/`).
class GameAssets {
  GameAssets._();

  static const String images = 'assets/images';
  static const String icons = 'assets/icons';

  static const String playstoreIcon = '$images/playstore_icon.png';
  static const String tigerIcon = '$images/tiger_icon.png';
  static const String goatIcon = '$images/goat_icon.png';

  static const String tamilNaduBoard = '$images/tamil_nadu_board.png';
  static const String andhraPradeshBoard = '$images/andhra_pradesh_board.png';
  static const String karnatakaBoard = '$images/karnataka_board.png';
  static const String templeFloorBoard = '$images/temple_floor_board.png';
  static const String modernDigitalBoard = '$images/modern_digital_board.png';
  static const String baghChalBoard = '$images/bagh_chal_board.png';

  static const String tigerIconSvg = '$icons/tiger-icon.svg';
  static const String goatIconSvg = '$icons/goat-icon.svg';

  static const List<BoardGalleryItem> regionalBoards = [
    BoardGalleryItem(
      title: 'Tamil Nadu',
      subtitle: 'Aadu Puli Aatam style',
      assetPath: tamilNaduBoard,
    ),
    BoardGalleryItem(
      title: 'Andhra Pradesh',
      subtitle: 'Pulijudam style',
      assetPath: andhraPradeshBoard,
    ),
    BoardGalleryItem(
      title: 'Karnataka',
      subtitle: 'Huli Gatta style',
      assetPath: karnatakaBoard,
    ),
    BoardGalleryItem(
      title: 'Temple floor',
      subtitle: 'Traditional courtyard board',
      assetPath: templeFloorBoard,
    ),
    BoardGalleryItem(
      title: 'Modern digital',
      subtitle: 'App board layout',
      assetPath: modernDigitalBoard,
    ),
    BoardGalleryItem(
      title: 'Bagh Chal',
      subtitle: 'Nepal variant',
      assetPath: baghChalBoard,
    ),
  ];
}

class BoardGalleryItem {
  const BoardGalleryItem({
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });

  final String title;
  final String subtitle;
  final String assetPath;
}
