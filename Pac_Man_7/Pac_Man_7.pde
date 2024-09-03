import processing.sound.*;
import vsync.*;
//first we import


///////////////// GLOBAL VARIABLES //////////////////////////

static char dirChar;    //the character for accessing directories (either / or \)
PFont emulogic;         //the in-game font
static Sound sound;     //configures sound globally
Game game = new Game(); //the game itself

//the following are merely for debugging purposes
static PApplet testApp;     //the papplet we use statically for debugging purposes ONLY
boolean testChange = false; //DEBUG: I'm just using this to see how likely it is for someone to press a key in the middle of a frame

ArrayList<Button> buttons = new ArrayList<Button>(); //an arraylist of all the buttons

static int scale = 2;

static int scroll = 0;

void setup() {
  size(448,580);        //set the size
  frameRate(60.606061); //set the framerate
  noSmooth();           //do NOT use gaussian blur or any other method to keep things smooth. I want all the pixels to match.
  
  dirChar = directoryCharacter(); //set the directory character
  
  testApp = this; //set the global test PApplet
  
  emulogic=createFont("assets"+dirChar+"emulogic.ttf",7.75); //load and
  textFont(emulogic);                                        //set the font
  
  sound = new Sound(this); //initialize the sound controller
  //sound.volume(0.4);       //configure the sound
  sound.volume(0.1);
  
  Artist.loadSprites(this); //load all sprites
  DeeJay.loadSounds(this);  //load all sounds
  
  game.restartGame();
  //Choreographer.initStartScreen(game); //load the game into the start screen
  
  loadButtons(game, buttons);
}

void draw() {
  testChange = false;
  background(0);
  scale(scale,scale);
  
  //here, we will respond to controls (when we want controls to be more consistent)
  
  //updates
  UpdateManager.updateGame(game);
  
  //drawing
  Artist.drawGame(this, game, buttons);
  
  //sound
  DeeJay.manageAmbience(game);
  
  //updating game modes
  boolean sounds = (game.screen == Screen.NORMAL); //TODO put this somewhere at the beginning so we don't have to calculate more than once
  game.updateTimerAndMode(this, sounds); //update all countdown timers and game modes
  
  //animation
  Artist.animate(game); //animate the game (don't worry, the animation function knows when to and when not to freeze the animations ;) )
  
  //if(game.maze.invincible) { text("invincible",width/2,20); }
  
  
  
  
  
  
  //if(game.screen == Screen.CUTSCENE_1 && !game.isPausedCompletely) {
  //  try { Actor pac = game.maze.get("Pac-Man"), blink = game.maze.get("Blinky"); println("Frame count: "+frameCount); println(pac.atom.copy().sub(blink.atom)); }
  //  catch(Exception ex) { println("Exception: I don't care"); }
  //}
  
  /*for(Actor ghost : game.maze) if(ghost instanceof Ghost) {
    float root = sqrt(ghost.atom.copy().sub(ghost.atomPrev).magSq());
    if(root != ghost.findSpeed() && ghost.cDir.equals(ghost.pDir)) {
      println(frameCount, ghost.name, root);
    }
  }*/
  
  //println(game.choreoTimer);
  
  //try { println(game.maze.get("Pac-Man").corners, sqrt(game.maze.get("Pac-Man").atom.copy().sub(game.maze.get("Pac-Man").atomPrev).magSq())); } catch(Exception ex) { }
  
  if(testChange) { println("Key press occurred during frame ("+frameRate+")"); }
}

void keyPressed() {
  testChange = true;
  switch(key) {
    ////PAUSE////
    case ' ': game.isPausedCompletely^=true; break; // space: pause/unpause
    
    ////CONTROLS////
    case 'w': case 'W': if(game.player1!=null) { game.player1.nDir.set( 0,-1); } break;
    case 'a': case 'A': if(game.player1!=null) { game.player1.nDir.set(-1, 0); } break;
    case 's': case 'S': if(game.player1!=null) { game.player1.nDir.set( 0, 1); } break;
    case 'd': case 'D': if(game.player1!=null) { game.player1.nDir.set( 1, 0); } break;
    
    case CODED: switch(keyCode) {
      case    UP: if(game.player2!=null) { game.player2.nDir.set( 0,-1); } break;
      case  LEFT: if(game.player2!=null) { game.player2.nDir.set(-1, 0); } break;
      case  DOWN: if(game.player2!=null) { game.player2.nDir.set( 0, 1); } break;
      case RIGHT: if(game.player2!=null) { game.player2.nDir.set( 1, 0); } break;
      
      ////INSERT COIN////
      case SHIFT: if(game.hCredits!=198) {
        switch(game.creditRate) { //switch the credit exchange rate
          case HALF: game.hCredits++;  break; //half: only add half a credit
          case  ONE: game.hCredits+=2; break; //one: add 2 halves
          case  TWO: game.hCredits+=4; break; //two: add 4 halves
          default: break;                     //free play: do nothing
        }
        if(game.hCredits>198) { game.hCredits=198; } //you can only have 98 credits
        if(game.creditRate!=CreditRate.FREE && (game.creditRate!=CreditRate.HALF || (game.hCredits&1)==0)) { //if we're not in free play, and the number of full credits has changed:
          DeeJay.credit.stop(); DeeJay.credit.play();                                                        //play the credit sound
        }
      } break;
    } break;
    
    ////START GAME////
    case ENTER: case RETURN: if(game.screen==Screen.CREDIT_SCREEN) { //if we press START (and are on the credit screen):
      game.startGame(this, 1);                                   //start the game, with 1 player
      if(game.creditRate!=CreditRate.FREE) { game.hCredits-=2; } //unless in free play mode, decrement the number of half credits by 2
    } break;
    case '2': if(game.screen==Screen.CREDIT_SCREEN && (game.hCredits>=4 || game.creditRate==CreditRate.FREE)) { //if we press START for 2 players (and are on the credit screen, and either have enough credits or are in free play):
      game.startGame(this, 2);                                   //start the game, with 2 players
      if(game.creditRate!=CreditRate.FREE) { game.hCredits-=4; } //unless in free play mode, decrement the number of half credits by 4
    } break;
    
    ////CHEATS////
    case '\\': game.maze.invincible^=true; break;
    case '\t': game.rackTest^=true; break;
    case '.':
      if(game.player1==null) { break; }
      if(game.maze.getItem(game.player1.tile) == Item.NONE) { game.maze.dotsLeft++; } //if there wasn't already an item here, increment dots left
      game.maze.setItem(game.player1.tile, Item.ENERGIZER);                           //set item to energizer pellet
    break;
    
    ////DEBUGS////
    case 'b': println(game.maze.get("Blinky")); break;
    case 'p': println(game.maze.get("Pinky")); break;
    case 'i': println(game.maze.get("Inky")); break;
    case 'c': println(game.maze.get("Clyde")); break;
  }
}

void mouseReleased() {
  if(mouseButton==LEFT && game.isPausedCompletely) {
    for(Button b : buttons) { //loop through all buttons
      if(b.hitbox(mouseX/scale, mouseY/scale)) {
        b.func.activate();
        break;
      }
    }
  }
}

void mouseWheel(MouseEvent event) {
  int amt = event.getCount(); //record how much the mousewheel has moved
  
  if(game.isPausedCompletely) {
    int scrollPrev = scroll;
    scroll = constrain(scroll+10*amt,0,220);
    
    float diff = scrollPrev-scroll;
    for(Button b : buttons) {
      b.y += diff;
    }
  }
}



/*
NOTES:

right, down, left, up. IN THAT ORDER


Things to do later:

Fully implement hard mode (correctly)
Correctly implement the lengths of all the pauses
Correctly implement which times the level does and doesn't get moduloed with 256
Make the ghost house gate disappear when the maze flashes. Also make the game over flash blue and white (during the demo screen)
Add the Disc class, so the DeeJay can use them :)
Make it so, after losing a life, Pinky and the other 2 ghosts alternate directions in the ghost house, instead of all going in unison
Make it so Pac-Man is in the correct animation frame during certain times, like when he hits a wall or when he finishes a level (also, figure out how that works)

Correctly implement pausing

Stop ghosts from halting if they can't move in a certain direction (I'm not sure if that happens anymore, though), fix the ghost house

Put the findspeed functions into the Choreographer class

make the artist.animation variable more formal, i.e. something you access indirectly

Make sure all actors get removed from the artist's hash table once deleted




BIGGEST THINGS TO DO: add the Disc class, add level 256 (correctly), add the buttons, add the high score

Biggest TODO, something that's extremely, extremely hard to do, and something I don't hate you for putting off: Perfect movement.
Okay? Because a lot of times, ghosts will move at 45 degree angles, or move less than theyr'e supposed to even though they're not turning corners.

Ideally, there should be some system for non-cornering actors. Namely, they start out with a certain amount of gas each frame. When you reach the middle of an intersection, you use the rest of your gas to continue moving in
whatever direction you ought to be moving in. If that direction happens to be RIGHT INTO A WALL, you stop, and throw out the extra gas.


BUGS:

sometimes, ghosts will move around the ghost house randomly like they got somewhere to be (doesn't seem to happen anymore, but I'll make 100% sure this ship is as tight as I thought)
sometimes, right after fright mode ends, the ghosts will try to move in a direction that they can't (specifically, through a passageway). I can't really blame them for this, but it DOES need to be fixed nonetheless.
ghosts in the ghost house look where they're about to go, not where they are going

when in PAC_DEATH_1 mode, ghosts can still turn from vulnerable to normal

When you start a game, then die, then start a second game, you're unable to touch ghosts until the next level (solved. cause: "dying" wasn't reset to null)

On only one occasion so far, I've tried starting the game while in demo mode, then having an exception thrown because it wasn't able to initialize the fruit for some reason

On a rare occasion, Pinky might switch behavior into BASE_EXIT_1 without immediately switching to BASE_EXIT_2. This isn't supposed to happen. This throws a NullPointerException because it causes Pinky to have a null target






game options:

normal/hard
lives (1,2,3,5;     4,infinity)
coinage (1 coin/credit, 2 coins/credit, 1 coin/2 credits, free play)
points for bonus life (10000, 15000, 20000, no bonus)
rack test
cabinet facing (upright/cocktail)
alternate ghost names (because it's hilarious!)

I also need to somehow figure out how to toggle service mode



invincible
which player?
sound











GAME CRASH: Pinky sometimes gets put in base_exit_1 mode, which they supposedly are supposed to skip. Neither Blinky nor Pinky have behavior programmed for that mode, and this causes a crash.

Pinky:
Position: <128.0, 116.0> (<16, 15>)
Velocities: <0, -1>, <0, -1>
Previous Position: <128.0, 115.5> (<16, 14>)
State: NORMAL, Class: Ghost, Modulos: 0.0, 0.0
cannot corner, didn't center
Brain = {Body: Pinky, Behavior: BASE_EXIT_1, Targetter: null}
java.lang.NullPointerException
  at Pac_Man_7$Brain.loadPathFinding(Pac_Man_7.java:1247)
  at Pac_Man_7$Brain.setNextDirection(Pac_Man_7.java:1250)
  at Pac_Man_7$Actor.setNextDirection(Pac_Man_7.java:412)
  at Pac_Man_7$Actor.progress1Frame(Pac_Man_7.java:476)
  at Pac_Man_7$Actor.update(Pac_Man_7.java:490)
  at Pac_Man_7$Ghost.update(Pac_Man_7.java:598)
  at Pac_Man_7$UpdateManager.updateMaze(Pac_Man_7.java:2948)
  at Pac_Man_7$UpdateManager.updateGame(Pac_Man_7.java:2929)
  at Pac_Man_7.draw(Pac_Man_7.java:78)
  at processing.core.PApplet.handleDraw(PApplet.java:2094)
  at processing.awt.PSurfaceAWT$9.callDraw(PSurfaceAWT.java:1386)
  at processing.core.PSurfaceNone$AnimationThread.run(PSurfaceNone.java:356)
NullPointerException


*/
