<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="color-scheme" content="dark light">
  <title>Index</title>
  <style>{{ style }}</style>
</head>
<body>
<main>
  {% for fleet in fleets %}
    <article>

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
</body>
</html>
