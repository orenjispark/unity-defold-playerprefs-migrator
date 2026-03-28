# Unity → Defold Save Migration (WebGL)

> **This is a test repo.** It's not a production library — just a working demo to explore whether Unity WebGL save data can be read by a Defold WebGL game running in the same browser.

---

## What is this?

When you ship a WebGL game in Unity and later want to move it to Defold, your players already have save data sitting in the browser. This repo tests one approach to reading that data automatically, so players don't lose their progress.

---

## How it works (simply)

1. **Unity** saves player data as a JSON string inside the browser's built-in storage (IndexedDB).
2. **A small JS snippet** (in the Defold `index.html`) knows how to find and read that data.
3. **Defold** calls that JS snippet on startup, gets the JSON back, and can use it to restore the player's save.

---

## How the data flows

```
Browser storage (IndexedDB)
  └── Unity left a save file here: /idbfs/<hash>/PlayerPrefs
          │
          │  JS reads the binary file and finds the right key
          ▼
  window.UnityMigrator  (JS object in index.html)
          │
          │  Defold's Lua calls the JS and waits for the result
          ▼
  migrator.lua  (Lua module in the Defold project)
          │
          │  Returns a plain Lua table to your game code
          ▼
  Your game  →  load the player's old level, score, etc.
```

---

## Repo layout

```
public/
  unity-game/    ← pre-built Unity WebGL game 
  defold-game/   ← pre-built Defold WebGL game 

_game-projects/
  unity/         ← Unity source
  defold/        ← Defold source
    main/
      migrator.lua       ← the Lua module that does the reading
      main.gui_script    ← example of how to call it
```

---

## Trying it out

1. Run the dev server:
   ```sh
   npm run dev
   ```
2. Open the URL in your browser. You'll see the **Unity game** by default.
3. Click **Save** in the Unity game to write some save data.
4. Click the **button in the top-left corner** to switch to the Defold game.
5. The Defold game will automatically read the Unity save and display it on screen.

---