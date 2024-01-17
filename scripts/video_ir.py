#!/usr/bin/env python3
"""
Handles the creation of intermediate representation for video.

Ref: https://github.com/ve1ld/vyasa/issues/21
"""
import json
import sys
from libindic.soundex import Soundex

instance = Soundex()

def read_file(filename):
    print(f">> Reading {filename} as a json file")

    with open(filename, 'r') as f:
        data = json.load(f)

    return data

def write_to_file(filename, content):
   with open(filename, 'w') as file:
      file.write(content)


class VideoCaptions:
   """
   Observations about segments::
   0. A negligible minority of the events won't have segments (only the first one it seems.)
   1. [the text has instrumentals] there are text-events that just say "[संगीत]", which means instruments.
   I'm guessing that similar stuff will be there in other languages as well. If there's a need to filter these
   commented parts out, then we should be able to do so by just filtering away whatever is within `[]`
   2. some events will overlap when displaying captions, that's why they are not chronologically unique segments.
   """

   def __init__(self, captions_data):
     events = captions_data.get('events')

     self.caption_events = [Event(event, event_idx + 1) for event_idx, event in enumerate(events)]

   def create_srt_file(self, filename="captionsOutput.srt"):
      print(f">> writing to file {filename}...")
      content = "".join([str(event) for event in self.caption_events])
      write_to_file(filename, content)

      print(f">> wrote to file {filename}")


class Event:
   def __init__(self, event_data, event_num):
       self.event_num = event_num
       self.event_text = self.extract_all_text_in_event(event_data)
       self.event_start_time, self.event_end_time, self.event_duration = self.extract_timing_info(event_data)
       self.event_data = event_data



   def extract_all_text_in_event(self, event):
      segs = event.get("segs", [])
      text_in_segs = " ".join([seg.get("utf8", " ") for seg in segs])
      # print(f"{text_in_segs}")

      return text_in_segs

   def extract_timing_info(self,event):
      start_time = event.get('tStartMs')
      duration = event.get('dDurationMs', 0)
      end_time = start_time + duration
      # print(f"Event with start = {start_time}ms end = {end_time}ms \t\t duration: {duration}")

      return [start_time, end_time, duration]

   def create_time_triplet(self, ms_timestring):
      seconds = (ms_timestring // 1000)
      hours = str(seconds // 3600).zfill(2)
      seconds %= 3600
      minutes = str(seconds // 60).zfill(2)
      seconds %= 60
      seconds = str(seconds).zfill(2)
      milliseconds = str(ms_timestring % 1000).zfill(3)

      return f"{hours}:{minutes}:{seconds},{milliseconds}"


   def __str__(self) -> str:
      result = f"{self.event_num}\n"
      TWO_HASH_ARROW_DELIM = "-"+"-"+">"
      start_time = self.create_time_triplet(self.event_start_time)
      end_time = self.create_time_triplet(self.event_end_time)
      result += f"{start_time} {TWO_HASH_ARROW_DELIM} {end_time}\n"
      result += f"{self.event_text}\n"

      return result

class Verse:

    def __init__(self, verse_data) -> None:
        self.count = verse_data.get("count")
        self.transliteration = verse_data.get("verse_trans")
        self.sanskrit = verse_data.get("verse_sanskrit")
        self.meaning = verse_data.get("verse_meaning")

        return

    def get_similarity_score_for_text(self, other_text):
        if not other_text:
            return

        return instance.compare(self.sanskrit, other_text)


    def __repr__(self) -> str:
        msg = f"{[self.count]}\n{self.sanskrit}\n"
        return msg

class ScrapedText:
    def __init__(self, file_data) -> None:
        self.title = file_data.get("title")
        self.description = file_data.get("description")
        self.verses = [Verse(verse_data) for verse_data in file_data.get("verses")]

        return

def main():
    caption_data = read_file(sys.argv[1] if len(sys.argv) - 1 > 0 else "chalisa.json")
    captions = VideoCaptions(caption_data)
    # captions.create_srt_file(sys.argv[2] if len(sys.argv) - 1 > 1 else "chalisa.srt")

    scraped_data = read_file(sys.argv[1] if len(sys.argv) - 1 > 0 else "chalisa_scraped.json")
    scraped_text = ScrapedText(scraped_data)

    test_input_verse = scraped_text.verses[4]
    test_input_captions = captions.caption_events[45].event_text
    all_captions = [event.event_text for event in captions.caption_events]
    # print(">>> test input verse:\n", test_input_verse)
    # print("test_input_captions\n", test_input_captions)
    # print("sim:", test_input_verse.get_similarity_score_for_text(test_input_captions))

    for verse_idx, verse in enumerate(scraped_text.verses):
        scores = []
        for caption_idx, caption in enumerate(all_captions):
            score = verse.get_similarity_score_for_text(caption)

            if (score == 1):
                print(f">> DIRECT MATCH: \n verse_idx {verse_idx} matching caption idx: {caption_idx}")
                # print(f">> MATCH: \ntest input: {test_input_verse}\n matching: {caption}")
            scores.append(score or -1)

        highest_score = max(scores)
        most_likely_caption_idx = highest_score_idx = scores.index(highest_score)
        print(f"Verse idx {verse_idx} --> likely to be --> {most_likely_caption_idx} with score of {highest_score}")



    # all_scores = []
    # print("all scores:", all_scores)




    # [print(str(verse))for verse in scraped_text.verses]

    return


if __name__ == "__main__":
   main()
