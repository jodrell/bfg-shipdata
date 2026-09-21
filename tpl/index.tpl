<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="color-scheme" content="dark light">
  <title>Battlefleet Gothic Ship Profiles</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="assets/style.css">
  <link rel="shortcut icon" href="assets/favicon.png">
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

  <hr>

  <nav>
    <ul>
      <li>Jump to:</li>
      {% for fleet in fleets %}
        <li>
          <a href="#{{ fleet.slug }}">{{ fleet.name }}</a>
        </li>
      {% endfor %}
    </ul>
  </nav>

  {% for fleet in fleets %}
    <hr>

    <article>

      <a name="{{ fleet.slug }}"></a>
      <h2>{{ fleet.name }}</h2>

      {% if fleet.counts.Battleship > 0 %}
        <section>
          <h3>Battleships</h3>
          <table><tbody>
            {% for ship in fleet.ships.Battleship %}
              <tr>
                <td class="index-ship-name"><a href="{{ ship.href }}">{{ ship.name }}</a></td>
                <td class="index-ship-points">
                  {% if ship.bp > 0 %}
                    {{ ship.bp }} pts
                  {% else %}
                    -
                  {% endif %}
                </td>
              </tr>
            {% endfor %}
          </tbody></table>
        </section>
      {% endif %}

      {% if fleet.counts.Grand_Cruiser > 0 %}
        <section>
          <h3>Grand Cruisers</h3>
          <table><tbody>
            {% for ship in fleet.ships.Grand_Cruiser %}
              <tr>
                <td class="index-ship-name"><a href="{{ ship.href }}">{{ ship.name }}</a></td>
                <td class="index-ship-points">
                  {% if ship.bp > 0 %}
                    {{ ship.bp }} pts
                  {% else %}
                    -
                  {% endif %}
                </td>
              </tr>
            {% endfor %}
          </tbody></table>
        </section>
      {% endif %}

      {% if fleet.counts.Cruiser > 0 %}
        <section>
          <h3>Cruisers</h3>
          <table><tbody>
            {% for ship in fleet.ships.Cruiser %}
              <tr>
                <td class="index-ship-name"><a href="{{ ship.href }}">{{ ship.name }}</a></td>
                <td class="index-ship-points">
                  {% if ship.bp > 0 %}
                    {{ ship.bp }} pts
                  {% else %}
                    -
                  {% endif %}
                </td>
              </tr>
            {% endfor %}
          </tbody></table>
        </section>
      {% endif %}

      {% if fleet.counts.Escort > 0 %}
        <section>
          <h3>Escorts</h3>
          <table><tbody>
            {% for ship in fleet.ships.Escort %}
              <tr>
                <td class="index-ship-name"><a href="{{ ship.href }}">{{ ship.name }}</a></td>
                <td class="index-ship-points">
                  {% if ship.bp > 0 %}
                    {{ ship.bp }} pts
                  {% else %}
                    -
                  {% endif %}
                </td>
              </tr>
            {% endfor %}
          </tbody></table>
        </section>
      {% endif %}

      {% if fleet.counts.Defence > 0 %}
        <section>
          <h3>Defences</h3>
          <table><tbody>
            {% for ship in fleet.ships.Defence %}
              <tr>
                <td class="index-ship-name"><a href="{{ ship.href }}">{{ ship.name }}</a></td>
                <td class="index-ship-points">
                  {% if ship.bp > 0 %}
                    {{ ship.bp }} pts
                  {% else %}
                    -
                  {% endif %}
                </td>
              </tr>
            {% endfor %}
          </tbody></table>
        </section>
      {% endif %}

      {% if fleet.counts.Ground > 0 %}
        <section>
          <h3>Ground Assets</h3>
          <table><tbody>
            {% for ship in fleet.ships.Ground %}
              <tr>
                <td class="index-ship-name"><a href="{{ ship.href }}">{{ ship.name }}</a></td>
                <td class="index-ship-points">
                  {% if ship.bp > 0 %}
                    {{ ship.bp }} pts
                  {% else %}
                    -
                  {% endif %}
                </td>
              </tr>
            {% endfor %}
          </tbody></table>
        </section>
      {% endif %}

    </article>
  {% endfor %}
</main>

<hr>

<footer>
  <div style="text-align:center;font-style:italic;white-space:nowrap">
    <a href="https://github/com/jodrell/bfg-shipdata">GitHub</a>
    &middot;
    Brought to you by <a href="https://jodrell.org">𝔍𝔬𝔡𝔯𝔢𝔩𝔩.𝔬𝔯𝔤</a>
  </div>
</footer>

<script src="//analytics.tau.uk.com"></script>
</body>
</html>
