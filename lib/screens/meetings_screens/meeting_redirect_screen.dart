import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/deliver_meetings.dart';
import 'package:rentool/screens/card_verification_screen.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/big_icons.dart';

class MeetingRedirectScreen extends StatefulWidget {
  const MeetingRedirectScreen({Key? key, required this.meeting}) : super(key: key);

  final DeliverMeeting meeting;

  @override
  State<MeetingRedirectScreen> createState() => _MeetingRedirectScreenState();
}

class _MeetingRedirectScreenState extends State<MeetingRedirectScreen> {
  DocumentSnapshot<Object?>? doc;
  bool? isSuccess;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.your_action_required),
            FutureBuilder(
              future: doc == null ? FirestoreServices.getDeliverMeetingPrivateDoc(widget.meeting) : Future.value(doc),
              builder: (context, AsyncSnapshot<DocumentSnapshot<Object?>?> snapshot) {
                if (snapshot.hasError) {
                  print(AppLocalizations.of(context)!.error + ': ' + snapshot.error.toString());
                  return Center(
                    child: BigIcon(
                      icon: Icons.error,
                      caption: AppLocalizations.of(context)!.unexpected_error_occured,
                    ),
                  );
                }

                doc = snapshot.data;
                if (doc == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (doc is DocumentSnapshot<Map?>) {
                  final data = doc!.data() as Map?;

                  if (data?['type'] == 'redirect') {
                    final String link = data!['link'];
                    if (isSuccess == null) {
                      Future.microtask(() async {
                        final value = await Navigator.push<CardVerificationScreenResult?>(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return CardVerificationScreen(
                                url: link,
                                sucessUrlStart: 'https://rentool.site/payment/success',
                                errorUrlStart: 'https://rentool.site/payment/error',
                              );
                            },
                          ),
                        );
                        setState(() => isSuccess = value?.success);
                      });
                    }

                    var result = isSuccess == null
                        ? AppLocalizations.of(context)!.require_3ds_waiting
                        : isSuccess!
                            ? AppLocalizations.of(context)!.verification_successful
                            : AppLocalizations.of(context)!.verification_failed;

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(result),
                          if (isSuccess == null)
                            ElevatedButton(
                              child: Text(AppLocalizations.of(context)!.submit),
                              onPressed: () async {
                                final value = await Navigator.push<bool?>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return CardVerificationScreen(
                                        url: link,
                                        sucessUrlStart: 'https://rentool.site/payment/success',
                                        errorUrlStart: 'https://rentool.site/payment/error',
                                      );
                                    },
                                  ),
                                );
                                setState(() => isSuccess = value);
                              },
                            ),
                        ],
                      ),
                    );
                  }
                }

                return SingleChildScrollView(
                  child: Center(
                    child: Text(doc!.data().toString()),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
