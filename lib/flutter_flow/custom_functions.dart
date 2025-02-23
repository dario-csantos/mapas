import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/supabase/supabase.dart';

List<LatLng> converteStringLatLng(List<String> strings) {
  List<LatLng> latLngList = [];

  for (String s in strings) {
    final match = RegExp(r'LatLng\(lat: (.*), lng: (.*)\)').firstMatch(s);
    if (match != null) {
      double lat = double.parse(match.group(1)!);
      double lng = double.parse(match.group(2)!);
      latLngList.add(LatLng(lat, lng));
    }
  }

  return latLngList;
}
