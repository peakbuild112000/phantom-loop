# PHANTOM LOOP 👻

Un prototype d'escape room à boucles temporelles pour **PHANTOM**, le hackathon
Hack Club (février 2027). À chaque boucle, tes actions sont rejouées par un
fantôme. Résous les salles en coopérant avec tes propres copies.

* **Moteur :** Godot 4.6.1 stable
* **Cibles :** Desktop + WebGL2
* **Repo :** <https://github.com/peakbuild112000/phantom-loop>
* **Design :** [docs/PHANTOM_LOOP.md](docs/PHANTOM_LOOP.md)

> ⚠️ Ce dossier est volontairement **un squelette** : le code du jeu est fourni
> dans [docs/COPY_ME.md](docs/COPY_ME.md) et doit être copié à la main dans les
> dossiers indiqués. Rien n'est généré automatiquement dans `scripts/`,
> `scenes/` ou `shaders/`.

## Démarrage

1. Copie les trois blocs de [docs/COPY_ME.md](docs/COPY_ME.md) :
   - `scripts/phantom_loop.gd`
   - `shaders/ghost.gdshader`
   - `scenes/main.tscn`
2. Ouvre ce dossier avec Godot 4.6.1.
3. Appuie sur **F6** (ou le bouton Play).

Commande équivalente :

```powershell
$godot = "C:\Users\PC\Desktop\Godot\Godot_v4.6.1-stable_win64_console.exe"
$project = "C:\Users\PC\Documents\project-1\phantom-loop"

& $godot --headless --path $project --editor --quit
& $godot --path $project
```

## Commandes

| Touche | Action |
|--------|--------|
| `W A S D` | Marcher |
| Souris | Regarder |
| `E` | Maintenir l'action (les fantômes ne retiennent que ce geste) |
| `Esc` | Relâcher la souris |
| `R` | Rejouer après avoir gagné |

## Export Web

Depuis Godot : **Project → Export → Web** (le preset est déjà configuré),
ou en ligne de commande :

```powershell
& $godot --headless --path $project --export-release "Web" "$project\build\web\index.html"
```

Le résultat est dans `build/web/`. Serve-le avec un serveur statique ;
`file://` ne fonctionne pas avec WebGL.

Chaque push sur `main` déclenche aussi `.github/workflows/export-web.yml`, qui
exporte le jeu et le publie sur GitHub Pages :
<https://peakbuild112000.github.io/phantom-loop/>

## Hackatime

Le fichier `.wakatime-project` donne le nom `phantom-loop` à tes sessions de
code, ce qui rend le temps suivi lisible dans Hackatime. Copier le code toi-même
dans l'éditeur est volontaire : c'est du code que tu écris vraiment.

## Structure

```
phantom-loop/
├── project.godot          # config Godot + inputs (WASD/E/R)
├── export_presets.cfg     # preset Web
├── icon.svg
├── docs/
│   ├── COPY_ME.md         # code à copier
│   └── PHANTOM_LOOP.md    # design doc + planning 50 h
├── scripts/               # ← tu copies phantom_loop.gd ici
├── scenes/                # ← tu copies main.tscn ici
├── shaders/               # ← tu copies ghost.gdshader ici
└── .github/workflows/     # export Web + GitHub Pages
```

## License

MIT — voir [LICENSE](LICENSE).
