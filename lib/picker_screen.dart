import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:audioplayers/audioplayers.dart' as player;
import 'package:audioplayers/audioplayers.dart';

class PickerScreen extends StatefulWidget {
  final List<AssetEntity> alreadySelected;
  const PickerScreen({super.key, required this.alreadySelected});

  @override
  State<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<PickerScreen> {
  //variable to store retrieved audios available in the device storage
  List<AssetEntity> retrievedAudio = [];

  int currentPage = 0;
  loadAudio() async {
    //load 50 audios per page
    await recentAlbum!.getAssetListPaged(page: currentPage, size: 50).then(
      (assets) {
        for (var a in assets) {
          bool contains = retrievedAudio.any((element) => element.id == a.id);
          if (contains == false) {
            setState(() {
              retrievedAudio.add(a);
            });
          }
        }
      },
    );
  }

  //variable that stores 'recent' or 'all audio' album
  AssetPathEntity? recentAlbum;

  //initialize retrieving the recent album
  initAudio() async {
    //assign the alreadySelected audio list to the selectedAudio list
    setState(() {
      selectedAudio = widget.alreadySelected;
    });
    await PhotoManager.requestPermissionExtend().then(
      (state) async {
        if (state.hasAccess) {
          //ensure you are retrieving only audio assets
          await PhotoManager.getAssetPathList(type: RequestType.audio).then(
            (value) {
              setState(() {
                recentAlbum = value.first;
              });
              //then load audio available in that album
              loadAudio();
            },
          );
        }
      },
    );
  }

  //this is the selected audio list
  List<AssetEntity> selectedAudio = [];

  selectAudio({required AssetEntity audio}) {
    bool contains = selectedAudio.any((element) => element.id == audio.id);
    int index = selectedAudio.indexWhere((element) => element.id == audio.id);

    if (contains) {
      setState(() {
        selectedAudio.removeAt(index);
      });
    } else {
      setState(() {
        selectedAudio.add(audio);
      });
    }
  }

  TextEditingController searchController = TextEditingController();
  List<AssetEntity> searchResult = [];
  searchAudio({required String text}) {
    //clear searchResult list for new data
    setState(() {
      searchResult = [];
    });

    for (var audio in retrievedAudio) {
      //make the search NOT case-sensitive
      if (audio.title
          .toString()
          .toLowerCase()
          .contains(text.trim().toLowerCase())) {
        bool contains = searchResult.any((element) => element.id == audio.id);
        if (contains == false) {
          setState(() {
            searchResult.add(audio);
          });
        }
      }
    }
  }

  @override
  void initState() {
    initAudio();
    //play listener
    audioPlayer.onPlayerStateChanged.listen(
      (event) {
        if (mounted) {
          setState(() {
            isPlaying = event == PlayerState.playing ? true : false;
          });
        }
      },
    );
    super.initState();
    //create a listener that retrieves more audio as the user scrolls
    scrollController.addListener(
      () {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          loadAudio();
        }
      },
    );
  }

  @override
  void dispose() {
    if (mounted) {
      audioPlayer.dispose();
    }
    super.dispose();
  }

  ScrollController scrollController = ScrollController();

  //play and pause audio files
  AudioPlayer audioPlayer = player.AudioPlayer();
  AssetEntity? playingAudio;
  bool isPlaying = false;

  playPauseAudio({required AssetEntity audio}) async {
    if (audio == playingAudio) {
      if (audioPlayer.state == player.PlayerState.playing) {
        audioPlayer.pause();
      } else if (audioPlayer.state == player.PlayerState.paused) {
        audioPlayer.resume();
      }
    } else {
      File? file = await audio.originFile;
      if (file != null) {
        await audioPlayer.play(player.DeviceFileSource(file.path)).then(
          (_) {
            setState(() {
              playingAudio = audio;
            });
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          onChanged: (text) {
            searchAudio(text: text);
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: "Search",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.trim().isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        searchController.clear();
                        searchResult = [];
                      });
                    },
                    child: const Icon(Icons.close),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
      body: retrievedAudio.isEmpty
          ? const Center(
              child: Text("No audio found!!!"),
            )
          : Scrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: searchResult.isNotEmpty
                    ? searchResult.length
                    : retrievedAudio.length,
                itemBuilder: (context, index) {
                  AssetEntity audio = searchResult.isNotEmpty
                      ? searchResult[index]
                      : retrievedAudio[index];
                  return ListTile(
                    onTap: () {
                      selectAudio(audio: audio);
                    },
                    leading: GestureDetector(
                      onTap: () {
                        playPauseAudio(audio: audio);
                      },
                      child: CircleAvatar(
                        child: Icon(
                          isPlaying && playingAudio == audio
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                    ),
                    title: Text(
                      audio.title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing:
                        selectedAudio.any((element) => element.id == audio.id)
                            ? Text(
                                "${(selectedAudio.indexOf(audio) + 1)}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.redAccent,
                                ),
                              )
                            : const SizedBox.shrink(),
                  );
                },
              ),
            ),
      floatingActionButton: selectedAudio.isEmpty
          ? const SizedBox.shrink()
          : FloatingActionButton(
              onPressed: () {
                //return the selected audios
                Navigator.pop(context, selectedAudio);
              },
              child: const Icon(
                Icons.check,
              ),
            ),
    );
  }
}
