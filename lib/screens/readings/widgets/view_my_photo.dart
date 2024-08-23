import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meter_reading/Database/controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class ViewMyPhoto extends StatefulWidget {
  const ViewMyPhoto({
    super.key,
    required this.path,
    required this.refNo,
    required this.fetchMeters,
  });
  final String path;
  final int refNo;
  final void Function() fetchMeters;

  @override
  State<ViewMyPhoto> createState() => _ViewMyPhotoState();
}

class _ViewMyPhotoState extends State<ViewMyPhoto> {
  late File imageFile;
  void updateTable(int refNo, String path) async {
    int result = await Controller()
        .updateImageField(refNo, path); // updateData(contactinfoModel);
    if (result > 0) {
      EasyLoading.showSuccess('Image updated successfuly!');
    } else {
      EasyLoading.showError('Image update failed!');
    }

    setState(() {});
    return;
  }

  Future<String> _saveImage(File imgFile, int name) async {
    final imgName = '$name.jpg';
    Directory appDir = await getApplicationDocumentsDirectory();

    final savePath = '${appDir.path}/$imgName';
    await imgFile.copy(savePath);
    updateTable(widget.refNo, savePath);
    widget.fetchMeters();
    EasyLoading.showSuccess('Image updated successfuly!');
    Navigator.pop(context);

    return savePath;
  }

  void deleteImage(int refNo, String path) async {
    int result = await Controller()
        .updateImageField(refNo, ''); // updateData(contactinfoModel);
    if (result > 0) {
      EasyLoading.showSuccess('Image deleted successfuly!');
    } else {
      EasyLoading.showError('Image delation failed!');
    }
    widget.fetchMeters();
    Navigator.pop(context);
  }

  Future<void> pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 96);
    if (pickedImage != null) {
      _saveImage(File(pickedImage.path), widget.refNo);

      setState(
        () {
          imageFile = File(pickedImage.path);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              SizedBox(
                child: PhotoView(
                  minScale: PhotoViewComputedScale.contained * 1,
                  maxScale: PhotoViewComputedScale.covered * 10,
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.white),
                  imageProvider: FileImage(File(widget.path)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: deviceSize.width * 0.35,
                        child: ElevatedButton(
                            onPressed: () {
                              pickImage();
                            },
                            child: const Text('Update')),
                      ),
                      SizedBox(
                        width: deviceSize.width * 0.35,
                        child: ElevatedButton(
                          onPressed: widget.path.isEmpty
                              ? null
                              : () {
                                  deleteImage(widget.refNo, widget.path);
                                },
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
