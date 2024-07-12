import 'package:flutter/material.dart';
import 'package:flutter_application_6/button_horiz_rail.dart';
import 'package:flutter_application_6/video_card.dart';
import 'board_input_page.dart';
import 'my_appbar.dart';
import 'board.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_constant.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';

// import 'src/sign_in_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // 플러그인 초기화를 위해 필요

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ideal time to initialize
  // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

  FirebaseAuth.instance
  .authStateChanges()
  .listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
  });

  // User user = FirebaseAuth.instance.currentUser!;

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Flutter'),
    );
  }
}

// ignore: must_be_immutable
class MyHomePage extends StatefulWidget {
  late String title;
  MyHomePage({super.key, required this.title});
  
  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  late Future<List<BoardDTO>>? futureBoards = null;
  String baseUrl = '';

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  

  Future<User?> _signInWithGoogle() async {
    // Trigger the Google Sign In process
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // 사용자가 로그인 프로세스를 취소했을 경우
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome ${userCredential.user!.displayName}, ${userCredential.user!.email}')),
      );
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }


  @override
  void initState() {
    super.initState();    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();  // SharedPreferences에서 baseUrl을 불러온걸 보장한 뒤 fetchBoards를 호출한다.
      setState(() {
        futureBoards = fetchBoards();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(baseUrl)),
      );
    });
  }

  // Future<void> init() async {
  //   await Firebase.initializeApp(
  //       options: DefaultFirebaseOptions.currentPlatform);

  //   FirebaseUIAuth.configureProviders([
  //     EmailAuthProvider(),
  //   ]);

  //   FirebaseAuth.instance.userChanges().listen((user) {
  //     if (user != null) {
  //       _loggedIn = true;
  //     } else {
  //       _loggedIn = false;
  //     }
  //     notifyListeners();
  //   });
  // }

  // Future<void> onloaded(Duration timeStamp) async {
  //   await _loadData();
    
  //   setState(() {
  //     futureBoards = fetchBoards();  
  //   });

  //   ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(baseUrl)),
  //   );
  // }



  Future<List<BoardDTO>> fetchBoards() async {
    if (baseUrl.isEmpty) {
      baseUrl = AppConstants.baseUrlDefault;
    }

    final response = await http.get(
        Uri.parse('$baseUrl/api/board/page?page=0&pageSize=20'),        
        headers: {'content-type': 'application/json; charset=UTF-8'});
    if (response.statusCode == 200) {
      return (json.decode(utf8.decode(response.bodyBytes))['content'] as List)
          .map((data) => BoardDTO.fromJson(data))
          .toList();
    } else {
      throw Exception('Failed to load boards');
    }
  }

  Future<void> _saveData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    for (var entry in data.entries) {
      await prefs.setString(entry.key, entry.value.toString());
    }
    // await prefs.setString(key, value);
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Shared Preferences에서 baseUrl을 불러오는데 실패할 경우 기본값을 사용한다.
      baseUrl = prefs.getString(AppConstants.baseUrlKey) ?? AppConstants.baseUrlDefault;
    } catch (e) {
      baseUrl = AppConstants.baseUrlDefault;
      print('Error: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar.withValues(
        title: widget.title,
        leading: const Icon(Icons.home, color: Colors.white),
        actions: [          
          Icon(Icons.account_circle_sharp),
          Icon(Icons.notifications),
          Icon(Icons.search),
        ],     
        loginWithGoogle: _signInWithGoogle,
        onSaveData: _saveData,   
        data: {'baseUrl': baseUrl},
      ),      
      body: LayoutBuilder(
        builder: (context, constraints) {
          futureBoards ??= fetchBoards();

          List<String> items = ['Post', '새로운 맞춤 동영상', '레이아웃', '애니메이션', '쇼핑', '게임', '채널', '커뮤니티'];
          return ConstrainedBox(
            constraints: const BoxConstraints(              
              minWidth: 300,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 4, color: Colors.black,),
                  Container(
                    color: Colors.black,
                    child: ButtonHorizRail(items: items,),
                    
                  ),
                  Container(height: 4, color: Colors.black,),
                  FutureBuilder(
                    future: futureBoards, 
                    builder: (context, snapshot) {
                      if (futureBoards == null) {
                        return const Center(child: CircularProgressIndicator());
                      } else
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No data available'));
                      } else {
                        return Column(
                          children: snapshot.data!.map((board) {
                            return VideoCard(
                              key: ValueKey(board.id),
                              board: board,
                              baseUrl: baseUrl,
                            );
                          }).expand((element) => [
                                element,
                                const SizedBox(height: 8),
                              ]).toList(),
                        );
                      }
                    },
                  ),
                ].expand((element) => [ element, const SizedBox(height: 8), ]).toList(),
              ),
            ),
          );
        },              
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => BoardInputPage(userId: '1', baseUrl: baseUrl,))
                );
                
                print('result: $result');
                // 업로드 결과가 성공적으로 이루어 졌다면...
                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('게시글이 성공적으로 업로드되었습니다.')),
                  );
                  
                  // 게시글 목록을 다시 불러온다.
                  setState(() {                    
                    futureBoards = fetchBoards();                    
                  });
                } 
              }              
            ),
          ],
        ),
      )
    );
  }
}

class MyText extends StatelessWidget {
  final String text;
  final int condition;

  MyText({super.key, this.text='MyText', this.condition=0});
  
  @override
  Widget build(BuildContext context) {

    Color color;
    switch (condition) {
      case 0:
        color = Colors.black;
        break;
      case 1:
        color = Colors.red;
        break;
      case 2:
        color = Colors.blue;
        break;
      default:
        color = Colors.black;
    }

    TextStyle? style = TextStyle(color: color, fontSize: 16);

    return Text('MyText', style:style,);
  }
}