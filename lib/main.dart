import 'package:flutter/material.dart';
import 'package:flutter_audio_picker/picker_screen.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //This variable will hold the audio we pick
  List<AssetEntity> selectedAudio = [];

  //function to help us pick audios
  Future pickAudio() async {
    //we navigate to the picker screen and return the selected audios, to remember audios that already picked we pass the selected audios as parameter for PickerScreen
    List<AssetEntity>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return PickerScreen(alreadySelected: selectedAudio);
        },
      ),
    );
    if (result != null && result.isNotEmpty) {
      for (var audio in result) {
        //remove any duplication from the list of selected audio
        bool contains = selectedAudio.any((element) => element.id == audio.id);
        if (contains == false) {
          setState(() {
            selectedAudio.add(audio);
          });
        }
      }
    }
  }

  createAudio() async {
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Picker"),
        centerTitle: true,
      ),
      body: selectedAudio.isEmpty
          ? const Center(
              child: Text("No audio selected"),
            )
          : ListView.builder(
              itemCount: selectedAudio.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.music_note_rounded),
                      title: Text(selectedAudio[index].title!),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            selectedAudio.remove(selectedAudio[index]);
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await pickAudio().then((_) {
            setState(() {});
          });
        },
        child: const Icon(
          Icons.music_note_rounded,
        ),
      ),
    );
  }
}
