<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="color-scheme" content="dark light">
  <title>Battlefleet Gothic Ship Profiles</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="assets/style.css">
</head>
<body>
<main>
  <header>
    <h1>Battlefleet Gothic Ship Profiles</h1>
  </header>
  <aside>
    <p>This site contains mobile-friendly HTML profile pages for all the ships in
      the <em>Battlefleet Gothic: Remastered</em> Fleets Book. These pages are
      built using images taken from the PDF and statistical data taken from the
      <a href="https://bfgtools.kuldare.com/">Gothic Fleet Registry</a>.</p>
  </aside>

  <nav><ul>
    <li>Jump to:</li>
    {% for fleet in fleets %}
      <li>
        <a href="#{{ fleet.slug }}">{{ fleet.name }}</a>
      </li>
    {% endfor %}
  </ul></nav>

  {% for fleet in fleets %}
    <article>

      <a name="{{ fleet.slug }}"></a>
      <h2>{{ fleet.name }}</h2>

      {% if fleet.counts.Battleship > 0 %}
        <section>
          <h3>Battleships</h3>
          <ul>
            {% for ship in fleet.ships.Battleship %}
              <li><a href="{{ ship.href }}">{{ ship.name }}</a></li>
            {% endfor %}
          </ul>
        </section>
      {% endif %}

      {% if fleet.counts.Cruiser > 0 %}
        <section>
          <h3>Cruisers</h3>
          <ul>
            {% for ship in fleet.ships.Cruiser %}
              <li><a href="{{ ship.href }}">{{ ship.name }}</a></li>
            {% endfor %}
          </ul>
        </section>
      {% endif %}

      {% if fleet.counts.Escort > 0 %}
        <section>
          <h3>Escorts</h3>
          <ul>
            {% for ship in fleet.ships.Escort %}
              <li><a href="{{ ship.href }}">{{ ship.name }}</a></li>
            {% endfor %}
          </ul>
        </section>
      {% endif %}

      {% if fleet.counts.Defence > 0 %}
        <section>
          <h3>Defences</h3>
          <ul>
            {% for ship in fleet.ships.Defence %}
              <li><a href="{{ ship.href }}">{{ ship.name }}</a></li>
            {% endfor %}
          </ul>
        </section>
      {% endif %}

      {% if fleet.counts.Ground > 0 %}
        <section>
          <h3>Ground Assets</h3>
          <ul>
            {% for ship in fleet.ships.Ground %}
              <li><a href="{{ ship.href }}">{{ ship.name }}</a></li>
            {% endfor %}
          </ul>
        </section>
      {% endif %}

    </article>
  {% endfor %}
</main>

<script src="//analytics.tau.uk.com"></script>
</body>
</html>
