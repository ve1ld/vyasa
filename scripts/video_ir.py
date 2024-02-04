#!/usr/bin/env python3
"""
Handles the creation of intermediate representation for video.

Ref: https://github.com/ve1ld/vyasa/issues/21
"""
import json
import math
import sys
from indicnlp.tokenize import indic_tokenize
from indicnlp.normalize.indic_normalize import IndicNormalizerFactory
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

remove_nuktas = False
normalizer_factory = IndicNormalizerFactory()
normalizer=normalizer_factory.get_normalizer("hi") # NB: documentation doesn't match up with usage here in the #params. Problem shall be ignored.

def get_text_similarity(a, b):
    normalized_a = normalizer.normalize(a)
    normalized_b = normalizer.normalize(b)
    tokens_a = indic_tokenize.trivial_tokenize(normalized_a)
    tokens_b = indic_tokenize.trivial_tokenize(normalized_b)

    tokens_a = [token.lower() for token in tokens_a]
    tokens_b = [token.lower() for token in tokens_b]

    stringified_tokens_a = " ".join(tokens_a)
    stringified_tokens_b = " ".join(tokens_b)

    vectorizer = TfidfVectorizer().fit_transform([stringified_tokens_a, stringified_tokens_b])
    sim_score = cosine_similarity(vectorizer[0], vectorizer[1])
    return sim_score[0][0]

def read_file(filename):
    print(f">> Reading {filename} as a json file")

    with open(filename, 'r') as f:
        data = json.load(f)

    return data

def write_to_file(filename, content):
   with open(filename, 'w') as file:
      print(f"Writing to {filename}...")
      file.write(content)
      print(f"... Wrote to {filename}")



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
      content = "".join([str(event) for event in self.caption_events])
      write_to_file(filename, content)

class Event:
   def __init__(self, event_data, event_num):
       self.event_num = event_num
       extracted_text = self.extract_all_text_in_event(event_data)
       self.event_text = extracted_text
       self.is_empty_text = True if not extracted_text else False
       self.event_start_time, self.event_end_time, self.event_duration = self.extract_timing_info(event_data)
       self.event_data = event_data

   def to_dict(self):
       payload = {
           "event_num": self.event_num,
           "text": self.event_text,
           "is_empty": self.is_empty_text,
           "start_ms": self.event_start_time,
           "end_ms": self.event_end_time,
           "duration_ms": self.event_duration,
       }

       return payload


   def get_text_similarity_score(self, other_text):
       (is_one_arg_empty_and_not_same) = not(other_text == self.event_text) and (not other_text or not self.event_text)
       if(is_one_arg_empty_and_not_same):
           return -1

       return get_text_similarity(self.event_text, other_text)

   def extract_all_text_in_event(self, event):
      segs = event.get("segs", [])
      text_in_segs = " ".join([seg.get("utf8", " ") for seg in segs])
      text_in_segs.strip()

      return text_in_segs

   def extract_timing_info(self,event):
      start_time = event.get('tStartMs')
      duration = event.get('dDurationMs', 0)
      end_time = start_time + duration

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

    def to_dict(self):
        payload = {
            "count": self.count,
            "transliteration": self.transliteration,
            "text": self.sanskrit,
            "meaning": self.meaning,
        }

        return payload

    def get_similarity_score_for_text(self, other_text):
        if not other_text:
            return 0

        return get_text_similarity(other_text, self.sanskrit)

    def __repr__(self) -> str:
        msg = f"{[self.count]}\n{self.sanskrit}\n"
        return msg

class ScrapedText:
    def __init__(self, file_data) -> None:
        self.title = file_data.get("title")
        self.description = file_data.get("description")
        self.verses = [Verse(verse_data) for verse_data in file_data.get("verses")]

        return


class Mapping:

    def __init__(self, scraped_text, video_captions):
        self.text = scraped_text
        self.captions = video_captions
        self.matches = self.map_scraped_verses_to_captioned_events(scraped_text.verses, video_captions.caption_events)

        for match in self.matches:
            print("======================")
            print(match)

    def dump_mapping_json(self, filename="mapping_dump.json"):
        payload = {
            "text": "hanuman chalisa",
            "mappings": [match.to_dict() for match in self.matches]
        }

        stringified = json.dumps(payload, indent=4, ensure_ascii=False)
        write_to_file(filename=filename, content=stringified)

        return

    def map_scraped_verses_to_captioned_events(self, scraped_verses, caption_events):
        num_exact_matches = 0
        num_related_matches = 0
        num_non_matches = 0
        matches = []

        for verse in scraped_verses:
            best_candidate = None
            candidates = []
            non_candidates = []
            best_sim_score = -math.inf
            for caption_event in caption_events:
                # disregard empty events:
                if caption_event.is_empty_text:
                    non_candidates.append((-math.inf, caption_event))
                    continue

                sim_score = verse.get_similarity_score_for_text(caption_event.event_text)
                pair = (sim_score, caption_event)
                best_sim_score = max(best_sim_score, sim_score)

                is_better = best_sim_score == sim_score
                if (is_better):
                    best_candidate = caption_event

                if sim_score > 0:
                    candidates.append(pair)
                else:
                    non_candidates.append(pair)

            match = self.Match(verse, best_candidate, best_sim_score)

            if (best_sim_score == 1):
                num_exact_matches += 1
                match.is_exact_match = True
            elif (best_sim_score > 0):
                num_related_matches += 1
            else:
                num_non_matches += 1

            matches.append(match)

        print(f"After mapping, stats: \n\t#exact = {num_exact_matches} \n\t#related: {num_related_matches}\n\t#non-matches: {num_non_matches}")

        return matches

    class Match:
        def __init__(self, verse, caption, score):
            self.verse = verse
            self.caption = caption
            self.score = score
            self.is_exact_match = False # default

            return

        def set_is_exact_match(self, is_exact_match):
            self.is_exact_match = is_exact_match

        def __repr__(self) -> str:
            res = f"Verse Count: {self.verse.count} Caption Event Num: {self.caption.event_num}. {self.caption.event_start_time} - {self.caption.event_end_time}\n"
            res += f"### Verse:\n{self.verse}"
            res += f"### Caption:\n{self.caption}"

            return res

        def to_dict(self):
            payload = {
                "is_exact_match": self.is_exact_match,
                "verse_count": self.verse.count,
                "caption_event_num": self.caption.event_num,
                "similarity": self.score,
                "verse": self.verse.to_dict(),
                "caption": self.caption.to_dict(),
            }

            return payload


def main(cfg={}):
    num_cli_args = len(sys.argv) - 1
    caption_file_source = sys.argv[1] if num_cli_args > 0 else "chalisa.json"
    verse_file_source = sys.argv[2] if num_cli_args > 1 else "chalisa_scraped.json"

    caption_data = read_file(cfg.get("caption_file_source", caption_file_source))
    scraped_data = read_file(cfg.get("verse_file_source", verse_file_source))

    mapping = Mapping(ScrapedText(scraped_data), VideoCaptions(caption_data))
    mapping.dump_mapping_json("chalisa_mapping_v1.json")

    return


if __name__ == "__main__":
   main()
