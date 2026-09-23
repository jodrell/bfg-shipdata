<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="color-scheme" content="light">
  <title>{{ ship.nm }} ({{ ship.fl }})</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>

    @page {
      size: A5 landscape;
    }

    @font-face {
      font-family: 'Minion Pro Regular';
      font-style: normal;
      font-weight: normal;
      src: local('Minion Pro Regular'), url('../assets/MinionPro-Regular.woff') format('woff');
    }

    @font-face {
        font-family: 'MachineItcDEE';
        src: url('../assets/MachineItcDEE.ttf') format('truetype');
        font-weight: normal;
        font-style: normal;
        font-display: swap;
    }

    *,html,body,div,table,th,td,ul,li {
      font-family: 'Minion Pro Regular', 'Times New Roman', Times, serif;
    }

    ul {
      margin:0;
      padding:0 0 0 2em;
    }
  </style>
</head>
<body style="background-color:white;color:black">

  {% assign width = 21 %}
  {% assign height = 14.8 %}
  {% assign column_width = 4 %}

  <div style="width:{{ width }}cm;height:{{ height }};margin:auto;padding:0.5cm;overflow:hidden">

    <div style="line-height:1;font-size:7.5mm;font-weight:bold;font-family:MachineItcDEE;text-transform:uppercase">{{ ship.nm }}</div>

    <div style="display:flex; font-size:large;margin:0.25cm 0 0.25cm 0">
      <div style="flex: 1 1 auto">{% if is_unique %}&nbsp;{% else %}Name:{% endif %}</div>
      <div style="flex: 0 0 3cm;text-align">Ld:</div>
      <div style="flex: 0 0 auto;text-align:right;color:#eee">{{ ship.bp }}&nbsp;</div>
      <div style="flex: 0 0 auto;text-align:left">pts</div>
    </div>

    <div style="display:flex">

      <div style="flex: 0 0 {{ column_width }}cm">
        <div style="padding:2mm 1mm 0 1mm;font-weight:bold">Type</div>
        <div style="padding:1mm;background-color:#eee">{{ ship.ty }}</div>
        <div style="padding:2mm 1mm 0 1mm;font-weight:bold">Speed</div>
        <div style="padding:1mm;background-color:#eee">{{ ship.sp }}</div>
        <div style="padding:2mm 1mm 0 1mm;font-weight:bold">Turns</div>
        <div style="padding:1mm;background-color:#eee">{{ ship.tn }}</div>
      </div>

      <div style="flex: 1 1 auto;padding:0.25cm">
        {% if has_image %}
          <img src="{{ image }}" style="display:block;max-width:100%;max-height:12em;margin:0 auto 0.25cm auto">
        {% endif %}

        {% if ship.hp > 1 %}

          {% assign range = (1..ship.hp) %}

          <table style="margin:auto"><tbody><tr>
            {% for i in range %}
              <td style="border:1px solid black;width:8mm;height:8mm;padding:0;vertical-align:middle;text-align:center;color:#eee">
                {{ i }}
              </td>
              {% if i == crippled_at %}
                <td>|</td>
              {% endif %}
            {% endfor %}
          </tr></tbody></table>
        {% endif %}
      </div>

      <div style="flex: 0 0 {{ column_width }}cm">
        <div style="padding:2mm 1mm 0 1mm;font-weight:bold">Shields</div>
        <div style="padding:1mm;background-color:#eee">{{ ship.sh }}</div>
        <div style="padding:2mm 1mm 0 1mm;font-weight:bold">Armour</div>
        <div style="padding:1mm;background-color:#eee">{{ ship.ar }}</div>
        <div style="padding:2mm 1mm 0 1mm;font-weight:bold">{{ ship.tl }}</div>
        <div style="padding:1mm;background-color:#eee">{{ ship.tu }}</div>
      </div>
    </div>

    {% if has_armament %}
      <table style="margin-top:0.125cm;width:100%;border-collapse: collapse">
        <thead><tr style="background-color:black;color:white">
          <th style="font-weight:bold;font-family:MachineItcDEE;text-transform:uppercase;text-align:center;border:1px solid black">Armament</th>
          <th style="font-weight:bold;font-family:MachineItcDEE;text-transform:uppercase;text-align:center;border:1px solid black">Range/Speed</th>
          <th style="font-weight:bold;font-family:MachineItcDEE;text-transform:uppercase;text-align:center;border:1px solid black">Firepower/Str</th>
          <th style="font-weight:bold;font-family:MachineItcDEE;text-transform:uppercase;text-align:center;border:1px solid black">Fire Arc</th>
        </tr></thead>
        <tbody>
        {% for weapon in ship.aw %}
          <tr>
            <td style="text-align:center;border:1px solid black">{{ weapon.0 }}</td>
            <td style="text-align:center;border:1px solid black">{{ weapon.1 }}</td>
            <td style="text-align:center;border:1px solid black">{{ weapon.2 }}</td>
            <td style="text-align:center;border:1px solid black">{{ weapon.3 }}</td>
          </tr>
        {% endfor %}
        </tbody>
      </table>
    {% endif %}

    {% if has_sr %}
      <div style="font-size:small;margin:0.25cm 0 0 0">
        <strong>Special:</strong> {{ ship.sr }}
      </div>
    {% endif %}

    {% if has_op %}
      <div style="font-size:small;margin:0.25cm 0 0 0">
        <strong>Options</strong>: {{ ship.op }}
      </div>
    {% endif %}
</div>
</body>
</html>
