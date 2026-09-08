<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="color-scheme" content="dark light">
  <title>{{ ship.nm }} ({{ ship.fl }})</title>
  <style>{{ style }}</style>
</head>
<body>
<main>
  <header>
    <h1 id="ship-name">{{ ship.nm }}</h1>
    <h2 id="ship-points">{{ ship.bp}} pts</h2>
    <h3 id="fleet-name">{{ ship.fl }}</h3>
  </header>

  <figure id="ship-image">
    <img src="{{ image }}">
    <figcaption></figcaption>
  </figure>

  <table id="ship-info">
    <thead><tr>
      <th>Type/Hits</th>
      <th>Speed</th>
      <th>Turns</th>
      <th>Shields</th>
      <th>Armour</th>
      <th>{{ ship.tl }}</th>
    </tr></thead>
    <tbody><tr>
      <td>{{ ship.ty }}/{{ ship.hp }}</td>
      <td>{{ ship.sp }}</td>
      <td>{{ ship.tn }}</td>
      <td>{{ ship.sh }}</td>
      <td>{{ ship.ar }}</td>
      <td>{{ ship.tu }}</td>
    </tr></tbody>
  </table>

  <table id="ship-armament">
    <thead><tr>
      <th>Armament</th>
      <th>Range/Speed</th>
      <th>Firepower/Str</th>
      <th>Fire Arc</th>
    </tr></thead>
    <tbody>
    {% for weapon in ship.aw %}
      <tr>
        <td>{{ weapon.0 }}</td>
        <td>{{ weapon.1 }}</td>
        <td>{{ weapon.2 }}</td>
        <td>{{ weapon.3 }}</td>
      </tr>
    {% endfor %}
    </tbody>
  </table>

  {% if has_sr %}
    <section id="special">
      <h3>Special</h2>
      <div id="special-rules">{{ ship.sr }}</div>
    </section>
  {% endif %}

  {% if has_op %}
    <section id="options">
      <h3>Options</h2>
      <div id="optional">{{ ship.op }}</div>
    </section>
  {% endif %}
</main>
</body>
</html>
