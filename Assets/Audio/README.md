# Audio files go here

Files ka **naam** important hai — automation (`BuildAutomation.cs`)
filename me keyword dhundh ke khud sahi slot me daal deta hai, koi
Editor drag-drop nahi karna. Format: `.mp3`, `.wav`, ya `.ogg`.

File ke naam me ye keyword hona chahiye (case-insensitive, kahin bhi
naam ke andar):

| Filename me ye keyword ho | Jaata hai kis slot me |
|---|---|
| `footstep` ya `run` | Footstep run loop |
| `jump` | Jump sound |
| `slide` | Slide sound |
| `death` ya `dying` | Death sound |
| `growl` ya `roar` | Animal growl/attack |
| `coin` ya `collect` | Coin collect |
| `gameover` (ya `game_over` / `game-over`) | Game Over sound |
| `victory` ya `win` | Victory/level-complete sound |
| `jungle` | Jungle background music |
| `home` ya `safe` | Home/safe-zone background music |

**Examples**: `player_jump.mp3`, `wolf_growl.wav`, `jungle_theme.mp3` —
sab chalenge, bas keyword kahin naam me ho.

Bas files is folder me daal do aur push kar do — agli build me
automatically wire ho jayengi. Koi match na mile to wo slot khali
rahega, baaki game normally chalega (crash nahi hoga).
