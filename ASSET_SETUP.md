# Asset Placement Guide

`BuildAutomation.cs` khud scene banata hai — lekin usko pata hona chahiye
**kaunsi file kahan hai**. Isliye har downloaded asset ko is exact folder
structure me GitHub par upload karo (GitHub app/website me "Add file →
Upload files" karte waqt path likh sakte ho).

```
Assets/Models/Character/          ← Remy.fbx (WITH skin — character body)
Assets/Models/Animations/Run/     ← Running.fbx (WITHOUT skin)
Assets/Models/Animations/Jump/    ← Jump.fbx (WITHOUT skin)
Assets/Models/Animations/Slide/   ← "Running Slide".fbx (WITHOUT skin)
Assets/Models/Animations/Death/   ← Death/Dying.fbx (WITHOUT skin)

Assets/Models/Wolf/               ← wolf .glb file
Assets/Models/Tiger/              ← Tiger LP .glb file

Assets/Models/Forest/             ← Forest Nature Pack ke SAARE fbx/obj
                                     files yahan seedha daal do, sort
                                     karne ki zarurat nahi — filenames me
                                     "tree"/"rock"/"bush"/"grass"/"log"
                                     jaise words dekh ke script khud
                                     categorize kar lega (obstacles vs
                                     decoration)

Assets/Models/House/              ← House.rar se extract ki hui .fbx
                                     file(s), sab yahan
```

## Important

- **Har folder ka naam exactly waisa hi rakho** jaisa upar likha hai
  (case-sensitive) — script inhi exact paths me dhundta hai.
- File ka naam khud kuch bhi ho sakta hai (Mixamo/Sketchfab jo bhi de),
  bas sahi folder me ho.
- `.rar`/`.zip` files ko extract karke andar ki `.fbx`/`.glb` files
  daalni hain — poora zip/rar mat daalna.
- Rocks/fallen-trees automatically **obstacles** ban jayenge (player se
  takraye to game over). Trees/bushes/grass automatically **background
  decoration** ban jayenge (sirf dikhengi, takrayengi nahi).
- Agar koi ek category (jaise Death animation) na mile, script use
  simply skip kar dega — baaki sab kaam karega, bas wo ek cheez missing
  rahegi (fix baad me kabhi bhi kar sakte ho, wahi folder me file daal
  ke phir se push karke).

## Sound (baad me)

`Assets/Audio/` folder me README already hai — jab music/sfx files
download karoge, wahan daal dena aur `AudioManager` GameObject me
Inspector se wire karna hoga (ye ek kaam Unity Editor maangta hai, ya
main isko bhi automation me add kar sakta hoon jab time aaye — bata
dena).

## Push karne ke baad kya hota hai

`.github/workflows/android-build.yml` GitHub Actions pe chalta hai:
1. `.unitypackage` files (agar `RawPackages/` me ho) extract hoti hain
2. Unity headless mode me khulta hai aur `BuildAutomation.BuildAndroid()`
   chalata hai — ye khud scene banata hai in files se
3. Android APK build hoke **Artifacts** section me milta hai (Actions
   tab → completed run → Artifacts)

Pehli build me koi chhoti error aaye (missing asset, import issue), to
Actions ka **red ❌ log** open karke uska text copy-paste kar dena yahan
— us hisaab se fix kar dunga.
