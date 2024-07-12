import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'dart:io';


class BoardInputPage extends StatefulWidget {
  final String userId;
  final String baseUrl;

  // 생성자를 통해 무조건 userId와 baseUrl을 전달받음
  const BoardInputPage({super.key, required this.userId, required this.baseUrl});

  @override
  _BoardInputPageState createState() => _BoardInputPageState();
}

class _BoardInputPageState extends State<BoardInputPage> {
  final _formKey = GlobalKey<FormState>();

  // 텍스트 필드의 현재 값을 쉽게 읽거나 설정할 수 있도록 하는 컨트롤러
  // 텍스트 필드의 값이 변경될 때 이를 감지할 수 있다.
  // 폼에서 여러 텍스트 필드를 관리하고 검증할 때 유용
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  // XFile은 iOS, Android, 웹, 데스크탑 등 다양한 플랫폼에서 일관된 방식으로 파일을 다룰 수 있게 한다.
  // XFile을 통해 파일을 읽고 쓸 수 있으며, 파일의 메타데이터에 접근할 수 있다.  
  List<XFile?> _images = List<XFile?>.filled(3, null);

  // 웹에서 이미지를 선택할 때 사용할 Uint8List(바이트 스트림) 리스트
  List<Uint8List?> _webImages = List<Uint8List?>.filled(3, null); 

  // 이미지를 선택하거나 촬영하기 위해 ImagePicker 인스턴스를 생성
  final ImagePicker _picker = ImagePicker();

  // uploadUrl은 서버의 업로드 API 주소로 변경해야 함
  final String uploadUrl = '/api/board/create';
  
  // 이미지 선택 기능(모바일 or not)
  Future<void> _pickImage(int index) async {
    try{
      if (index < 0 || index >= _images.length) {
        print('Index out of range, index: $index');
        return;

      }

      if (kIsWeb) { // 현재 실행환경이 웹 베이스드에서 실행이 되고 있는지 여부를 확인
        await _pickImageWeb(index);
        return;
      }

      // 크롬기반에서 아래코드를 호출하면 Exception이 발생함!!! 
      if (Platform.isAndroid || Platform.isIOS) {
        await _pickImageMobile(index);
      } else {
        await _pickImageDesktop(index);
      }
    } catch (e) {      
      print(e);
    }
    // if (Platform.isAndroid || Platform.isIOS) {
    //   await _pickImageMobile(index);
    // } else {
    //   await _pickImageDesktop(index);
    // }
  }

  Future<void> _pickImageWeb(index) async {
    // XTypeGroup : file_selector 패키지에서 파일 선택을 위한 허용되는 파일 형식(이미지 파일)을 정의
    // openFile 메서드를 사용하여 파일을 선택하고, 선택한 파일을 XFile 객체로 반환
    final typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'png', 'gif', 'webp']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        print('${bytes.length} bytes read.');
        _webImages[index] = bytes;
      });
    }    
  }

  // 이미지 선택 기능(모바일) 
  Future<void> _pickImageMobile(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        // _images.add(File(pickedFile.path));
        _images[index] = pickedFile;
      });
    }
  }

  // 이미지 선택 기능(데스크탑)
  Future<void> _pickImageDesktop(index) async {
    // XTypeGroup : file_selector 패키지에서 파일 선택을 위한 허용되는 파일 형식(이미지 파일)을 정의
    // openFile 메서드를 사용하여 파일을 선택하고, 선택한 파일을 XFile 객체로 반환    
    // Use file_selector for web, macOS, Windows, and Linux    
      final typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'png', 'gif', 'webp']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        setState(() {
          // _images.add(File(file.path));
          _images[index] = XFile(file.path);
        });
      }
  }

  // 이미지 촬영 기능, iOS와 Android에서만 지원
  // ImagePicker를 사용하여 이미지를 촬영하고, 촬영한 이미지를 _images 리스트에 추가
  Future<void> _takePhoto(int index) async {
    // 웹 실행환경인지 체크를 하고 지원하지 않음을 알림
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카메라는 이 플랫폼에서 지원되지 않습니다.'),
        ),
      );
      return;
    }

    if (Platform.isIOS || Platform.isAndroid) {
      // Use image_picker for iOS and Android
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _images[index] = pickedFile;
        });
      }
    } else {
      // Camera not supported on web, macOS, Windows, and Linux
      // throw UnimplementedError('Camera not supported on this platform');
      // Camera not supported on web, macOS, Windows, and Linux
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카메라는 이 플랫폼에서 지원되지 않습니다.'),
        ),
      );
    }
  }


  Future<void> _uploadData() async {
    if (_formKey.currentState!.validate()) {

      String url = '${widget.baseUrl}$uploadUrl';
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['title'] = _titleController.text;
      request.fields['text'] = _textController.text;
      request.fields['userId'] = '1';  // 추후에 생성자로부터 받은 userId로 변경해야 함

      if (kIsWeb) {
        // 웹에서 이미지를 업로드할 때는 바이트 스트림으로 변환하여 전송
        int i = 0;
        for (var image in _webImages) {
          if (image != null) {
            request.files.add(http.MultipartFile.fromBytes('files', image, filename: 'image_$i.jpg'));
          }
          i++;
        }
      } else {
        for (var image in _images) {
          if (image != null) {
            request.files.add(await http.MultipartFile.fromPath('files', image.path));
          }
        }
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        // await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pop(true);  // 게시글 작성 페이지를 닫고 이전 페이지로 이동
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: ${response.statusCode}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 작성'),
      ),
      body: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      labelText: '제목',
                      hintText: '제목을 입력하세요',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '제목을 입력하세요';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _textController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      labelText: '내용',
                      hintText: '내용을 입력하세요',
                    ),
                    maxLines: 8,
                    maxLength: 300,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '내용을 입력하세요';
                      }
                      return null;
                    },
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo),
                        onPressed: ()=>_pickImage(0),
                        label: const Text('갤러리에서 이미지 선택'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera),
                        onPressed: ()=>_takePhoto(0),
                        label: const Text('카메라로 사진 찍기'),
                      ),
                    ],
                  ),
                  Wrap( // 한줄에 자식 위젯들이 모드 들어가지 않을 때 자동으로 다음 줄로 넘기는 위젯
                    spacing: 8.0,   // 가로 간격
                    runSpacing: 4.0,  // 세로 간격
                    children: List.generate(3, (index) {
                      return GestureDetector(
                        onTap: () => _pickImage(index),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: (kIsWeb)?  // 현재 실행환경이 웹 베이스드에서 실행이 되고 있는지 여부를 확인
                            (_webImages[index] != null) ? // 이미지 데이터 로딩이 되어 있는지 여부 확인
                            Stack(
                              children: [
                                Image.memory( // 바이트 스트림으로 이미지를 로딩
                                  _webImages[index]!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  right: 0,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _webImages[index] = null;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ) :
                            const Center(child: Icon(Icons.add_to_photos_sharp),) :
                            _images[index] != null
                            ? Stack(
                                children: [
                                  Image.file(
                                    File(_images[index]!.path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    right: 0,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _images[index] = null;
                                        });
                                      },
                                      child: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                  ],
                                )
                              : const Center(
                                  child: Icon(Icons.add_to_photos_sharp),
                                ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _uploadData(),
                      label: const Text('저장'),
                      icon: Icon(Icons.upload),
                      style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.blue)),
                    ),
                  ),
                ].expand((element) => [element, const SizedBox(height: 16)]).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
