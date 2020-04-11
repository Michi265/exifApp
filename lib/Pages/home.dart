import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:exif/exif.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';


class Home extends StatefulWidget {

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future _future;

  File _image;
  List<File> listImg= new List(5);
  Map<String, IfdTag> imgTags;

  double finalAngle = 0.0;
  double offsetAngle = 0.0;
  double _scale = 1.0;
  double _previousScale = 1.0;

  var latitudeValue;
  var latitudeSignal;

  var longitudeValue;
  var longitudeSignal;

  var latitude;
  var longitude;

  var index = 0;
  var selectedIndex = 0;

  var _imgLocation;
  bool _imgHasLocation;

  CameraController controller;

  @override
  initState() {
    super.initState();
    initCam();
  }

  initCam() async {

    var cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    await controller.initialize();
    setState(() {});
  }

  Future onCameraCapture() async {

    await ImagePicker.pickImage(source: ImageSource.camera).then((image) {
      setState(() {
        if(index<4) {
          listImg[index] = image;
          _future = getExifFromFile(image);
          index++;
        }else{
          listImg[4] = image;
          _future = getExifFromFile(image);
        }
        _image = image;
        finalAngle = 0.0;
        _scale = 1.0;
        selectedIndex = index-1;
      });
    });
  }

  Future getImage() async {

    await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
      setState(() {
        if(index<4) {
          listImg[index] = image;
          _future = getExifFromFile(image);
          index++;
        }else{
          listImg[4] = image;
          _future = getExifFromFile(image);
        }
        _image = image;
        finalAngle = 0.0;
        _scale = 1.0;
        selectedIndex = index-1;
      });
    });
  }

  Future<String> getExifFromFile(File image) async {

    if (image == null) {
      return null;
    }
    Map<String, IfdTag> imgTags = await readExifFromBytes(
        File(image.path).readAsBytesSync());

    if (imgTags.containsKey('GPS GPSLongitude')) {
      setState(() {
        _imgHasLocation = true;
        _imgLocation = exifGPSToGeoFirePoint(imgTags);
      });
    }

    var bytes = await image.readAsBytes();
    var tags = await readExifFromBytes(bytes);
    var sb = StringBuffer();
    print(bytes);
    print(tags);
    tags.forEach((k, v) {
      sb.write("$k: $v \n");
    });
    return sb.toString();
  }

  GeoFirePoint exifGPSToGeoFirePoint(Map<String, IfdTag> tags) {

    latitudeValue = tags['GPS GPSLatitude'].values.map<double>( (item) => (item.numerator.toDouble() / item.denominator.toDouble()) ).toList();
    latitudeSignal = tags['GPS GPSLatitudeRef'].printable;

    longitudeValue = tags['GPS GPSLongitude'].values.map<double>( (item) => (item.numerator.toDouble() / item.denominator.toDouble()) ).toList();
    longitudeSignal = tags['GPS GPSLongitudeRef'].printable;

    latitude = latitudeValue[0]
        + (latitudeValue[1] / 60)
        + (latitudeValue[2] / 3600);

    longitude = longitudeValue[0]
        + (longitudeValue[1] / 60)
        + (longitudeValue[2] / 3600);

    if (latitudeSignal == 'S') latitude = -latitude;
    if (longitudeSignal == 'W') longitude = -longitude;

    return  GeoFirePoint(latitude, longitude);
  }

  Future<void> openMap(LinkableElement link) async {

    imgTags = await readExifFromBytes(File(_image.path).readAsBytesSync());
    /*
    if ((imgTags['GPS GPSLatitude']) != null) {

      final latitudeValue = imgTags['GPS GPSLatitude'].values.map<double>((item)
      => (item.numerator.toDouble() / item.denominator.toDouble())).toList();

      final latitudeSignal = imgTags['GPS GPSLatitudeRef'].printable;

      final longitudeValue = imgTags['GPS GPSLongitude'].values.map<double>((item)
      => (item.numerator.toDouble() / item.denominator.toDouble())).toList();

      final longitudeSignal = imgTags['GPS GPSLongitudeRef'].printable;

      latitude = latitudeValue[0]
          + (latitudeValue[1] / 60)
          + (latitudeValue[2] / 3600);

      longitude = longitudeValue[0]
          + (longitudeValue[1] / 60)
          + (longitudeValue[2] / 3600);

      if (latitudeSignal == 'S') latitude = -latitude;
      if (longitudeSignal == 'W') longitude = -longitude;
*/
     if (imgTags['GPS GPSLatitude'] == null) {

      latitude = null;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20.0)),
            child: Container(
              height: 150,
              width: 200.0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'This image not have latitude and longitude data!'),
                    ),
                    SizedBox(
                      width: 50.0,
                      child: RaisedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Column(
                          children: <Widget>[
                            Align(
                                alignment: Alignment.bottomCenter,
                                child: Icon(Icons.check, color: Colors.white)
                            ),
                          ],
                        ),
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else if (await canLaunch(link.url)) {
      await launch(link.url);
    }
  }

  deleteImage(){

    setState(() {
      for(int i = selectedIndex; i<=4; i++){
        if(i+1==5 || listImg[i+1]==null){
          listImg[i] = null;
        }else{
          listImg[i] = listImg[i+1];
        }
      }
      index --;
      if(index<0){
        index=0;
      }
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Exif Viewer Image'),
      ),

      body:ListView(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.only(top: 200),
            child: Transform.rotate(
              angle: finalAngle,
              origin: Offset(0, 0),
              child: SizedOverflowBox(
                size: Size(40.0, 110.0),
                child: Container(
                  height: 512.0,
                  color: Colors.grey[200],
                  child:GestureDetector(
                    onScaleStart: (ScaleStartDetails details){
                      print(details);
                      _previousScale = _scale;
                      setState(() {});
                    },
                    onScaleUpdate: (ScaleUpdateDetails details){
                      print(details);
                      _scale = _previousScale * details.scale;
                      setState(() {});
                    },
                    onScaleEnd: (ScaleEndDetails details){
                      print(details);
                      _previousScale = 1.0;
                      setState(() {});
                    },
                    child: SizedBox(
                      child:ClipRect(
                        child: Transform(
                          alignment: FractionalOffset.center,
                          transform: Matrix4.diagonal3(Vector3(_scale,_scale,_scale)),
                          child: _image == null ? Text('No image selected.',style: TextStyle( color:Colors.black,),textAlign: TextAlign.center)
                              : Image.file(_image)
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              child: Icon(Icons.delete),
              onPressed: deleteImage,
              backgroundColor: Colors.red[800],
            ),
          ),
          GestureDetector(
            onPanStart: (details) {},
            onPanEnd: (details) {},
            onPanUpdate: (details) {
              setState(
                    () {
                  finalAngle += details.delta.distance * -pi / 180;
                },
              );
            },
            child: Container(
              margin: EdgeInsets.only(top: 220),
              color: Colors.black,
              width: 50,
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Swipe to rotate', style: TextStyle(color: Colors.white),textAlign: TextAlign.center,),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: <Widget>[
              Container(
                height: 80,
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FloatingActionButton(
                        tooltip: 'Pick Image',
                        child: Icon(
                          Icons.rotate_right,
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.black,
                        onPressed: (){
                          setState(() {
                            finalAngle+=pi/2;
                          });
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: FloatingActionButton(
                        tooltip: 'Pick Image',
                        child: Icon(Icons.photo_library),
                        onPressed: getImage,
                        backgroundColor: Colors.black,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: FloatingActionButton(
                        child: Icon(Icons.camera),
                        onPressed: onCameraCapture,
                        backgroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 10.0),
            height: 200.0,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Container(
                  width: 160.0,
                  child: RaisedButton(
                    color: Colors.grey[200],
                    child: listImg[0]==null? Text('No image selected.'):Image.file(listImg[0]),
                    onPressed: (){
                      setState(() {
                       _image = listImg[0];
                       _future = getExifFromFile(_image);
                       finalAngle = 0.0;
                       _scale = 1.0;
                       selectedIndex = 0;
                      });
                    },
                  ),
                ),
                Container(
                  width: 160.0,
                  color: Colors.black,
                  child: RaisedButton(
                    color: Colors.grey[200],
                    child: listImg[1]==null? Text('No image selected.'):Image.file(listImg[1]),
                    onPressed: (){
                      setState(() {
                          _image = listImg[1];
                          _future = getExifFromFile(_image);
                          finalAngle = 0.0;
                          _scale = 1.0;
                          selectedIndex = 1;
                      });
                    },
                  ),
                ),
                Container(
                  width: 160.0,
                  color: Colors.black,
                  child: RaisedButton(
                    color: Colors.grey[200],
                    child: listImg[2]==null? Text('No image selected.'):Image.file(listImg[2]),
                    onPressed: (){
                      setState(() {
                        _image = listImg[2];
                        _future = getExifFromFile(_image);
                        finalAngle = 0.0;
                        _scale = 1.0;
                        selectedIndex = 2;
                      });
                    },
                  ),
                ),
                Container(
                  width: 160.0,
                  color: Colors.black,
                  child: RaisedButton(
                    color: Colors.grey[200],
                    child: listImg[3]==null? Text('No image selected.'):Image.file(listImg[3]),
                    onPressed: (){
                      setState(() {
                        _image = listImg[3];
                        _future = getExifFromFile(_image);
                        finalAngle = 0.0;
                        _scale = 1.0;
                        selectedIndex = 3;
                      });
                    },
                  ),
                ),
                Container(
                  width: 160.0,
                  color: Colors.black,
                  child: RaisedButton(
                    color: Colors.grey[200],
                    child: listImg[4]==null? Text('No image selected.'):Image.file(listImg[4]),
                    onPressed: (){
                      setState(() {
                        _image = listImg[4];
                        _future = getExifFromFile(_image);
                        finalAngle = 0.0;
                        _scale = 1.0;
                        selectedIndex = 4;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data != null) {
                      return Text(snapshot.data);
                    } else {
                      return CircularProgressIndicator();
                    }
                  }
                  return Container();
                },
              ),
              Linkify(
                onOpen: openMap,
                text: latitude==null? "" : "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

