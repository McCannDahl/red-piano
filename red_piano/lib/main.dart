import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_piano_pro/flutter_piano_pro.dart';
import 'package:flutter_piano_pro/note_model.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

void main() {
  runApp(const MyApp());
}

const sharpOrder = ['F', 'C', 'G', 'D', 'A', 'E', 'B'];

const flatOrder = ['B', 'E', 'A', 'D', 'G', 'C', 'F'];

const sharpAccidentals = ['F#', 'C#', 'G#', 'D#', 'A#', 'E#', 'B#'];

const flatAccidentals = ['Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb', 'Fb'];

String? whiteNoteLetter(int midi) {
  switch (midi % 12) {
    case 0:
      return 'C';
    case 2:
      return 'D';
    case 4:
      return 'E';
    case 5:
      return 'F';
    case 7:
      return 'G';
    case 9:
      return 'A';
    case 11:
      return 'B';
    default:
      return null;
  }
}

String? accidentalName(int midi, AccidentalType type) {
  switch (midi % 12) {
    case 1:
      return type == AccidentalType.sharps ? 'C#' : 'Db';
    case 3:
      return type == AccidentalType.sharps ? 'D#' : 'Eb';
    case 6:
      return type == AccidentalType.sharps ? 'F#' : 'Gb';
    case 8:
      return type == AccidentalType.sharps ? 'G#' : 'Ab';
    case 10:
      return type == AccidentalType.sharps ? 'A#' : 'Bb';
    default:
      return null;
  }
}

enum AccidentalType { sharps, flats }

class PianoSettings {
  int count;

  AccidentalType type;

  PianoSettings({this.count = 0, this.type = AccidentalType.sharps});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PianoScreen());
  }
}

class PianoScreen extends StatefulWidget {
  const PianoScreen({super.key});

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> {
  // 1. Instantiate the MidiPro engine
  final _midiPro = MidiPro();
  int? _soundfontId;
  bool _isEngineReady = false;
  int currentNote = 0;
  final settings = PianoSettings();

  // Track which fingers are pressing which notes to avoid duplicated notes
  final Map<int, NoteModel> _activePointerNotes = {};

  @override
  void initState() {
    super.initState();
    _setupAudioEngine();
  }

  Future<void> _setupAudioEngine() async {
    // 2. Load your asset SoundFont file before trying to play anything
    // bank 0, program 0 usually represents the default Grand Piano instrument
    final id = await _midiPro.loadSoundfontAsset(
      assetPath: 'assets/piano.sf2',
      bank: 0,
      program: 0,
    );

    setState(() {
      _soundfontId = id;
      _isEngineReady = true;
    });
  }

  Future<void> _showSettings() async {
    int sharpsFlats = settings.count;
    AccidentalType type = settings.type;

    await showDialog(
      context: context,
      builder: (context) {
        int sharpsFlats = settings.count;
        AccidentalType type = settings.type;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Key Signature"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<AccidentalType>(
                    value: type,
                    items: const [
                      DropdownMenuItem(
                        value: AccidentalType.sharps,
                        child: Text("Sharps"),
                      ),
                      DropdownMenuItem(
                        value: AccidentalType.flats,
                        child: Text("Flats"),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        type = value!;
                      });
                    },
                  ),

                  Slider(
                    value: sharpsFlats.toDouble(),
                    min: 0,
                    max: 7,
                    divisions: 7,
                    onChanged: (value) {
                      setDialogState(() {
                        sharpsFlats = value.toInt();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      settings.count = sharpsFlats;
                      settings.type = type;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEngineReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Piano Pro'),
        actions: [
          // Down Arrow Action
          IconButton(
            icon: Icon(Icons.arrow_downward),
            onPressed: () {
              setState(() {
                currentNote++;
              });
            },
            tooltip: 'Decrease Value',
          ),
          // Up Arrow Action
          IconButton(
            icon: Icon(Icons.arrow_upward),
            onPressed: () {
              setState(() {
                currentNote--;
              });
            },
            tooltip: 'Increase Value',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: (-330 + currentNote * 46).toDouble(),
                  left: 0,
                  child: Container(
                    width: 130,
                    height: 1350,
                    child: Image.asset(
                      'assets/Treble_clef_and_Bass_clef.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 250,
            child: RotatedBox(
              quarterTurns:
                  3, // 1 = 90 degrees clockwise, 2 = 180, 3 = 270, 4 = 360
              child: PianoPro(
                firstNoteIndex: currentNote,
                firstOctave: 3,
                noteCount: 15, // Number of keys to display
                // 3. Play note when key is pressed
                onTapDown: (NoteModel? note, int tapId) {
                  if (note == null || _soundfontId == null) return;

                  _midiPro.playNote(
                    sfId: _soundfontId!,
                    channel: 0,
                    key: note.midiNoteNumber,
                    velocity: 127, // Maximum volume/force
                  );

                  _activePointerNotes[tapId] = note;
                },

                // 4. Update note when sliding finger across keys
                onTapUpdate: (NoteModel? note, int tapId) {
                  if (note == null || _soundfontId == null) return;
                  if (_activePointerNotes[tapId] == note) return;

                  // Stop the previous note slide-off
                  if (_activePointerNotes[tapId] != null) {
                    _midiPro.stopNote(
                      sfId: _soundfontId!,
                      channel: 0,
                      key: _activePointerNotes[tapId]!.midiNoteNumber,
                    );
                  }

                  // Play the new note slide-on
                  _midiPro.playNote(
                    sfId: _soundfontId!,
                    channel: 0,
                    key: note.midiNoteNumber,
                    velocity: 127,
                  );

                  _activePointerNotes[tapId] = note;
                },

                // 5. Stop note when finger is lifted
                onTapUp: (int tapId) {
                  if (_soundfontId == null ||
                      _activePointerNotes[tapId] == null)
                    return;

                  _midiPro.stopNote(
                    sfId: _soundfontId!,
                    channel: 0,
                    key: _activePointerNotes[tapId]!.midiNoteNumber,
                  );

                  _activePointerNotes.remove(tapId);
                },
                buttonColors: getButtonColors(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, Color> getButtonColors() {
    final colors = <int, Color>{};

    final whiteHighlights = settings.type == AccidentalType.sharps
        ? sharpOrder.take(settings.count).toSet()
        : flatOrder.take(settings.count).toSet();

    final blackHighlights = settings.type == AccidentalType.sharps
        ? sharpAccidentals.take(settings.count).toSet()
        : flatAccidentals.take(settings.count).toSet();

    for (int midi = 0; midi <= 127; midi++) {
      final white = whiteNoteLetter(midi);

      if (white != null) {
        if (whiteHighlights.contains(white)) {
          colors[midi] = Colors.red;
        }
        continue;
      }

      final accidental = accidentalName(midi, settings.type);

      if (!(accidental != null && blackHighlights.contains(accidental))) {
        colors[midi] = Colors.red.shade800;
      }
    }

    return colors;
  }
}
