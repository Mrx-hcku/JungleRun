# Jungle Escape Runner — Godot Edition

Unity se Godot 4 pe shift kiya gaya, kyunki Unity ka headless GitHub Actions
build license activation maangta hai (jo bina PC/Unity Editor ke possible
nahi tha). Godot ko koi license/activation nahi chahiye.

## Kya real hai (tumhare actual JungleRun repo ke assets se wired)
- **Player** — `Assets/Models/Character/Remy.fbx` (`Scenes/Player.tscn`)
- **Wolf** — `Assets/Models/Wolf/low-poly_wolf.glb`
- **Tiger** — `Assets/Models/Tiger/tiger_lp.glb`
- **House / victory zone** — `Assets/Models/House/Models/House.fbx`
- Log/Rock obstacles aur coin abhi bhi **placeholder shapes** hain (repo
  mein inke liye dedicated model nahi mila — path bata do to wire kar dunga)
- Ground/environment (Forest pack) abhi plain green floor hai — Forest pack
  ke props scatter karna baaki hai
- Audio abhi silent — folders bane hain, files daalte hi auto-wire (neeche)

## Animations — koi PC/Editor NAHI chahiye (correction)
Pehle maine bola tha ki Run/Jump/Slide/Death animations Editor ke bina
retarget nahi ho sakti — ye galat tha. `Scripts/Player.gd` mein ab ek
runtime loader hai (`_load_and_attach_animations`) jo game start hote hi:
1. Har animation FBX ko load karta hai
2. Uske bone tracks nikaal ke Remy ke apne skeleton pe re-point karta hai
   (Mixamo se export hone ki wajah se sab same bone names use karte hain)
3. Player ke AnimationPlayer mein attach kar deta hai

Ye poora kaam **PC/Editor ke bina, sirf code se** hota hai — bas repo push
karo, GitHub Actions APK banayegi, aur pehli baar game khulte hi animations
khud-ba-khud judd jayengi.

Agar kisi wajah se bone naming match nahi hui (rare, but possible), game
crash nahi hogi — character static rahega us specific clip ke liye, aur
Godot console/log mein warning aayegi bata ke kaunsi clip fail hui. Wo
message mujhe bhej dena, error fix kar dunga (phir bhi PC ki zaroorat nahi
padegi).

## Audio auto-wiring
Files `.ogg`/`.wav`/`.mp3` seedha inn folders mein daal do — koi code/scene
change nahi chahiye, filename kuch bhi ho sakta hai:
- `Assets/Audio/footstep/`
- `Assets/Audio/jump/`
- `Assets/Audio/slide/`
- `Assets/Audio/death/`
- `Assets/Audio/growl/` (wolf/tiger attack)
- `Assets/Audio/coin/`
- `Assets/Audio/gameover/`
- `Assets/Audio/victory/`
- `Assets/Audio/jungle/` (background music loop)
- `Assets/Audio/home/` (victory/home music loop)

## Build kaise hoga
`.github/workflows/android-build.yml` `barichello/godot-ci` Docker image use
karta hai — usme Godot + export templates + ek default debug keystore
already installed hai, isliye koi Unity-jaisa license file/secret nahi
chahiye. Bas `main` branch pe push karo, Actions tab mein
**jungle-escape-runner-apk** artifact ban jayega — download karke phone pe
install kar lena (unknown sources allow karna padega).

## Package name
Abhi `com.mycompany.jungleescape` set hai (`export_presets.cfg` mein) —
badalna ho to wahi file mein `package/unique_name` edit kar dena.
