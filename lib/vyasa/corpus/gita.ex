defmodule Vyasa.Corpus.Gita.Chapter do
  defstruct chapter_number: 1,
    chapter_summary: "The first chapter of the Bhagavad Gita - \"Arjuna Vishada Yoga\" introduces the setup, the setting, the characters and the circumstances that led to the epic battle of Mahabharata, fought between the Pandavas and the Kauravas. It outlines the reasons that led to the revelation of the of Bhagavad Gita.\nAs both armies stand ready for the battle, the mighty warrior Arjuna, on observing the warriors on both sides becomes increasingly sad and depressed due to the fear of losing his relatives and friends and the consequent sins attributed to killing his own relatives. So, he surrenders to Lord Krishna, seeking a solution. Thus, follows the wisdom of the Bhagavad Gita.",
    chapter_summary_hindi: "भगवद गीता का पहला अध्याय अर्जुन विशाद योग उन पात्रों और परिस्थितियों का परिचय कराता है जिनके कारण पांडवों और कौरवों के बीच महाभारत का महासंग्राम हुआ। यह अध्याय उन कारणों का वर्णन करता है जिनके कारण भगवद गीता का ईश्वरावेश हुआ। जब महाबली योद्धा अर्जुन दोनों पक्षों पर युद्ध के लिए तैयार खड़े योद्धाओं को देखते हैं तो वह अपने ही रिश्तेदारों एवं मित्रों को खोने के डर तथा फलस्वरूप पापों के कारण दुखी और उदास हो जाते हैं। इसलिए वह श्री कृष्ण को पूरी तरह से आत्मसमर्पण करते हैं। इस प्रकार, भगवद गीता के ज्ञान का प्रकाश होता है।" ,
    id: 1,
    image_name: "arjuna-vishada-yoga",
    name: "अर्जुनविषादयोग",
    name_meaning: "Arjuna's Dilemma",
    name_translation: "Arjuna Visada Yoga",
    name_transliterated: "Arjun Viṣhād Yog",
    verses_count: 47
end

defmodule Vyasa.Corpus.Gita.Verse do
  defstruct chapter_id: 1,
    chapter_number: 1,
    externalId: 1,
    id: 1,
    text: "धृतराष्ट्र उवाच\n\nधर्मक्षेत्रे कुरुक्षेत्रे समवेता युयुत्सवः।\n\nमामकाः पाण्डवाश्चैव किमकुर्वत सञ्जय।।1.1।।\n ",
    title: "Verse 1",
    verse_number: 1,
    verse_order: 1,
    transliteration: "dhṛitarāśhtra uvācha\ndharma-kṣhetre kuru-kṣhetre samavetā yuyutsavaḥ\nmāmakāḥ pāṇḍavāśhchaiva kimakurvata sañjaya\n",
    word_meanings: "dhṛitarāśhtraḥ uvācha—Dhritarashtra said; dharma-kṣhetre—the land of dharma; kuru-kṣhetre—at Kurukshetra; samavetāḥ—having gathered; yuyutsavaḥ—desiring to fight; māmakāḥ—my sons; pāṇḍavāḥ—the sons of Pandu; cha—and; eva—certainly; kim—what; akurvata—did they do; sañjaya—Sanjay\n"
end

defmodule Vyasa.Corpus.Gita do
  alias Vyasa.Corpus.Gita

  @chapters Path.join(:code.priv_dir(:vyasa), "static/corpus/gita/chapters.json")
  |> tap(&(@external_resource &1))
  |> File.read!()
  |> Jason.decode!(keys: :atoms)
  |> Enum.map(&struct!(Gita.Chapter, &1))

  @verses Path.join(:code.priv_dir(:vyasa), "static/corpus/gita/sorted_verses.json")
  |> tap(&(@external_resource &1))
  |> File.read!()
  |> Jason.decode!(keys: :atoms)

  def chapters() do
    @chapters
  end

  def chapters(chapter_no) do
    Enum.find(@chapters, &(&1.id == String.to_integer(chapter_no)))
  end

  def verses(chapter_no) when is_integer(chapter_no) do
    @verses[String.to_atom(to_string(chapter_no))]
    |> Enum.map(&struct!(Gita.Verse, &1))
  end

  def verses(chapter_no) do
    @verses[String.to_atom(chapter_no)]
    |> Enum.map(&struct!(Gita.Verse, &1))
  end

  def verse(chapter_no, verse_no) when is_binary(verse_no) and is_binary(chapter_no) do
    IO.puts("checking verse resolution... #{chapter_no}, #{verse_no} \n\n")

    verse = @verses[String.to_atom(chapter_no)]
    |> Enum.find(fn %{:verse_number => verse_num} -> Integer.to_string(verse_num) === verse_no end)

    IO.inspect(verse)

    verse
  end

  def verse(_,_) do
    %Vyasa.Corpus.Gita.Verse{}

  end

end
