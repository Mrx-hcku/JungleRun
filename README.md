# Jungle Escape Runner — Open World Edition

Pehle wala version lane-swipe endless runner tha (Temple Run style) —
tumhare ask ke hisaab se ab **open-world free-roam** mein rewrite kiya hai.

## Controls
- **Left thumb, joystick** — screen ke left-bottom hisse mein kahin bhi touch
  karo, ek floating joystick appear hoga, usse move karo (jungle ke aar-paar
  free movement, koi fixed lane nahi)
- **Swipe (kahi bhi baaki screen pe)** — camera ko orbit karta hai (drag
  left/right = look around, drag up/down = camera angle change), SpringArm3D
  automatically zoom-in kar deta hai agar camera kisi cheez se clip ho rahi ho

## Gameplay
- Jungle ek circular open area hai (radius ~60 units), player center mein
  start karta hai
- Isme scattered hain: obstacles (log/rock — touch = death), coins
  (cosmetic collectible abhi), Wolf/Tiger (chase predators)
- **Wolf/Tiger:** idle rehte hain jab tak player unki detection radius mein
  na aaye (Wolf ~11 units, Tiger ~14 units) — **dikhte hi seedha chase karna
  shuru kar dete hain**, paas aane par player ko catch kar lete hain
  (`Scripts/PredatorAI.gd`)
- **Goal:** jungle ke kinare pe kahin (random position) House hai — wahan
  pahunchte hi victory

## Night atmosphere
- Dim moonlight (bluish directional light), low ambient light, dense fog —
  `Scenes/Main.tscn` ke `WorldEnvironment` mein set hai. Chaho to
  `fog_density` aur `light_energy` values tweak kar sakte ho

## Kya real hai (tumhare actual JungleRun repo ke assets se wired)
- **Player** — `Assets/Models/Character/Remy.fbx`
- **Wolf** — `Assets/Models/Wolf/low-poly_wolf.glb`
- **Tiger** — `Assets/Models/Tiger/tiger_lp.glb`
- **House / victory zone** — `Assets/Models/House/Models/House.fbx`
- Log/Rock obstacles abhi bhi **placeholder shapes** hain (repo mein inke
  liye dedicated model nahi mila — path bata do to wire kar dunga)
- Ground abhi plain dark floor hai — Forest pack ke trees/plants scatter
  karke actual "dense jungle" feel add karna baaki hai (bata do exact model
  paths, `WorldPopulator.gd` mein prop-scatter add kar dunga)
- Audio abhi silent — folders bane hain, files daalte hi auto-wire (neeche)

## Animations — PC/Editor NAHI chahiye
`Scripts/Player.gd` mein runtime loader hai jo game start hote hi Run/Jump/
Slide/Death Mixamo animations ko Remy ke skeleton pe khud retarget kar
deta hai (bone names Mixamo se same hone ki wajah se). Koi Editor step
nahi chahiye. Agar koi clip attach na ho paye, Godot console mein warning
aayegi (game crash nahi hogi) — wo message bhej dena.

## Audio auto-wiring
Files `.ogg`/`.wav`/`.mp3` seedha inn folders mein daal do — koi code/scene
change nahi chahiye:
- `Assets/Audio/footstep/`, `jump/`, `slide/`, `death/`, `growl/` (predator
  attack), `coin/`, `gameover/`, `victory/`, `jungle/` (bg music loop),
  `home/` (victory music loop)

## Build kaise hoga
`.github/workflows/android-build.yml` `barichello/godot-ci` Docker image use
karta hai — Godot + export templates + debug keystore already installed.
Bas `main` branch pe push karo, Actions tab mein
**jungle-escape-runner-apk** artifact ban jayega.

## Package name
`com.mycompany.jungleescape` (`export_presets.cfg` mein) — badalna ho to
`package/unique_name` edit kar dena.
