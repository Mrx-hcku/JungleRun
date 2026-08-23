# Jungle Escape Runner — Android Build (GitHub Actions)

Ye repo [game-ci/unity-builder](https://github.com/game-ci/unity-builder) use karke
GitHub Actions par Android build (.apk / .aab) automatically banata hai, jab bhi
`main` branch par push hoga (ya manually "Run workflow" se).

## Setup steps

### 1. Is folder ko apne Unity project ke root me merge karo
```
YourUnityProject/
├── Assets/
│   ├── Scripts/        ← is repo ke .cs files yahan hain
│   ├── Prefabs/
│   └── Scenes/
├── ProjectSettings/     ← Unity khud generate karta hai, isko bhi commit karo
├── .github/workflows/android-build.yml
├── .gitignore
```
**Important**: `Library/` folder kabhi commit mat karo (`.gitignore` me already excluded hai) —
Unity use dobara generate kar leta hai, aur GitHub Actions cache use karega.

### 2. Unity license ka secret banao (required)
GitHub Actions ko Unity activate karne ke liye license chahiye. Free/Personal license ke liye:

1. Local machine par Unity Hub → Unity install karo (same version jo project use kar raha hai)
2. `game-ci/unity-request-activation-file` action se `.alf` file generate karo, ya
   [game-ci docs](https://game.ci/docs/github/activation) follow karo
3. `.alf` file Unity ke [manual activation page](https://license.unity3d.com/manual) par upload karo → `.ulf` file milegi
4. `.ulf` file ka content copy karke GitHub repo → **Settings → Secrets and variables → Actions** me
   `UNITY_LICENSE` naam se secret banao

### 3. GitHub Secrets add karo
Repo → Settings → Secrets and variables → Actions → **New repository secret**:

| Secret name | Value |
|---|---|
| `UNITY_LICENSE` | `.ulf` file ka pura content |
| `UNITY_EMAIL` | Tumhara Unity account email |
| `UNITY_PASSWORD` | Tumhara Unity account password |

**Signed release build ke liye (optional, agar Play Store par upload karna hai):**

| Secret name | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i your.keystore` output |
| `ANDROID_KEYSTORE_NAME` | keystore ka filename, e.g. `release.keystore` |
| `ANDROID_KEYSTORE_PASS` | keystore password |
| `ANDROID_KEYALIAS_NAME` | key alias name |
| `ANDROID_KEYALIAS_PASS` | key alias password |

Agar ye 5 keystore secrets nahi doge, workflow ab bhi chalega — Unity ek debug-signed APK banayega
(testing ke liye theek hai, Play Store upload ke liye nahi).

### 4. Push karo
```bash
git add .
git commit -m "Add Android build workflow"
git push origin main
```
GitHub → repo → **Actions** tab me build progress dikhega. Success ke baad
**Artifacts** section se `.apk`/`.aab` download kar sakte ho.

### 5. AAB chahiye (Play Store ke liye) instead of APK
`.github/workflows/android-build.yml` me ye line change karo:
```yaml
androidExportType: androidAppBundle
```

## Step 0: Asset placement (READ THIS FIRST)

Downloaded character/animal/environment files ko exact folders me daalna
hai taaki automation unhe dhundh sake — poora guide **`ASSET_SETUP.md`**
me hai. Ye step sabse pehle karo, code push karne se pehle.

## Using Asset Store `.unitypackage` files (no Editor needed)

`.unitypackage` files ek gzipped tar archive hote hain — inhe manually extract
karne ki koshish mat karo. Bas:

1. Asset Store se downloaded `.unitypackage` file ko is repo ke `RawPackages/`
   folder me daal do (GitHub app/website se upload karke, koi extraction nahi)
2. Push karo — workflow automatically `Tools/extract_unitypackage.sh` chala ke
   sahi `Assets/` structure me unpack kar dega (correct paths + `.meta` files
   ke saath), Unity build shuru hone se pehle
3. FBX files (Mixamo/Sketchfab se) ke liye ye step zaroori nahi — unhe seedha
   `Assets/Models/` (ya jahan chaho) me upload kar do, Unity build ke time
   khud import kar lega

## Notes
- `main` branch pe push hone par auto-build chalega. Manually trigger karne ke liye
  Actions tab → "Build Android" workflow → **Run workflow** button.
- Build Ubuntu runner par chalta hai — free GitHub-hosted runner minutes use hote hain
  (public repo = unlimited free, private repo = monthly quota).
- First build slow hoga (Library cache nahi hai), baad ke builds cache ki wajah se fast honge.
