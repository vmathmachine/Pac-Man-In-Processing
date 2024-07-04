public static class Artist { //responsible for loading and displaying the graphics & animations
  
  public static HashMap<String, HashMap<State, PImage[][]>> sprites = new HashMap<String, HashMap<State, PImage[][]>>();
  //contains all the sprites (PImage), ordered by name (String), state (State), direction (int), and position in the animation cycle (int)
  
  public static HashMap<Actor, Integer> animation = new HashMap<Actor, Integer>();
  //contains the times in the animation cycle (int), ordered by name (String)
  
  public static PImage lifeSprite; //the sprite used to display how many Pac-Mans we have left
  public static PImage infinitySprite; //the sprite used to identify that Pac-Man has infinity lives (NOT vanilla)
  public static PImage[] comboSprites; //the sprites used to display the scores when you eat a ghost
  public static PImage energizer;     //the sprite for displaying energizer pellets
  public static PImage pointsSprite1; //the sprite for displaying the "PTS" character (in white)
  public static PImage pointsSprite2; //the sprite for displaying the "PTS" character (in orange)
  
  public static PImage[] caughtClothes; //the sprites of Blinky when his rags get caught on a pole during one of the intermissions
  
  public static byte energizerClock =  0; //used for clocking the flashing energizer pellets
  public static byte oneUpClock     =  0; //used for clocking the flashing 1UP sign
  public static byte twoUpClock     =  0; //used for clocking the flashing 2UP sign
  
  ////////////////////////////////////// SPRITE LOADING ////////////////////////////////////////////////////
  
  public static void loadSprites(PApplet app) { //loads all the images
    final String[] direction = {"right","down","left","up"}; //all 4 directions, in the order they're stored in the game (used for grabbing files)
    final String folder = "assets"+dirChar+"Actors"+dirChar; //the location of the Actor sprites
    
    loadPacMan(app, direction, folder); //first Pac-Man
    loadGhosts(app, direction, folder); //then the Ghosts
    loadFruits(app, folder);            //finally, the fruits
    
    loadOther(app); //load the other, miscellaneous sprites
  }
  
  public static void loadPacMan(final PApplet app, final String[] direction, final String folder) {
    HashMap<State, PImage[][]> pacSprites = new HashMap<State, PImage[][]>(); //initialize the Pac-Man sprite map
    
    String folder2 = folder+"Pac"+dirChar+"Pac-Man"+dirChar; //grab the Pac-Man sprite folder
    for(State s : new State[] {State.NORMAL, State.BIG}) { //loop through both the normal and the big states
      
      PImage[][] sprites = new PImage[4][16]; //4 directions, 8 animation frames
      for(int n=0;n<4;n++) { //loop through all 4 directions
        if(sprites[0][0]!=null) { sprites[n][0] = sprites[0][0]; } //when his mouth is closed, he looks the same no matter which direction he looks
        else                    { sprites[n][0] = app.loadImage(folder2+s+" 0.png"); } //so, we can just use one image for all directions on that frame
        sprites[n][1] = sprites[n][8] = sprites[n][9] = sprites[n][0];
        
        sprites[n][2] = sprites[n][3] = sprites[n][10] = sprites[n][11] = app.loadImage(folder2+s+" 1 "+direction[n]+".png"); //mouth slightly open
        sprites[n][4] = sprites[n][5] = sprites[n][12] = sprites[n][13] = app.loadImage(folder2+s+" 2 "+direction[n]+".png"); //mouth all the way open
        sprites[n][6] = sprites[n][7] = sprites[n][14] = sprites[n][15] = sprites[n][2];                                      //mouth slightly open (again)
      }
      
      pacSprites.put(s, sprites); //put the sprites in the map
    }
    
    PImage[][] sprites2 = new PImage[4][88]; //4 directions, 11 animation frames lasting for 8 frames each (for dying animation)
    for(int n=0;n<11;n++) { //loop through all 11 actual frames
      PImage image = app.loadImage(folder2+"DYING "+n+".png"); //load each one
      for(int m=0;m<4;m++) for(int k=0;k<8;k++) { sprites2[m][8*n+k] = image; } //assign that to 8 frames for each of the 4 directions
    }
    pacSprites.put(State.DYING, sprites2); //put the sprites in the map
    
    sprites.put("Pac-Man", pacSprites); //put Pac-Man's sprites in the pile
  }
  
  public static void loadGhosts(final PApplet app, final String[] direction, final String folder) {
    String names[] = {"Blinky", "Pinky", "Inky", "Clyde"};
    String ghostFolder = folder+"Ghost"+dirChar; //grab the ghost folder
    
    //first, load all the vulnerable sprites
    PImage[] vulnerable = new PImage[32]; //load all the blue ghost sprites
    for(int n=0;n<4;n++) {
      PImage image = app.loadImage(ghostFolder+"VULNERABLE "+n+".png");
      for(int m=0;m<8;m++) { vulnerable[8*n+m] = image; }
    }
    
    //then all the floating-eyes sprites
    PImage[][] eaten = new PImage[4][1];
    for(int n=0;n<4;n++) { eaten[n][0] = app.loadImage(ghostFolder+"EATEN 0 "+direction[n]+".png"); }
    
    //then, load all the normal sprites
    for(String name : names) { //loop through all 4 ghosts
      String folder2 = folder+"Ghost"+dirChar+name+dirChar; //grab the sprite folder
      HashMap<State, PImage[][]> ghostSprites = new HashMap<State, PImage[][]>(); //initialize the ghost sprite map
      
      //these are the normal sprites
      PImage normSprites[][] = new PImage[4][16]; //4 directions, 2 animation frames, last for 8 frames each
      for(int n=0;n<4;n++) for(int m=0;m<2;m++) { //loop through all 4 directions & all 2 animation sprites
        PImage image = app.loadImage(folder2+"NORMAL "+m+" "+direction[n]+".png"); //load each image
        for(int k=0;k<8;k++) { normSprites[n][8*m+k] = image; }                    //octuple each image (since they each last for 8 frames)
      }
      
      ghostSprites.put(State.NORMAL, normSprites); //put the normal sprites in the map
      
      ghostSprites.put(State.VULNERABLE, new PImage[][] {vulnerable, vulnerable, vulnerable, vulnerable}); //put all the vulnerable sprites in the map
      
      ghostSprites.put(State.EATEN, eaten); //put all the eaten sprites in the map
      
      sprites.put(name, ghostSprites); //put this Ghost's sprites in the pile
    }
    
    sprites.get("Blinky").put(State.RIPPED, new PImage[][] {{app.loadImage(ghostFolder+"Blinky"+dirChar+"RIPPED 0.png"), app.loadImage(ghostFolder+"Blinky"+dirChar+"RIPPED 1.png")}});
    
    PImage patched0 = app.loadImage(ghostFolder+"Blinky"+dirChar+"PATCHED 0.png"), patched1 = app.loadImage(ghostFolder+"Blinky"+dirChar+"PATCHED 1.png");
    PImage[] patchedSprites = new PImage[16]; for(int k=0;k<8;k++) { patchedSprites[k]=patched0; patchedSprites[k+8]=patched1; }
    sprites.get("Blinky").put(State.PATCHED, new PImage[][] {null, null, patchedSprites, null});
    
    PImage exposed0 = app.loadImage(ghostFolder+"Blinky"+dirChar+"EXPOSED 0.png"), exposed1 = app.loadImage(ghostFolder+"Blinky"+dirChar+"EXPOSED 1.png");
    PImage[] exposedSprites = new PImage[12]; for(int k=0;k<6;k++) { exposedSprites[k]=exposed0; exposedSprites[k+6]=exposed1; }
    sprites.get("Blinky").put(State.EXPOSED, new PImage[][] {exposedSprites});
  }
  
  public static void loadFruits(PApplet app, final String folder) {
    //first, we load the actual sprites
    String[] names = {"Cherry", "Strawberry", "Orange", "Apple", "Melon", "Flagship", "Bell", "Key"}; //make array of all the fruits you can collect
    HashMap<State, PImage[][]> sprite2 = new HashMap<State, PImage[][]>(); //create map to store all the fruit sprites
    PImage[] sprite3 = new PImage[names.length];                           //create array to store all the fruits sprites
    for(int n=0;n<names.length;n++) { sprite3[n] = app.loadImage(folder+"Fruit"+dirChar+names[n]+".png"); } //grab all the fruit sprites
    sprite2.put(State.NORMAL, new PImage[][] {sprite3, sprite3, sprite3, sprite3}); //put the array in the map
    
    //next, we load the score display sprites
    names = new String[] {"100", "300", "500", "700", "1000", "2000", "3000", "5000"}; //reload the names array
    sprite3 = new PImage[names.length];         //create array to store all the fruit score sprites
    for(int n=0;n<names.length;n++) { sprite3[n] = app.loadImage("assets"+dirChar+"Points"+dirChar+names[n]+".png"); } //grab all the fruit sprites
    sprite2.put(State.EATEN, new PImage[][] {sprite3, sprite3, sprite3, sprite3});  //put the array in the map
    
    sprites.put("Fruit", sprite2);                                                  //put the map in the other map
  }
  
  public static void loadOther(PApplet app) {
    lifeSprite = app.loadImage("assets"+dirChar+"Pac-Man Life Sprite.png"); //load the life sprite icon
    infinitySprite = app.loadImage("assets"+dirChar+"Pac-Man infinite lives icon.png"); //load the infinite lives sprite icon
    
    comboSprites = new PImage[4]; //initialize the combo sprites
    for(int n=0;n<4;n++) { comboSprites[n] = app.loadImage("assets"+dirChar+"Points"+dirChar+(200<<n)+".png"); } //load each combo sprite
    
    energizer = app.loadImage("assets"+dirChar+"Energizer Dot.png");
    pointsSprite1 = app.loadImage("assets"+dirChar+"PTS sprite.png");
    pointsSprite2 = app.loadImage("assets"+dirChar+"PTS sprite 2.png");
    
    caughtClothes = new PImage[6];
    for(int n=0;n<5;n++) { caughtClothes[n] = app.loadImage("assets"+dirChar+"Actors"+dirChar+"Ghost"+dirChar+"Blinky"+dirChar+"CAUGHT "+n+".png"); }
    caughtClothes[5]=caughtClothes[4];
  }
  
  
  ///////////////////////////////////// DRAWING //////////////////////////////////////////////
  
  //first, we make wrapper methods for drawing entire things
  
  public static void drawGame(PApplet app, Game game, ArrayList<Button> buttons) { //draws the whole game
    
    //first, draw the maze, as well as the stuff on the edge of the screen
    
    if(game.mode!=Mode.MAZE_FINISHED_2 || game.timer>30) { //except between levels,
      drawMaze(app, game.maze); //draw the maze
      
      if(!game.screen.isCutscene()) { //the score and life counter is not shown during cutscenes
        drawScores(app, game);           //draw the scores at the top
        drawLifeCounter(app, game.maze); //draw the number of lives at the bottom
      }
    }
    drawLevelFruit(app, game.values, game.levelCache); //draw the fruits at the bottom to show what level we're on
    
    if(game.screen==Screen.START_SCREEN || game.screen==Screen.CREDIT_SCREEN || game.screen==Screen.DEMO || game.mode==Mode.GAME_OVER) { //on start screens, show the number of credits
      drawCredits(app, game.hCredits, game.creditRate == CreditRate.FREE);                                                               //this is done in a built-in function
    }
    
    
    
    //then, draw some stuff that gets drawn over the maze but behind the actors
    if(game.screen==Screen.DEMO) { app.fill(#FF0000); app.textAlign(LEFT); app.text("Game  Over",72,167); } //on the demo screen, show the GAME OVER text to show us that no one's playing.
    
    if(game.screen == Screen.CUTSCENE_2) { //during the second cutscene:
      app.image(Artist.caughtClothes[game.choreoStage],115,158); //display the image of Blinky's clothes getting caught on a pole
    }
    
    //then, draw the actors
    if(game.mode!=Mode.MAZE_FINISHED_2 || game.timer>30) { //except between levels,
      drawActors(app, game.maze);                          //draw the maze's actors
    }
    
    
    //the following are extra things that only show during certain game animations
    
    switch(game.screen) {
      case START_SCREEN : drawCharacterRoster(app, game.timer,game.altGhostNames); break; //on the start screen, display the roster of all the ghosts
      case CREDIT_SCREEN: drawCreditScreen(app, game);                             break; //on the credit screen, show some important pre-game info
      default: //we don't do anything special for other screens
    }
    
    switch(game.mode) { //switch the game mode
      case INTRO: if(game.screen==Screen.NORMAL) { app.fill(#00FFFF); app.textAlign(LEFT); app.text("Player One",72,120); }        //during the intro, say "Player one ready!"
      case READY: if(game.screen==Screen.NORMAL) { app.fill(#FFFF00); app.textAlign(LEFT); app.text("Ready!",88,168);     } break; //during ready mode, just say "ready!"
      
      case TEMP_GAME_OVER: //during the temporary game over (where only one player game overed):
        int ind = 0; for(Maze m : game.mazes) { if(game.maze==m) { break; } ++ind; } //find player index
        String ident = (ind==0 ? "One" : ind==1 ? "Two" : ind+1+"");                 //find an appropriate identifier
        app.fill(#00FFFF); app.textAlign(LEFT);                                      //set drawing parameters
        app.text("Player "+ident,72,120);                                            //tell us which player game overed, then say "game over" (notice a lack of break statement)
      case GAME_OVER: app.fill(#FF0000); app.textAlign(LEFT); app.text("Game  Over",72,167); break; //during a game over: just say "game over"
      
      case EAT_GHOST: //when a ghost was just eaten:
        app.image(comboSprites[game.maze.comboCount-1],(int)(game.dying.atom.x-8)+game.maze.cx,(int)(game.dying.atom.y-3.5)+game.maze.cy); //display the score gained right where the ghost used to be
      break;
      
      default: //we don't do anything special for other game modes
    }
    
    //if(game.mode==Mode.READY) { println(game.choreoTimer); }
    
    //finally, just draw the pause screen (if applicable)
    if(game.isPausedCompletely) {    //if the game is paused completely:
      drawPauseScreen(app, buttons); //draw the pause screen
    }
  }
  
  public static void drawMaze(PApplet app, Maze maze) { //draws the maze
    
    if(maze.visual!=null) { //if the maze has a dedicated picture:
      if(maze.game.mode == Mode.MAZE_FINISHED_2 && maze.game.timer%24<12) { app.image(maze.altVisual, maze.cx+maze.topLeft.x,maze.cy+maze.topLeft.y); } //draw the picture
      else { app.image(maze.visual,maze.cx+maze.topLeft.x,maze.cy+maze.topLeft.y); }
    }
    else { maze.makeMazePicture(app.g); } //no dedicated picture: generate the picture manually
      
    //now we have to draw all the items on screen
    for(int x=0;x<maze.w;x++) for(int y=0;y<maze.h;y++) { //loop through all grid squares
      switch(maze.maze[x][y].getItem()) { //switch the item
        case PAC_DOT: app.fill(255,183,174); app.noStroke(); //Pac dot: set drawing parameters
                      app.square(maze.cell*(x+0.5)+maze.cx-1, maze.cell*(y+0.5)+maze.cy-1, 2); //draw 2x2 square in the middle of the tile
                      break;
        case ENERGIZER: if(energizerClock%20 < 10) { //Energizer: draw the energizer pellet
          app.image(energizer, maze.cell*x+maze.cx, maze.cell*y+maze.cy); //but make it blink every 10 frames
        } break;
      }
    }
    
    
  }
  
  public static void drawActors(PApplet app, Maze maze) { //draws the maze's actors
    for(Actor act : maze) { //loop through all actors
      drawActor(app, maze, act); //draw all actors
    }
  }
  
  public static void drawActor(PApplet app, Maze maze, Actor act) {
    if(act.state == State.INVISIBLE) { return; } //don't draw invisible entities
    
    int dir = act.cDir.x==0 ? (act.cDir.y<0 ? 3 : 1) : (act.cDir.x<0 ? 2 : 0); //find the direction, then find the index that corresponds to it (right, down, left, up)
    int frame = animation.get(act);                                            //find the frame in animation
    PImage sprite = sprites.get(act.name).get(act.state)[dir][frame];          //find the image
    //if(act.cDir.equals(-act.pDir.x,-act.pDir.y)) { dir^=2; }                   //if pDir and cDir point in opposite directions, look the other way
    
    if(sprite!=null) {
      IVector pixel = new IVector(act.atom.copy().sub(0.5*sprite.width,0.5*sprite.height)); //find the location of the top left corner
      app.image(sprite, pixel.x+maze.cx, pixel.y+maze.cy); //draw the sprite
    }
    else { //if no sprite:
      act.basicDisplay(app.g); //perform an emergency draw function so we can still see it
    }
  }
  
  public static void drawScores(PApplet app, Game game) { //draws the scores at the top
    app.fill(222); app.textAlign(LEFT); app.text("High Score",72,7);
    if((oneUpClock&16) == 0) { app.text("1UP", 24,7); } //if on the lower half of the clock, display 1UP
    if((twoUpClock&16) == 0) { app.text("2UP",176,7); } //if on the lower half of the clock, display 2UP
    
    
    /*if(game.mazes.length>0) { app.textAlign(RIGHT); app.text(game.mazes.get(0).score,48,16); app.text("0",56,16);
    if(game.mazes.length>1 && game.mazes.get(1).score!=0) { app.text(game.mazes.get(1).score,200,16); app.text("0",208,16); } }*/
    app.textAlign(RIGHT); app.text(game.score1Cache+"0",56,16); //draw the player 1 score
    if(game.mazes.length>1 || game.score2Cache!=0) { app.text(game.score2Cache+"0",208,16); } //draw the player 2 score (ignore if it's 0, unless we're in a 2 player game)
    if(game.mode.isPlaying()||game.highScore!=0) { app.text(game.highScore,128,16); app.text("0",136,16); } //only display the high score if we're playing or if it's non-zero
  }
  
  public static void drawLifeCounter(PApplet app, Maze maze) { //draws the lives counter at the bottom
    if(maze.lives == Integer.MIN_VALUE) { //minimum value is used to identify infinite lives
      app.image(infinitySprite,17,274); return; //display the infinity sprite & quit the function
    }
    
    for(int n=0;n<min(5,maze.lives-1);n++) { //loop through all the lives (max out at 8, exclude the one that's currently in the maze)
      app.image(lifeSprite,17+16*n,274);
    }
    
    /*if(maze.lives==0) {
      drawCredits(app, maze.game.hCredits, maze.game.creditRate == CreditRate.FREE);
    }*/
  }
  
  public static void drawLevelFruit(PApplet app, Game_Values values, int level) { //draw the fruit at the bottom corresponding to the level
    int min = max(1,level-6); //the first index we check
    for(int n=min;n<=level;n++) {            //display the fruits at the bottom corresponding to the level number
      int fruitIndex = values.fruitIndex(n); //find the index of the corresponding fruit
      PImage fruit = sprites.get("Fruit").get(State.NORMAL)[0][fruitIndex]; //load the fruit
      app.image(fruit, 194-15*(n-min), 274);                                //draw each fruit
    }
  }
  
  public static void drawCharacterRoster(PApplet app, int time, boolean altGhostNames) { //draw the character roster at the beginning of the game
    app.textAlign(LEFT);
    
    if(time<=698) { app.fill(222); app.text("Character / nickname",56,47); }
    
    color[] ghostColor={#FF0000, #FFB7FF, #00FFFF, #FFB751}; //colors of each ghost
    
    String[] ghostNames={"Blinky", "Pinky",   "Inky","Clyde"}; //used names of each ghost
    String[] fullNames ={"Shadow","Speedy","Bashful","Pokey"}; //full names of each ghost
    
    String[] realGhostNames = ghostNames;
    
    if(altGhostNames) {
      fullNames  = new String[] {"AAAAAAAA-","CCCCCCCC-","EEEEEEEE-","GGGGGGGG-"};
      ghostNames = new String[] {  "BBBBBBB",  "DDDDDDD",  "FFFFFFF",  "HHHHHHH"};
    }
  
    for(int n=0;n<4;n++) { //loop through all 4 ghosts.  Each ghost's info will display 120 frames apart from each other
      if(time<=642-120*n) { app.image(sprites.get(realGhostNames[n]).get(State.NORMAL)[0][0], 32,51+24*n); } //first, draw the sprite
      if(time<=582-120*n) {                                                                                 //60 frames later:
        app.fill(ghostColor[n]); app.text(fullNames[n],64,63+24*n);                                        //draw their name
        app.stroke(ghostColor[n]); app.strokeWeight(1); app.line(59,59+24*n,62,59+24*n); app.noStroke();  //put a dash before it
      }
      if(time<=1146-120*n-596) { app.text("\""+ghostNames[n]+"\"",144,63+24*n); }    //30 frames later: draw their "nickname"
      else { break; }                                                            //shortcut: if this character's info isn't fully loaded, don't bother trying to draw the next character
    }
    
    if(time<=126) { app.fill(222); app.text("10",96,199); app.text("50",96,215); app.image(pointsSprite1,120,194); app.image(pointsSprite1,120,210); } //displays how much each item is worth
    if(time<=64) { app.fill(255,183,255); app.text("©",32,256); app.text("  1980 midway mfg co",32,255); app.square(169,253,2); app.square(193,253,2); } //shows copyright disclaimer (hehehe)
  }
  
  public static void drawCreditScreen(PApplet app, Game game) { //draws the screen that says how many credits you have and that you can start at any time
    app.textAlign(LEFT);
    
    app.fill(255,183,82); app.text("push start button",48,130); //tells us how to start
    if(game.scoreForOneUp>0) { //if it's possible to get a 1UP:
      app.fill(255,183,173); app.text("Bonus Pac-Man for "+game.scoreForOneUp+"0 ",8,196); app.image(pointsSprite2,198,191); //tells us how to get a 1-UP
    }
    
    app.fill(0); app.square(193,230,4);
    app.fill(255,183,255); app.text("©",32,224); app.text("  1980 midway mfg co",32,223); app.square(169,221,3); app.square(193,221,3); //show copyright disclaimer (hehehe)
    
    app.fill(0,255,255);
    if(game.hCredits==2) { app.text("1 player only",65,160);  } //show how many players can play
    else                 { app.text("1 or 2 players",65,160); }
  }
  
  public static void drawCredits(PApplet app, int hCredits, boolean free) { //displays how many credits are inserted right at the bottom
    app.fill(222);                                      //set fill
    if(free) { app.textAlign(LEFT); app.text("free play",16,287); } //free play: just say free play
    else {                                                          //otherwise:
      app.textAlign(RIGHT); app.text(hCredits>>1,88,287); //say how many credits
      app.textAlign(LEFT); app.text("credit",16,287);     //say credit
    }
  }
  
  public static void drawPauseScreen(final PApplet app, ArrayList<Button> buttons) { //draws the pause screen
    app.fill(0xC0000000); app.rect(0,0,224,580); //draw a black tint over everything
    
    for(Button b : buttons) { b.display(app); } //display each button
    
    app.scale(2); app.fill(#FF0000); app.text("Paused",56,50-(scroll>>1)); app.scale(0.5); //draw the PAUSED indicator in twice the font size
    
    app.fill(#FFFF00); //draw a bunch of text in yellow
    app.text("Rack Test",178,190-scroll); app.text("Invincible",176,230-scroll); app.text("Lives",112,280-scroll); app.text("Points for 1-UP",112,320-scroll); //just text to tell us what each button does
    app.text("Credit Rate",112,360-scroll); app.text("Difficulty",65,400-scroll); app.text("Alt Names",178,400-scroll);
    app.text("Switch Player",112,450-scroll);
  }
  
  ////////////////////////////////////////////////////// ANIMATION ////////////////////////////////////////////
  
  public static void animate(Game game) { //animates a game
    if(!game.isPausedCompletely) { //make sure the game ISN'T paused
      //first, we animate the actors
      
      switch(game.mode) { //switch the game mode
        case NORMAL: case PAC_DEATH_1: //normal playing mode (as well as first stage of Pac-Man's death)
          Artist.animateActors(game.maze); //animate the actors in the maze
        break;
        
        case PAC_DEATH_2:             //second stage
          Artist.animate(game.dying); //only animate the character who's currently dying
        break;
        
        default: //we don't animate the actors in any other mode
      }
      
      //next, we animate the blinking objects
      if(game.mode != Mode.INTRO && game.mode != Mode.READY && game.mode != Mode.GAME_OVER) { Artist.energizerClock = (byte)((Artist.energizerClock+1)%20); }
      if     (game.mazes.length>0) { if(game.maze == game.mazes.get(0)) { ++Artist.oneUpClock; }
      else if(game.mazes.length>1 &&    game.maze == game.mazes.get(1)) { ++Artist.twoUpClock; } }
    }
  }
  
  public static void setAnimation(Maze maze) { //TODO what the heck is this function even for?
    animation.put(maze.get("Pac-Man"),0); //reset Pac-Man's animation
    animation.put(maze.get("Blinky"),0); animation.put(maze.get("Pinky"),0); animation.put(maze.get("Inky"),0); animation.put(maze.get("Clyde"),0); //reset the Ghosts' animation
    animation.put(maze.get("Fruit"),maze.game.values.fruitIndex(maze.level));
  }
  
  public static void animateActors(Maze maze) {
    for(Actor actor : maze) { //loop through all the actors in the maze
      animate(actor);         //animate the actor
    }
  }
  
  public static void animate(Actor actor) {
    if(actor instanceof Fruit) { return; } //fruits don't animate
    
    int frame = animation.get(actor); //find the current frame of animation for this actor
    
    if(actor.caught && (actor.game.choreoTimer&3)!=3) { return; } //special case: when an actor is caught, they animate at 1/4 speed
    
    switch(actor.state) {
      case EATEN: case INVISIBLE: return; //don't animate eaten ghosts or removed entities
      case VULNERABLE: //vulnerable:
        if(actor.maze.frightTimer<=160 && (actor.maze.frightTimer&15)==0) { frame ^= 16; } //if blinking, add/subtract 16 every 16 frames
      case NORMAL: case BIG: case PATCHED:                                 //normal, big, and patched (and vulnerable, notice no break statements)
        if(actor instanceof Ghost || !actor.atomPrev.equals(actor.atom)) { //if it's a ghost OR the position has changed:
          frame = frame&16 | (frame+1)&15;                                 //increment the last 4 bits (wrap around)
        }
      break;
      case EXPOSED: frame = (frame+1)%12; break; //when exposed, the animation plays for 12 frames
      case DYING: ++frame; break; //when dying, just play out the animation as is
    }
    animation.put(actor, frame); //replace the old frame count with the new frame count
  }
}
