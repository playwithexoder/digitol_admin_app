enum PaperSize {
  a4('a4', 'A4'),
  a3('a3', 'A3'),
  legal('legal', 'Legal'),
  letter('letter', 'Letter'),
  foolscap('foolscap', 'Foolscap'),
  r4('4r', '4R (4x6")'),
  r5('5r', '5R (5x7")'),
  r6('6r', '6R (6x8")'),
  r8('8r', '8R (8x10")'),
  ;

  const PaperSize(this.value, this.label);
  final String value;
  final String label;
}

enum ColorMode {
  bw('bw', 'Black & White'),
  color('color', 'Color'),
  ;

  const ColorMode(this.value, this.label);
  final String value;
  final String label;
}

enum PrintSides {
  single('single', 'Single Side'),
  duplex('duplex', 'Double Side'),
  ;

  const PrintSides(this.value, this.label);
  final String value;
  final String label;
}

enum PrintOrientation {
  auto('auto', 'Auto'),
  portrait('portrait', 'Portrait'),
  landscape('landscape', 'Landscape'),
  ;

  const PrintOrientation(this.value, this.label);
  final String value;
  final String label;
}

enum Scaling {
  fillPage('fill_page', 'Fill page'),
  shrinkToFit('shrink_to_fit', 'Shrink to fit'),
  ;

  const Scaling(this.value, this.label);
  final String value;
  final String label;
}

enum PageMargins {
  normal('normal', 'Normal'),
  uniform('uniform', 'Uniform'),
  ;

  const PageMargins(this.value, this.label);
  final String value;
  final String label;
}

enum ImagesPerPage {
  one(1, '1'),
  two(2, '2'),
  four(4, '4'),
  nine(9, '9'),
  ;

  const ImagesPerPage(this.value, this.label);
  final int value;
  final String label;
}

enum ImageLayout {
  fullPage('full_page', 'Full Page (8x10 in)'),
  twoUp('two_up', 'Two Photos (5x7 in)'),
  fourUp('four_up', 'Four Photos (4x6 in) / 6 Passports'),
  nineUp('nine_up', '12 Passports / Sheet'),
  eightByTen('8x10_in', '8 x 10 in.'),
  fiveBySeven('5x7_in', '5 x 7 in.'),
  fourBySix('4x6_in', '4 x 6 in.'),
  hagaki('hagaki', '100 x 148 mm (Hagaki)'),
  threeHalfByFive('3.5x5_in', '3.5 x 5 in.'),
  twoByThreeWallet('2x3_wallet', '2 x 3 in. (Wallet)'),
  sixByEightWallet('6x8_cm_wallet', '6 x 8 cm (Wallet)'),
  ;

  const ImageLayout(this.value, this.label);
  final String value;
  final String label;
}
