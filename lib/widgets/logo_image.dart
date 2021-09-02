import 'package:flutter/cupertino.dart';

class LogoImage extends Image {
  LogoImage.primary({Key? key}) : super.asset('assets/images/Logo/primary.png', key: key);
  LogoImage.primaryTypeface({Key? key}) : super.asset('assets/images/Logo/primary_typeface.png', key: key);
  LogoImage.primaryIcon({Key? key}) : super.asset('assets/images/Logo/primary_icon.png', key: key);

  LogoImage.black({Key? key}) : super.asset('assets/images/Logo/black.png', key: key);
  LogoImage.blackTypeface({Key? key}) : super.asset('assets/images/Logo/black_typeface.png', key: key);
  LogoImage.blackIcon({Key? key}) : super.asset('assets/images/Logo/black_icon.png', key: key);

  LogoImage.white({Key? key}) : super.asset('assets/images/Logo/white.png', key: key);
  LogoImage.whiteTypeface({Key? key}) : super.asset('assets/images/Logo/white_typeface.png', key: key);
  LogoImage.whiteIcon({Key? key}) : super.asset('assets/images/Logo/white_icon.png', key: key);
}
