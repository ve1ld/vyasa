#!/usr/bin/env python3
"""
Handles the creation of intermediate representation for video.

Ref: https://github.com/ve1ld/vyasa/issues/21
"""
import json
import sys

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

def main():
    data = read_file(sys.argv[1] or "chalisa.json")
    captions = VideoCaptions(data)
    captions.create_srt_file(sys.argv[2] or "chalisa.srt")

    return


if __name__ == "__main__":
   main()
