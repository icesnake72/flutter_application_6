import 'package:flutter/material.dart';


class ButtonHorizRail extends StatelessWidget {
  

  const ButtonHorizRail({
    super.key,
    required this.items, 
    this.spacing=4.0,
  });

  final List<String> items;  
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,      
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...List.generate(items.length, (index) {
            return Padding(
              padding: const EdgeInsets.all(4),
              child: ElevatedButton(
                onPressed: (){ (index, context) => _onPressed(index, context); },                
                style: const ButtonStyle(
                    shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    backgroundColor: WidgetStatePropertyAll<Color>(Color.fromARGB(255, 30, 30, 30)),                          
                ),
                child: Text(items[index], style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ));
          }),
        ].expand((element) => [ SizedBox(width: spacing), element, ]).toList(),
      ),
    );
  }

  void _onPressed(int index, BuildContext context) {
    // print('Button $index pressed');
    SnackBar snackBar = SnackBar(content: Text('Button $index pressed'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    // Navigator.push(context, MaterialPageRoute(builder: (context) => items[index]);
  }
}