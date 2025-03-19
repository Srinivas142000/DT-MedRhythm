import 'package:flutter/material.dart';

class SyncButton extends StatefulWidget{
  final Future<void> Function(Duration) syncSession;

  const SyncButton({Key? key, required this.syncSession}) : super(key: key);
  @override
  _SyncButtonState createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton>{
    bool isSyncing = false;
    int? selectedMinutes;
    Future <void> _handleSync() async{
      if(selectedMinutes == null) return;
      setState(() {
        isSyncing = true;
      });
      
      try{
        await widget.syncSession(Duration(minutes: selectedMinutes!));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sync succesful!")),
          );
      }catch(e){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"))
        );
      }
      setState(() {
        isSyncing = false;
      });
    }

    @override
    Widget build(BuildContext context){
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select Sync Duration: ${selectedMinutes ?? 'None'} min", style: TextStyle(fontSize: 15),),
              Slider(
                value: (selectedMinutes ?? 1).toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                label: "${selectedMinutes ?? 1} min",
                onChanged: (value){
                  setState(() {
                    selectedMinutes = value.toInt();
                  });
                }
              )
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: (selectedMinutes == null || isSyncing) ? null : _handleSync,
            icon: isSyncing
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              :Icon(Icons.sync),
            label: Text(isSyncing ? "Syncing.." : (selectedMinutes == null ? "Select Duration" : "Sync $selectedMinutes min")),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: TextStyle(fontSize: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      );
    }
}