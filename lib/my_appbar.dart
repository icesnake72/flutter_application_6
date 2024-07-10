
// import 'dart:nativewrappers/_internal/vm/lib/core_patch.dart';
import 'package:flutter/material.dart';
// import 'dart:core';

class MyAppBar extends AppBar {  

  MyAppBar.withValues({
    super.key,
    required String title,
    required List<Icon> actions,
    required Icon leading,
    required Function() loginWithGoogle,
    required Function(Map<String, dynamic>) onSaveData,    
    required Map<String, dynamic> data,
  }) : super(
    backgroundColor: Colors.black,
    title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              // Icon(Icons.home, color: Colors.white),
              const SizedBox(width: 10),
              Text(title, 
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: actions[0], //Icon(Icons.tv), 
                color: Colors.white,
                onPressed: (){
                  var user = loginWithGoogle();
                  print(user.toString());
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: actions[1], 
                color: Colors.white,
                onPressed: (){},
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: actions[2], 
                color: Colors.white,
                onPressed: (){onSaveData(data);},
              ),
            ],
          ),
        ],
    ),
  );  
}