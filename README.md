# Pikachu Volleyball - DCL Final Project

This repository contains the source code and resources for the **Pikachu Volleyball** game, developed as part of the Digital Circuit Lab (DCL) Final Project. The project involves a volleyball game where the player controls a Pikachu character, competing against a computer-controlled opponent.

## Team Members
- **111550076** 楊子賝
- **111550080** 曾煥宗
- **111550100** 邱振源
- **111550124** 陳燁

## Project Overview
Pikachu Volleyball is a one-player game where the player controls Pikachu using four buttons to move left, right, jump, and hit the ball. The objective is to hit the ball onto the ground on the opponent's side of the net to score points.

### Features
#### Basic Features:
- Draw and control a Pikachu player that moves along the ground.
- Computer-controlled Pikachu opponent that moves automatically.
- The ball bounces off the boundaries, players, and the net.
- Player and ball interactions with the net are realistic—neither can pass through.
- Simple boundary and collision detection.
- Game controlled via physical buttons.

#### Advanced Features:
- Scoring system to track points.
- Ball follows a parabolic trajectory when bouncing.
- Pikachu can jump to hit the ball.
- Smash mechanic that increases ball speed upon hitting.

#### Additional Features:
- Quick ground-dive move for defensive play.
- Player can select different Pikachu skins in the starting menu.
- Game includes start, ready, win, and lose screens.
- Ability to restart the game using a button after the game ends.
- Loser Pikachu explodes upon game over.
- Screen shakes when Pikachu smashes the ball.
- Ball evolves after winning a match.

## Gameplay Instructions
1. **Start Screen**: Press the button to choose a Pikachu skin and begin the game.
2. **In-Game**: Use the buttons to move left, right, jump, and hit the ball.
3. **Game Over**: After a win or loss, the game displays the result and allows for a restart by pressing a button.

## File Structure
- **sources_1/**
  - `clk_divider.v` - Clock divider module.
  - `debounce.v` - Button debounce module to handle input noise.
  - `sram.v` - SRAM module for memory storage.
  - `vga_sync.v` - VGA synchronization module for display.
  - `lab10.v` - Top-level Verilog module connecting all components.
  - `main.v` - Game logic and control module.
- **mem_file/**
  - Contains all the `.mem` files used for loading images and sprites for the game, including backgrounds, player skins, ball sprites, etc.
  - Example files:
    - `background.mem`
    - `ball.mem`
    - `pikachu.mem`
    - `score.mem`
    - `win.mem`
    - `lose.mem`
- **DCL_FP_team_12_repo.pdf** - Project report document.

## Modules Description
### `sram.v`
This module handles the SRAM (Static Random-Access Memory) used to store and retrieve game graphics and other data.

### `vga_sync.v`
The VGA synchronization module generates the correct signals for the VGA display, ensuring that game graphics are displayed properly on the screen.

### `clk_divider.v`
The clock divider module is used to reduce the system clock frequency to a manageable rate for different game operations.

### `debounce.v`
The debounce module ensures that button inputs are properly handled, filtering out noise from mechanical button presses.

## Contributions
- **楊子賝**: 25% - Graphics rendering, interface switching, and integration.
- **曾煥宗**: 25% - Ball collision detection, boundary handling, AI for computer-controlled Pikachu.
- **邱振源**: 25% - Player movement, image drawing and processing.
- **陳燁**: 25% - Ball physics (parabolic motion, smashing mechanics).

## Lessons Learned
Early decisions on task distribution greatly improved efficiency, as repetitive tasks could be avoided. Regular integration of the work was also crucial to avoid compatibility issues. Establishing a consistent naming convention for variables early on saved us a lot of time during the integration phase.

We also realized the importance of understanding physics while working on game mechanics like parabolic ball motion and collision detection!

