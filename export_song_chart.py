# export_song_chart.py
import sys
import json
from music21 import converter, tempo

# Map pitch names to Godot keys
note_to_keyname = {
    "D4": "KEY_1",
    "E4": "KEY_2",
    "F4": "KEY_3",
    "G4": "KEY_4",
    "A4": "KEY_5",
    "B4": "KEY_6",
    "C5": "KEY_7",
    "D5": "KEY_8",
    "E5": "KEY_9",
}

def xml_to_songchart(xml_path, out_path, bpm=60, offset=1.0):
    """Convert a MusicXML (.mxl) file to a Godot JSON song chart."""
    score = converter.parse(xml_path)
    quarter_duration = 60.0 / bpm  # seconds per beat (quarter note)

    events = []
    current_time = 0.0

    for note in score.flat.notes:
        if note.isNote:
            note_name = note.nameWithOctave
            if note_name in note_to_keyname:
                keyname = note_to_keyname[note_name]
                # get offset in beats from start
                time_in_seconds = note.offset * quarter_duration
                events.append({
                    "time": round(time_in_seconds + offset, 3),
                    "key": keyname
                })

    events.sort(key=lambda e: e["time"])

    with open(out_path, "w") as f:
        json.dump(events, f, indent=2)

    print(f"✅ Wrote {len(events)} events to {out_path}")
    if events:
        print(f"🎵 First note starts at {events[0]['time']:.3f}s")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python export_song_chart.py input.mxl output.json")
        sys.exit(1)

    xml_to_songchart(sys.argv[1], sys.argv[2])
