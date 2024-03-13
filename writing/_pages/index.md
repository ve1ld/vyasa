---
layout: page
title: Home
id: home
permalink: /
---

# Good morning! 🌅

  Welcome to Vyasa! <span style="font-weight: bold">[[Your first note]]</span> to get started on your exploration.

Find us [on GitHub here](https://github.com/ve1ld/vyasa).

<strong>Past Writings</strong>

<ul>
  {% assign recent_notes = site.notes | sort: "last_modified_at_timestamp" | reverse %}
  {% for note in recent_notes limit: 5 %}
    <li>
      {{ note.last_modified_at | date: "%Y-%m-%d" }} — <a class="internal-link" href="{{ site.baseurl }}{{ note.url }}">{{ note.title }}</a>
    </li>
  {% endfor %}
</ul>

<style>
  .wrapper {
    max-width: 46em;
  }
</style>
