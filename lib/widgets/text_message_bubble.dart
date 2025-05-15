import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../../models/message_model.dart';

class TextMessageBubble extends StatelessWidget {
  final MessageModel message;
  final BorderRadiusGeometry borderRadius;
  final bool isSender;

  const TextMessageBubble({
    super.key,
    required this.message,
    required this.borderRadius,
    required this.isSender,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final Color textColor = isSender
        ? Colors.white
        : (isDark ? Colors.white : Colors.black);

    final BoxDecoration bubbleDecoration = isSender
        ? BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.purple.shade400, Colors.purple.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: borderRadius,
    )
        : BoxDecoration(
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
      borderRadius: borderRadius,
    );

    // ✅ اختيار الخط حسب النظام
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final TextStyle baseStyle = isIOS
        ? TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      color: textColor,
      height: 1.2,
      fontFamily: isIOS ? '.SF UI Text' : 'NotoSansArabic',
      fontFamilyFallback: ['NotoColorEmoji'],
    )
        : GoogleFonts.notoSansArabic(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textColor,
      height: 1.2,
    ).copyWith(
      fontFamily: isIOS ? '.SF UI Text' : 'NotoSansArabic',
      fontFamilyFallback: ['NotoColorEmoji'],
    );

    return Container(
      decoration: bubbleDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      child: _buildRichText(message.content, baseStyle),
    );
  }

  Widget _buildRichText(String text, TextStyle baseStyle) {
    final emojiRegex = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff]|\ud83e[\udd00-\udfff])',
    );

    final spans = <InlineSpan>[];
    final characters = text.characters;

    for (final char in characters) {
      final isEmoji = emojiRegex.hasMatch(char);
      spans.add(TextSpan(
        text: char,
        style: baseStyle.copyWith(
          fontSize: isEmoji
              ? (baseStyle.fontSize! + 3)
              : baseStyle.fontSize,
        ),
      ));
    }

    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    final textAlign = isArabic ? TextAlign.right : TextAlign.left;

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}
