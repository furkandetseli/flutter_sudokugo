import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ContactScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and text scale factor
    final screenSize = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isLargeDevice = screenSize.width > 400;

    // Calculate responsive font sizes
    final double titleFontSize = (isLargeDevice ? 24.0 : 20.0) / textScaleFactor;
    final double contentFontSize = (isLargeDevice ? 18.0 : 16.0) / textScaleFactor;

    // Calculate responsive spacing
    final double verticalSpacing = screenSize.height * 0.02;
    final double sectionSpacing = screenSize.height * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.contact,
          style: TextStyle(
            fontSize: titleFontSize * 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 600, // Maximum width for large screens
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.05,
                vertical: screenSize.height * 0.03,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Contact Section
                  Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: verticalSpacing),
                  SelectableText(
                    'furkandetseli0@gmail.com',
                    style: TextStyle(
                      fontSize: contentFontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sectionSpacing),

                  // Special Thank You Section
                  Text(
                    'Special Thank You',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: verticalSpacing),
                  _buildThankYouName('Deniz Ekin Ünsal', contentFontSize),
                  SizedBox(height: verticalSpacing * 0.5),
                  _buildThankYouName('Ahmet Detseli', contentFontSize),
                  SizedBox(height: verticalSpacing * 0.5),
                  _buildThankYouName('Oğulcan Yılmaz', contentFontSize),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThankYouName(String name, double fontSize) {
    return Text(
      name,
      style: TextStyle(fontSize: fontSize),
      textAlign: TextAlign.center,
    );
  }
}