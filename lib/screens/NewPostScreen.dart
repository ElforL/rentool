import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/PopupMenuWidget.dart';
import 'package:video_player/video_player.dart';

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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    child: Text('CREATE'),
                    onPressed: () async {
                      if (_nameContoller.text.trim().isEmpty ||
                          _descriptionContoller.text.trim().isEmpty ||
                          _priceContoller.text.trim().isEmpty ||
                          _insuranceContoller.text.trim().isEmpty ||
                          _locationContoller.text.trim().isEmpty) {
                        print('Missing fields');
                        return;
                      }
                      await FirestoreServices.createNewTool(
                        _nameContoller.text,
                        _descriptionContoller.text,
                        double.parse(_priceContoller.text.trim()),
                        double.parse(_insuranceContoller.text.trim()),
                        [],
                        _locationContoller.text,
                      );
                      Navigator.pop(context);
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
  List _vids = [];
  final picker = ImagePicker();
  List<VideoPlayerController> _contollers = [];

  Future _getMedia(bool isImage, ImageSource source) async {
    final pickedFile = isImage ? await picker.getImage(source: source) : await picker.getVideo(source: source);

    setState(() {
      if (pickedFile != null) {
        if (isImage)
          _images.add(File(pickedFile.path));
        else
          _vids.add(File(pickedFile.path));
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  void dispose() {
    _contollers.forEach((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length + _vids.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == _images.length + _vids.length) return _buildAddTile();
          if (index < _images.length) return _buildImageHolder(_images[index]);
          return _buildVideoHolder(_vids[index - _images.length]);
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
                  onPressed: () => _getMedia(false, ImageSource.gallery),
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

  Widget _buildVideoHolder(File video) {
    var _controller = kIsWeb ? VideoPlayerController.network(video.path) : VideoPlayerController.file(video);
    _contollers.add(_controller);

    return FutureBuilder(
      future: _controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          _buildLoadingTile();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AspectRatio(
            aspectRatio: _controller.value.size.width / _controller.value.size.height,
            child: Stack(
              children: [
                VideoPlayer(_controller),
                Icon(
                  Icons.videocam,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageHolder(File image) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Stack(
        children: [
          if (kIsWeb)
            Image.network(
              image.path,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) =>
                  loadingProgress == null ? child : _buildLoadingTile(loadingProgress),
            )
          else
            Image.file(
              image,
              fit: BoxFit.contain,
            ),
          Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  // color: Colors.,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.photo,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTile([ImageChunkEvent loadingProgress]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        color: Colors.black38,
        width: 200,
        child: Center(
          child: CircularProgressIndicator(
            value: loadingProgress == null
                ? null
                : loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes,
          ),
        ),
      ),
    );
  }
}
