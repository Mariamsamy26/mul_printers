import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import 'colors.dart';

var smallText = GoogleFonts.poppins();
var mediumText = GoogleFonts.poppins(fontWeight: FontWeight.w500);
var boldText = GoogleFonts.poppins(fontWeight: FontWeight.bold);

var receiptSmallText = GoogleFonts.poppins(fontSize: 13.sp);
var receiptmediumText = GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 18.sp);

var textBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20.r),
    borderSide: const BorderSide(
      color: Color(0xffD0D0CE),
    ));

var appBarStyle = GoogleFonts.dmSans(
  fontSize: 20.sp,
  color: goSmartBlue,
  fontWeight: FontWeight.w700,
);

//* BORDERS

var loginRegisterTextBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20.r),
    borderSide: const BorderSide(
      color: Color.fromRGBO(233, 239, 240, 1),
    ));
