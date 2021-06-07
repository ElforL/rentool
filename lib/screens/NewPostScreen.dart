import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewPostScreen extends StatelessWidget {
  NewPostScreen({Key key}) : super(key: key);

  var _nameContoller = TextEditingController();
  var _descriptionContoller = TextEditingController();
  var _priceContoller = TextEditingController();
  var _insuranceContoller = TextEditingController();
  var _locationContoller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            // name
            _buildTextField(
              controller: _nameContoller,
              labelText: 'Tool name',
              textInputAction: TextInputAction.next,
            ),
            // description
            _buildTextField(
              controller: _descriptionContoller,
              labelText: 'Description',
              textInputAction: TextInputAction.next,
            ),
            // rentPrice
            _buildTextField(
              controller: _priceContoller,
              labelText: 'Price',
              textInputAction: TextInputAction.next,
              isNumber: true,
            ),
            // insuranceAmount
            _buildTextField(
              controller: _insuranceContoller,
              labelText: 'Insurance Price',
              textInputAction: TextInputAction.next,
              isNumber: true,
            ),
            // TODO media
            ListTile(
              title: Text('*TODO*: MEDIA GOES HERE'),
            ),

            // location
            _buildTextField(
              controller: _locationContoller,
              labelText: 'City/Location',
              textInputAction: TextInputAction.next,
            ),

            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    child: Text('CANCEL'),
                    onPressed: () {},
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    child: Text('CREATE'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    controller,
    labelText,
    textInputAction,
    isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        textInputAction: textInputAction,
        keyboardType: isNumber ? TextInputType.number : null,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
