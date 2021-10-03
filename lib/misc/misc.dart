import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A mailto link that create an email draft to [reportIssueEmailAddress] as a form for reporting an issue
///
/// **_Subject:_**
///
/// Issue report - [platform] (language code)
///
/// #### **_Body:_**
///
/// **Your name:**
///
/// **Describe the problem**
/// A clear and concise description of what's wrong.
///
/// **Expected fix**
/// Description of how you think we should fix the problem.
///
/// **Additional context**
/// Anything else we should know about the problem?"
///
/// **Attach screenshots/videos**
String issueReportFormMailtoLink(TargetPlatform platform, BuildContext context) {
  var platformString = platform.toString().replaceFirst('TargetPlatform.', '');
  platformString = platformString.replaceFirst(platformString[0], platformString[0].toUpperCase());

  var subject = 'Issue report - $platformString (${AppLocalizations.of(context)!.localeName})';

  final bodyParts = [
    AppLocalizations.of(context)!.issue_report_form_name,
    AppLocalizations.of(context)!.issue_report_form_description,
    AppLocalizations.of(context)!.issue_report_form_fix,
    AppLocalizations.of(context)!.issue_report_form_extra,
    AppLocalizations.of(context)!.issue_report_form_attachments,
  ];
  var body = '';
  for (var part in bodyParts) {
    body += '$part\n\n';
  }

  return "mailto:$reportIssueEmailAddress?subject=$subject&body=$body";
}

const reportIssueEmailAddress = 'issues.rentool@gmail.com';
