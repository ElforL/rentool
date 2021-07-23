import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({Key key, @required this.tool}) : super(key: key);
  final Tool tool;

  @override
  _NewRequestScreenState createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  TextEditingController _descriptionController;
  TextEditingController _daysController;
  String _descriptionErrorText;
  String _daysErrorText;

  int get daysNum => int.parse(_daysController.text);

  @override
  void initState() {
    _daysController = TextEditingController(text: '1');
    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request ${widget.tool.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Text.rich(TextSpan(
              text: 'Price: ',
              children: [
                TextSpan(text: 'SAR ${widget.tool.rentPrice}', style: TextStyle(color: Colors.blue)),
              ],
            )),
            SizedBox(height: 10),
            Text.rich(TextSpan(
              text: 'Insurance deposit: ',
              children: [
                TextSpan(text: 'SAR ${widget.tool.insuranceAmount}', style: TextStyle(color: Colors.blue)),
              ],
            )),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: 'Description',
                errorText: _descriptionErrorText,
              ),
              onChanged: (_) {
                if (_descriptionErrorText != null) {
                  _descriptionErrorText = null;
                  setState(() {});
                }
              },
            ),
            TextField(
              maxLength: 3,
              controller: _daysController,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Number of days',
                counterText: '',
                errorText: _daysErrorText,
              ),
              onChanged: (_) {
                if (_daysErrorText != null) _daysErrorText = null;
                setState(() {});
              },
            ),
            SizedBox(height: 25),
            Text.rich(TextSpan(
              text: 'Rent: ',
              children: [
                TextSpan(text: 'SAR ${_calcTotal()}', style: TextStyle(color: Colors.blue)),
              ],
            )),
            SizedBox(height: 10),
            Text.rich(TextSpan(
              text: 'Total with insurance: ',
              children: [
                TextSpan(text: 'SAR ${_calcTotal(true)}', style: TextStyle(color: Colors.blue)),
              ],
            )),
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    child: Text('CANCEL'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    child: Text('SEND'),
                    onPressed: () async {
                      if (_daysController.text.isEmpty) {
                        setState(() {
                          _daysErrorText = "You can't leave this empty";
                        });
                      } else if (daysNum == 0) {
                        setState(() {
                          _daysErrorText = "Days must be 1 or greater";
                        });
                      } else {
                        var request = ToolRequest(
                          null,
                          AuthServices.auth.currentUser.uid,
                          widget.tool.id,
                          _descriptionController.text,
                          daysNum,
                          widget.tool.rentPrice,
                          widget.tool.insuranceAmount,
                          false,
                          false,
                        );
                        await FirestoreServices.sendNewToolRequest(request, widget.tool.id);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _calcTotal([bool withInsurance = false]) {
    if (_daysController.text.isNotEmpty) {
      return widget.tool.rentPrice * daysNum + (withInsurance ? widget.tool.insuranceAmount : 0);
    }
    return 0;
  }
}
