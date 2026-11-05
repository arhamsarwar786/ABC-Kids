# Flow map

Visual reference: `references/app-flow-board.png` (18-screen board). Where the
board conflicts with the written requirements, the requirements win:
parent gate is a written multiplication question (not hold-to-continue),
Magic Trail uses real three-stroke **m** geometry, no speech-speed control.

```
App start ─ storage open + migration + asset manifest
   ├─ first run ──▶ Welcome ──Play──▶ Shell          (guest learner already exists)
   │                 └─🔒 Grown-ups ─gate─▶ Learners (optional setup)
   └─ returning ───▶ Shell

Shell tabs: [Home] [Games] [My Stickers]   (tabs hidden during activities)

Sound order: all 26 letters (default s a t p i n m d g o c k e u r h b f l j v w x y z q;
parent can choose “m first” or “A to Z”). Older saves keep their order and gain the rest.

Home (toddler-simple: one Play button + big picture tiles, one word each)
 ├─ Play / Keep going (resume checkpoint) · small “Start again”
 ├─ ABC ─▶ all 26 letters (Aa tiles) ─▶ letter book: big letter, picture, hear word,
 │          hear letter name, ◀ ▶ through A–Z (swipe too), “Play with x” when that lesson is open
 ├─ Sounds ─▶ Sound Path (new / explored / practising) ─▶ Lesson
 ├─ Games ─▶ Games tab
 ├─ Numbers ─▶ Explore 1–10 · Count and Match
 ├─ Shapes ─▶ Explore · Shape Match · Find the Shape
 └─🔒 Grown-ups ─gate─▶ Parent dashboard

Lesson (checkpoint saved at each step)
 Meet the Sound ─▶ Listen & Discover ─▶ game 1 ─▶ game 2 [─▶ game 3 if “growing”]
   [─▶ Magic Trail only if a grown-up turns tracing on]
   ─▶ You did it! (sticker, idempotent) ─▶ Next sound ─▶ next Lesson
                                        └▶ Finish for now ─▶ See you soon ─▶ Home / Play again
 Break reminder at step/round boundaries: Finish for now (saves next step) · Keep playing
 Back from any step: returns to where the lesson was opened; Home shows Keep going
 Keep going starts a fresh lesson instead when a grown-up changed readiness, tracing or
   letter case, or a saved game can no longer run (e.g. device voice turned off)
 Guided mode opens finished sounds + the next one (Sound Path and letter book use the same rule);
   free play opens every letter

Games tab (only games that can run) ─tap─▶ Game starts at once (familiar sounds, level from
  preferences, demo the first time) ─▶ Great playing! (sticker on first finish)
                                                            ├─ Play again
                                                            ├─ More games
                                                            └─ Home

Inside every game
 demo (skippable) → prompt → input → feedback; wrong: replay → fewer choices/hint → show answer
 Pause button / app backgrounded → Paused overlay → Keep playing (explicit) · Finish for now
 Audio failure for an essential prompt → Try again · Choose another activity

Parent dashboard
 ├─ Learners: add / switch / edit / reset* / delete*   (*fresh gate + named confirmation)
 ├─ Learning preferences (per learner)
 ├─ Sound and accessibility (device)
 ├─ Progress details · Content status · Privacy · Help
```
