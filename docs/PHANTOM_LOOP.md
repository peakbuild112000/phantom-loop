# PHANTOM LOOP — design doc

## Concept

Une escape room à boucles temporelles. Chaque tentative est enregistrée puis
rejouée par un fantôme. Les énigmes demandent plusieurs actions simultanées :
le joueur doit donc « se faire coopérer » par ses copies passées.

* **Durée cible :** 50 h (objectif PHANTOM : 50 fragments-hours).
* **Moteur :** Godot 4.6.1 stable, renderer GL Compatibility.
* **Cibles :** desktop + WebGL2 (export Godot `Web`).
* **Joueurs :** 1 (mode coop en stretch goal).

## Loop

1. Entrer dans une salle, 30 s de timer.
2. Observer les plaques / mécanismes.
3. Résoudre une partie de l'énigme, échouer ou laisser le timer expirer.
4. La tentative devient un fantôme qui rejoue cycle après cycle.
5. Empiler les fantômes jusqu'à ce que toutes les conditions soient vraies en même temps.
6. Passer à la salle suivante.

## Règles de simulation

* Tick fixe à 60 Hz, avec accumulateur et maximum 5 sous-pas par frame.
* Snapshot = `{ position: Vector3, action: bool }` par tick.
* Replay par snapshot (pas par Input) : déterministe côté WebGL, pas de dépendance
  au moteur physique pour la relecture.
* Les fantômes sont des `CharacterBody3D` cinématiques : ils entrent dans les
  `Area3D` logiques mais ne poussent pas le joueur.
* Reset de salle : positions d'origine, timer, état des plaques, collision de porte.

## Salles du MVP

| # | Nom | Mécanique | Fantômes requis |
|---|-----|-----------|-----------------|
| 1 | **L'Antichambre** | 3 plaques à activer en même temps | 2 |
| 2 | **Le Couloir** | plaque + porte qui se referme après 2 s | 2 |
| 3 | **La Balance** | clé à porter sur une plaque pendant qu'un autre tient un levier | 3 |
| 4 | **La Sortie** | combinaison des trois mécaniques précédentes | 3+ |

## Architecture (cible)

```
scenes/
  main.tscn          # racine, script phantom_loop.gd (prototype)
  rooms/room_*.tscn  # salles (à venir)
scripts/
  phantom_loop.gd    # boucle, enregistrement, replay, reset
  ghost.gd           # rendu spectral, traînée
  puzzle/*.gd        # plaques, portes, leviers, faisceaux
shaders/
  ghost.gdshader
tests/
  loop_test.gd       # vérifie 1 enregistrement = 1 fantôme rejoué
```

## Planning 50 h

| Bloc | Heures | Contenu |
|------|--------|---------|
| Prototype boucle + fantôme | 8 | snapshot, replay, reset, HUD |
| Salles 1–4 | 12 | mécaniques, level design, signaux visuels |
| Polish | 10 | shaders, audio, feedback, animations |
| Coop WebRTC | 12 | signalisation, synchro des fantômes, lobby |
| Tests + soumission | 8 | tests Godot, export Web, README, vidéo démo |

## Stretch goals

- Générateur de salles seedé + partage de seed.
- Classement « moins de boucles » stocké en `user://`.
- Fantômes corrompus : un fantôme sur N rejoue une action différente.
- Bande-son qui se déforme à chaque boucle (pitch + reverb).
- Mode coop : chaque joueur voit les fantômes de tous les joueurs.

## Pourquoi ça se démarque

Le thème PHANTOM est la mécanique elle-même, pas un habillage. La démo se
comprend en 2 secondes : on voit son propre fantôme refaire le geste à côté de soi.
