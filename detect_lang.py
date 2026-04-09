#!/usr/bin/env python3
import os
import sys
from langdetect import detect, DetectorFactory

DetectorFactory.seed = 0

def detect_language(filepath):
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            text = f.read(5000) 

        lang = detect(text)

        if lang == "fi":
        	return "FI"

        elif lang == "en":
            return "EN"
        else:
            return lang.upper()

    except Exception as e:
        print(f"Error in file {filepath}: {e}")
        return None


def process_directory(directory):
    for filename in os.listdir(directory):
        if not filename.lower().endswith(".srt"):
            continue

        full_path = os.path.join(directory, filename)

        # estä tuplanimeäminen
        if filename.endswith("_EN.srt") or filename.endswith("_FI.srt"):
            print(f"Skipping (already named): {filename}")
            continue

        lang = detect_language(full_path)

        if not lang:
            continue

        if lang not in ["FI", "EN"]:
        	continue

        name, ext = os.path.splitext(filename)
        new_name = f"{name}_{lang}{ext}"
        new_path = os.path.join(directory, new_name)

        os.rename(full_path, new_path)
        print(f"{filename} -> {new_name}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python detect_sub_lang.py /path/to/folder")
        sys.exit(1)

    directory = sys.argv[1]

    if not os.path.isdir(directory):
        print(f"Error: the path given is not a directory: \n {directory}")
        sys.exit(1)

    process_directory(directory)
