import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
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

  final List<File> media = [];

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
            // location
            _buildTextField(
              controller: _locationContoller,
              labelText: 'City/Location',
              textInputAction: TextInputAction.done,
            ),

            // media
            MediaTile(
              media: media,
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
                        media,
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
  const MediaTile({Key key, @required this.media}) : super(key: key);

  final List<File> media;

  @override
  _MediaTileState createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile> {
  final picker = ImagePicker();
  List<VideoPlayerController> _contollers = [];

  Future _getMedia(MediaInput inputType) async {
    try {
      var res;
      if (inputType == MediaInput.gallery) {
        res = await FilePicker.platform.pickFiles(
          type: FileType.media,
          allowMultiple: true,
        );
      } else {
        res = inputType == MediaInput.cameraVideo
            ? await picker.getVideo(source: ImageSource.camera)
            : await picker.getImage(source: ImageSource.camera);
      }

      if (res != null) {
        List<File> files;
        if (res.runtimeType == FilePickerResult)
          files = (res as FilePickerResult).paths.map((path) => File(path)).toList();
        else
          files = [File(res.path)];
        _addMedia(files);
      } else {
        print('No files were selected.');
      }
    } on PlatformException catch (e) {
      if (e.code == 'read_external_storage_denied') {
        print('Storage read denied');
        _showStorageDeniedDialog();
      } else {
        rethrow;
      }
    }
  }

  /// add [files] to `widget.media` and rebuilds the widget.
  _addMedia(Iterable<File> files) {
    setState(() {
      widget.media.addAll(files);
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('files added'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _removeMedia(files);
                });
              },
            ),
          ),
        );
      } catch (e) {}
    });
  }

  /// removes [files] from the `widget.media`.
  _removeMedia(files) {
    for (var file in files) {
      widget.media.remove(file);
    }
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
        itemCount: widget.media.length + 1,
        itemBuilder: (BuildContext context, int i) {
          var index = i - 1;
          if (i == 0) return _buildAddTile();
          var type = lookupMimeType(widget.media[index].path).split('/')[0];
          if (type == 'image') {
            return _buildImageHolder(widget.media[index]);
          } else if (type == 'video') {
            return _buildVideoHolder(widget.media[index]);
          } else {
            throw Exception('Media type is not an image nor a video: $type, index: $index.');
          }
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.photo_library),
                  tooltip: 'Pick from gallery',
                  onPressed: () {
                    Navigator.pop(context);
                    _getMedia(MediaInput.gallery);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.videocam),
                  tooltip: 'Take video',
                  onPressed: () {
                    Navigator.pop(context);
                    _getMedia(MediaInput.cameraVideo);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt_outlined),
                  tooltip: 'Take photo',
                  onPressed: () {
                    Navigator.pop(context);
                    _getMedia(MediaInput.cameraImage);
                  },
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
          return _buildLoadingTile();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AspectRatio(
            aspectRatio: _controller.value.size.width / _controller.value.size.height,
            child: Stack(
              children: [
                VideoPlayer(_controller),
                _buildIconOnFog(Icons.videocam),
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
          _buildIconOnFog(Icons.photo),
        ],
      ),
    );
  }

  Widget _buildIconOnFog(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white70,
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

  _showStorageDeniedDialog() {
    var dialog = AlertDialog(
      title: Column(
        children: [
          Icon(Icons.folder),
          Text('Storage permission denied'),
        ],
      ),
      content: Text(
        "The app was denied access to the gallery. To allow the app to upload media from your device, it needs to have access to the device storage.\n\n"
        "You can give access if a permission dialog pops up, or in the app settings.",
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
      ],
    );
    showDialog(context: context, builder: (_) => dialog);
  }
}

enum MediaInput {
  cameraVideo,
  cameraImage,
  gallery,
}
