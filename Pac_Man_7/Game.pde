public static class Game { //holds everything about the current game
  
  /////////////////// ATTRIBUTES /////////////////////////////
  
  CyclicArray<Maze> mazes = new CyclicArray<Maze>(); //the mazes
  Iterator<Maze> mazeIter;                           //the maze iterator
  Maze maze;                                         //the current maze
  byte activePlayers = 0;                            //the number of active players
  
  Actor player1; //the Actor wasd is playing as
  Actor player2; //the Actor the arrows are playing as
  
  Actor dying = null; //the Actor who's currently dying (default to null)
  Pac   eater = null; //the Pac creature eating the dying actor
  
  boolean isPausedCompletely=false; //When true, the game is paused. Completely. We don't do anything, we just show the pause menu
  
  
  Screen screen = Screen.NORMAL; //the current game screen (defining where I am, what maze I'm on)
  Mode     mode =   Mode.NORMAL; //the current game mode (defining how the game acts)
  int timer=0;                   //how long left to be in the current game mode (if non-positive, it doesn't decrement)
  
  int choreoTimer=-1; //the time before the next event occurs (-1 means no events planned)
  int choreoStage=0;  //what stage of the choreography we're in
  
  Game_Values values = new Game_Values();
  
  CreditRate creditRate = CreditRate.ONE; //the coint-to-credit rate (either 2C1C, 1C1C, 1C2C, or free play)
  short hCredits = 0;                     //the number of half credits inserted (half, so we can keep track in 2C1C mode)
  
  int livesInitial = 5; //how many lives we get when we start a game
  
  int levelCache  = 0; //What level we say we're on (at the bottom of the screen)
  int score1Cache = 0; //What score we say player 1 has
  int score2Cache = 0; //What score we say player 2 has
  
  int scoreForOneUp=1000; //how many points before you get a 1-UP (divided by 10)
  
  Maze tempMaze = null; //When we start a cutscene, we need to store a copy of the maze we had before the cutscene. This is used to store the copy
  
  boolean rackTest = false; //whether or not the rack test cheat is turned on
  
  boolean altGhostNames = false; //if true, we use the alternate ghost names (yes, this was a real thing programmed into the game)
  
  boolean hard = false; //if true, we're in hard mode. if false, we're in normal mode
  
  int highScore = 0; //what high score we display at the top
  
  //methods
  
  Game() { } //default constructor
  
  void loadMazes(PApplet app, int players) { //loads all the mazes, given the number of players
    Maze[] mazeArray = new Maze[players]; //create array of mazes
    for(int n=0;n<players;n++) { //loop through them all
      mazeArray[n] = loadMaze(app).setGame(this);
    }
    
    mazes = new CyclicArray<Maze>(mazeArray); //set the maze list
    mazeIter = mazes.iterator();              //get the iterator to it
    maze = mazeIter.next();                   //get the current maze
    
    setPlayer(); //set the player
    
    Artist.twoUpClock = players==1 ? (byte)16 : (byte)0; //set the 2UP clock based on how many players there are
  }
  
  
  public static Maze loadMaze(final PApplet app) {
    //loading
    Maze maze = new Maze(-16,24,32,32,8,false);
    maze.loadMaze(app.createReader("assets"+dirChar+"maze file.txt"));
    
    //visuals
    maze.visual = app.loadImage("assets"+dirChar+"Background.png");
    maze.altVisual = app.loadImage("assets"+dirChar+"Flashing Background.png");
    maze.topLeft = new PVector(16,0);
    
    //boundaries
    maze.tunnel     = new Hitbox() { public boolean hitbox(IVector v) { return v.y==14 && (v.x<=6 || v.x>=25);           } };
    maze.ghostHouse = new Hitbox() { public boolean hitbox(IVector v) { return v.x>=13 && v.y>=13 && v.x<=18 && v.y<=15; } };
    
    //actors
    loadActors(maze);  //load all the actors
    resetActors(maze); //put them in their default locations and states
    
    return maze; //return result
  }
  
  public static void removeActors(final Maze maze) { //removes and destroys all current actors
    ArrayList<Actor> orphans = new ArrayList<Actor>(); //a list of all the actors the maze is about to disown
    for(Actor actor : maze) { orphans.add(actor); }    //add each child to the list
    for(Actor actor : orphans) { actor.destroy(); }    //destroy all references to the current actors
    //yes, the maze essentially just abandoned its children, then we destroyed the remaining orphans, leaving the grim reaper we call garbage collection to find them and destroy any remains of them
  }
  
  public static void loadActors(final Maze maze) { //adds in all the actors
    new Fruit("Fruit",maze,new PVector()); //load the fruit
    
    new Pac("Pac-Man",maze,new PVector()); //load Pac-Man
    
    new Ghost("Clyde",maze,new PVector()); //load Blinky,
    new Ghost("Inky",maze,new PVector()); //Pinky,
    new Ghost("Pinky",maze,new PVector()); //Inky,
    new Ghost("Blinky",maze,new PVector()); //and Clyde
  }
  
  public static void resetActors(final Maze maze) { //resets all the actors' positions and properties
    Actor fruit = maze.get("Fruit").setPos(16*8,17.5*8); //set properties of the fruit
    
    Actor   pac = maze.get("Pac-Man").setPos(16*8,23.5*8); pac.cDir=new IVector(-1,0); pac.corners=true; //set properties of Pac-Man
    
    Actor clyde = maze.get( "Clyde").setPos(18*8,14.5*8).setModX(0).setModY(0);  clyde.cDir.set(0,-1);  clyde.corners=false; clyde.tilePrev.set(18,14);
    Actor   ink = maze.get(  "Inky").setPos(14*8,14.5*8).setModX(0).setModY(0);    ink.cDir.set(0,-1);    ink.corners=false;   ink.tilePrev.set(14,14);
    Actor  pink = maze.get( "Pinky").setPos(16*8,14.5*8).setModX(0).setModY(0);   pink.cDir.set(0, 1);   pink.corners=false;  pink.tilePrev.set(16,14);
    Actor blink = maze.get("Blinky").setPos(16*8,11.5*8);                        blink.cDir.set(-1,0);  blink.corners=false; blink.tilePrev.set(16,11);
    
    for(Actor actor : maze) { //loop through all actors
      actor.nDir.set(actor.cDir);     //make both directions the same
      actor.setState(State.NORMAL);   //put every state in normal mode
      actor.didCenter = true;         //every actor has centered
      actor.unstop();                 //set every actor's stop timer to 0
      Artist.animation.put(actor, 0); //set animation frames for everyone
    }
    pink.nDir.neg(); //make Pinky want to go in the opposite direction
    if(maze.game!=null) {
      Artist.animation.put(fruit,maze.game.values.fruitIndex(maze.level)); //set the animation frame for the fruit, since each frame corresponds to a different fruit
    }
    fruit.setState(State.INVISIBLE); //make the fruit invisible
    
    new Brain(blink, Behavior.SCATTER); //give all the ghosts brains
    new Brain(pink, Behavior.BASE_EXIT_2);
    new Brain(ink, Behavior.BASE_PATROL);
    new Brain(clyde, Behavior.BASE_PATROL);
  }
  
  public static void resetMaze(final Maze maze, final boolean death) { //set up a maze into initial position (WITHOUT CHANGING DOTS) (death: true=Pac-Man died, false=new level)
    resetActors(maze);     //reset the actors
    //maze.game.setPlayer(); //set the player character(s?) (is removed because I'm pretty sure the player isn't ever wrongfully changed before a maze reset) TODO remove this line once you're sure it's safe
    
    maze.frightTimer=0;      //disable fright mode
    maze.globalDotCounter=0; //reset the global dot counter to 0
    maze.timeSinceLastDot=0; //reset the # of frames since the last dot was eaten
    maze.levelTimer = 0;     //reset the time in the level so far
    
    maze.game.dying = maze.game.eater = null; //set both of these Actors to null
    
    maze.doGlobalDotCounter = death; //enable/disable global dot counter depending on if Pac died or if it's a new level
    if(!death) { for(Actor ghost : maze) { if(ghost instanceof Ghost) { //loop through all ghosts
      ((Ghost)ghost).dotCounter = 0; //reset all their dot counters
    } } }
    if(death) { new Brain(maze.get("Pinky"),Behavior.BASE_PATROL); }
    
    Artist.energizerClock = 0; //reset the energizer clock cycle
  }
  
  public void updateTimerAndMode(PApplet app, boolean sound) { //updates timer, changes state if it reaches 0
    
    //first, update mode based on the credit number
    if((hCredits>1 || creditRate == CreditRate.FREE) && (screen == Screen.START_SCREEN || screen == Screen.DEMO)) { //if there are enough credits inserted (or we're on free play), and we're on the start screen or demo screen
      maze = new Maze(-16,25,32,32,8,app.createReader("assets"+dirChar+"empty maze file.txt")); //initialize a new empty maze and set that to the principal maze
      maze.game = this;                                                                         //make this that maze's principal game
      screen = Screen.CREDIT_SCREEN; mode = Mode.NORMAL; timer = choreoTimer = -1;              //swap to the credit screen (and go into normal mode, so we don't have any weird stuff going on) (and make the timers -1, same reason)
    }
    else if((hCredits<2 && creditRate != CreditRate.FREE) && screen == Screen.CREDIT_SCREEN) { //otherwise, if there aren't enough credits inserted (and we're NOT on free play), and we're on the credit screen
      Choreographer.initStartScreen(this); //go back to the start screen
    }
    
    //then, update the game-mode timer
    if(timer>0 && !isPausedCompletely) { //if positive (and not paused)
      --timer;       //decrement timer
      if(timer==0) { //if it just became 0:
        Choreographer.changeGameMode(this, app, sound); //update game mode
      }
      else if(screen == Screen.START_SCREEN) { //if we're on the start screen: we need to manage 2 events
        if     (timer==126) { maze.setItem(12,23,Item.ENERGIZER); maze.setItem(12,21,Item.PAC_DOT); } //at time 126, we place down an energizer and a pac-dot
        else if(timer== 64) { maze.setItem(6,17,Item.ENERGIZER);                                    } //at time 64, we place down an energizer in Pac-Man's path
      }
      //TODO seriously consider whether the above code block deserves to be here or if it should instead be with the time manager
    }
    
    //finally, update the game-screen timer, which is specific to choreographed events
    if(choreoTimer>0 && !isPausedCompletely) { //if positive (and not paused)
      --choreoTimer;       //decrement choreography timer
      if(choreoTimer==0) { //if it just became 0:
        Choreographer.changeScreen(this, app, sound); //update screen
      }
    }
  }
  
  public void setPlayer() {
    //this.player1 = this.player2 = maze.get("Pac-Man"); //set the player
    //this.player2 = maze.get("Blinky"); this.player2.brain = null; maze.invincible=true; //change the player 2 and delete their brain (also toggle invincibility)
    this.player1 = maze.get(maze.player1);
    this.player2 = maze.get(maze.player2);
  }
  
  void cycleMazes() {
    Maze mazeInit = maze; //record the initial maze
    do { maze = mazeIter.next(); } //repeatedly find the next maze in the cyclic list
    while(maze.lives == 0 && maze != mazeInit); //loop until we reach a maze with lives left, or until we've exhausted all the mazes
    
    levelCache = maze.level; //set the new value for the level cache
    
    setPlayer(); //set player again
  }
  
  
  
  
  public void startGame(PApplet app, int players) {
    loadMazes(app, players); //load all the mazes
    
    for(Maze m : mazes) { m.lives = livesInitial; } //set everybody's life count to the current default value
    maze.incrementLives();         //give the current maze an extra life so we can animate it turning into Pac-Man
    score1Cache = score2Cache = 0; //make both scores 0
    levelCache = 1;                //make the level 1
    
    activePlayers = (byte)players; //set the number of active players
    
    for(Actor actor : maze) { actor.setState(State.INVISIBLE); } //make all actors invisible
    
    DeeJay.intro.stop(); DeeJay.intro.play(); //play the jingle that plays at the start of the game
    
    mode = Mode.INTRO; //enter intro mode
    timer = 128;       //schedule a transition into ready mode in 128 frames
    
    Artist.energizerClock = 0; //make the energizers visible
    
    screen = Screen.NORMAL; //enter the NORMAL screen
    
    //maze.level=9; //TEMPORARY just so I can test out the third cutscene TODO remove this
  }
  
  
  
  public void setMaze(Maze m) { //sets the principal maze of the game
    if(maze!=null) { //if there's an existing maze:
      for(Actor actor : maze) { Artist.animation.remove(actor); } //remove each actor from the Artist's animation queue
      //TODO make it so we don't have to directly call upon the animation member of artist, which is supposed to be private in practice
    }
    
    maze = m; //set the maze
    for(Actor actor : maze) {        //loop through all actors
      Artist.animation.put(actor,0); //initialize each actor's animation cycle. The position can be changed, we just need it to be there
    }
  }
  //TODO actually use this, like you're supposed to
  
  
  
  
  
  
  public void updateScoreCache() { //updates the scores stored in cache
    if(mazes.length!=0 && maze == mazes.get(0))     { score1Cache = maze.score; } //if we're player 1, update the player 1 score
    else if(mazes.length>1 && maze == mazes.get(1)) { score2Cache = maze.score; } //if we're player 2, update the player 2 score
    
    if(maze.score > highScore && !maze.invincible) {
      updateHighScore(maze.score);
    }
  }
  
  void updateHighScore(int newScore) {
    highScore = newScore;
    
    String path = "data"+dirChar+"High Scores"+dirChar+(hard?"Hard":"Normal")+dirChar;
    if(scoreForOneUp==0) { path += "No Bonus"; }
    else                 { path += scoreForOneUp+"0 Bonus"; }
    path += ""+dirChar+livesInitial+".txt";
    PrintWriter writer = testApp.createWriter(path);
    writer.println(newScore);
    
    writer.flush(); writer.close();
  }
  
  void loadHighScore() {
    String path = "data"+dirChar+"High Scores"+dirChar+(hard?"Hard":"Normal")+dirChar;
    if(scoreForOneUp==0) { path += "No Bonus"; }
    else                 { path += scoreForOneUp+"0 Bonus"; }
    path += ""+dirChar+livesInitial+".txt";
    BufferedReader reader = testApp.createReader(path);
    
    String line;
    try {
      line = reader.readLine();
      highScore = int(line);
      reader.close();
    }
    catch(IOException ex) {
      throw new RuntimeException(ex.getMessage());
    }
  }
  
  
  public void restartGame() { //TODO finish this function
    hCredits = 0;                        //reset credit number
    Choreographer.initStartScreen(this); //initialize start screen
    
    loadHighScore();
  }
  
  public void   pause() { isPausedCompletely= true; }
  public void unpause() { isPausedCompletely=false; }
  
  
  /*Game setDifficulty(final boolean hrd) { //sets difficulty to normal (0) or hard (1)
    hard = hrd;                                                 //set difficulty
    maze.levelMap = Game_Values.levelMapping(maze.level, hard); //set the mapped level
    return this;                                                //return result
  }*/
}

//TODO organize the placement of each of the methods within the code
