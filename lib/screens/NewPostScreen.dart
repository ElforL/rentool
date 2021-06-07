import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class NewPostScreen extends StatelessWidget {
  NewPostScreen({Key key}) : super(key: key);

  final _nameContoller = TextEditingController();
  final _descriptionContoller = TextEditingController();
  final _priceContoller = TextEditingController();
  final _insuranceContoller = TextEditingController();
  final _locationContoller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: ListView(
          children: [
            SizedBox(height: 10),
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
            // media
            MediaTile(),

            // location
            _buildTextField(
              controller: _locationContoller,
              labelText: 'City/Location',
              textInputAction: TextInputAction.done,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
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
    TextEditingController controller,
    String labelText,
    TextInputAction textInputAction,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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

class MediaTile extends StatefulWidget {
  const MediaTile({Key key}) : super(key: key);

  @override
  _MediaTileState createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile> {
  List _images = [];
  final picker = ImagePicker();

  Future _getMedia(bool isImage, ImageSource source) async {
    final pickedFile = isImage ? await picker.getImage(source: source) : await picker.getVideo(source: source);

    setState(() {
      if (pickedFile != null) {
        _images.add(File(pickedFile.path));
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == _images.length) return _buildAddTile();
          return _buildImageHolder(_images[index]);
        },
      ),
    );
  }

  Widget _buildAddTile() {
    return Container(
      color: Colors.black38,
      width: 200,
      // child: Icon(Icons.add),
      child: PopupMenuButton(
        child: Icon(Icons.add),
        offset: Offset(50, 0),
        tooltip: 'Add media',
        itemBuilder: (BuildContext context) => [
          PopupMenuWidget(
            padding: EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.videocam),
                  tooltip: 'Video',
                  onPressed: null, //TODO () => getMedia(false, ImageSource.camera),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt_outlined),
                  tooltip: 'Photo',
                  onPressed: () => _getMedia(true, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHolder(File image) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Image.file(
        image,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// A `PopupMenuEntry` that is not pressable.
///
/// Useful for placing buttons or plain text in it.
class PopupMenuWidget<T> extends PopupMenuEntry<T> {
  const PopupMenuWidget({
    Key key,
    this.height,
    this.child,
    this.padding = const EdgeInsets.all(0),
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  final double height;

  @override
  _PopupMenuWidgetState createState() => new _PopupMenuWidgetState();

  @override
  bool represents(T value) {
    throw UnimplementedError();
  }
}

class _PopupMenuWidgetState extends State<PopupMenuWidget> {
  @override
  Widget build(BuildContext context) => Padding(padding: widget.padding, child: widget.child);
}
